// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;

import "../std/ERC20.sol";

import "../ProofVerifierInterface.sol";


/* Logic flows:

Involes two parties, initiator and counterparty.

Either side deposits their coin in the swap contract on either chain,
then they withdraw the other parties coins on the other chain.

Once the counterparty accepts the exchange, by depositing the coins,
the exchange is finalised and cannot be refunded.

Either the initiator or counterparty can cancel or reject the exchange
on the counterparty chain. Because the operation is serialized only
one action can happen, e.g. if Counterparty accepts, but Initiator cancel
gets processed first, the counterparty deposit will be rejected.

Aside from the first step, each further step must provide proof of the
preceeding state on the other chain.

To make life easier, Alice is always the initiator and Bob is always the
counterparty, the names Alice, Bob and Initiator, Counterparty can be
exchanged and mixed freely.

-------------------------

Straightforward exchange

The ideal path, steps 3 and 4 can occur in any order.

Step 4 doesn't require a state proof, as the withdraw/receiver address
can be verified by `msg.sender`

        On Chain A               On Chain B

    1. InitiatorPropose (with deposit)

    2.                        CounterpartyAccept (with deposit)

    3. CounterpartyWithdraw (recieves deposit)

    4.                        InitiatorWithdraw (recieves deposit)

-------------------------

Initiator Cancel

Initiator can pre-emptively cancel the swap on the other chain,
this blocks the counterparty from accepting and allows a withdraw
on the initiators chain.

        On Chain A               On Chain B

    1. InitiatorPropose (with deposit)

    2.                         InitiatorCancel (blocks counterparty action)

    3. InitiatorRefund

-------------------------

Counterparty Reject

        On Chain A               On Chain B

    1. InitiatorPropose (with deposit)

    2.                         CounterpartyReject (cancels)

    3. InitiatorRefund (recieves deposit)

*/
contract ExampleSwap
{
    ProofVerifierInterface internal m_verifier;

    mapping(uint256 => Swap) internal m_swaps;

    enum State
    {
        Invalid,
        AlicePropose,
        AliceCancel,
        AliceWithdraw,
        AliceRefund,
        BobAccept,
        BobReject,
        BobWithdraw
    }

    struct Swap
    {
        State state;

        ERC20 alice_token;
        address alice_addr;
        uint256 alice_amount;

        ERC20 bob_token;
        address bob_addr;
        uint256 bob_amount;
    }


    // Events emitted after state transitions
    event OnAlicePropose( uint256 guid );
    event OnAliceWithdraw( uint256 guid );
    event OnAliceRefund( uint256 guid );
    event OnAliceCancel( uint256 guid );
    event OnBobAccept( uint256 guid );
    event OnBobReject( uint256 guid );
    event OnBobWithdraw( uint256 guid );


    constructor( ProofVerifierInterface verifier )
        public
    {
        m_verifier = verifier;
    }


    function TransitionAlicePropose ( uint256 in_guid, ERC20 alice_token, address alice_addr, uint256 alice_amount, ERC20 bob_token, address bob_addr, uint256 bob_amount )
        public returns (bool)
    {
        Swap storage swap = m_swaps[in_guid];

        require( swap.state == State.Invalid );

        SafeTransfer( alice_token, alice_addr, address(this), alice_amount );

        swap.state = State.AlicePropose;

        swap.alice_token = alice_token;
        swap.alice_addr = alice_addr;
        swap.alice_amount = alice_amount;

        swap.bob_token = bob_token;
        swap.bob_addr = bob_addr;
        swap.bob_amount = bob_amount;

        emit OnAlicePropose( in_guid );

        return true;
    }


    function TransitionAliceCancel ( uint256 in_guid, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.Invalid );

        // Must provide proof of OnAlicePropose
        require( m_verifier.Verify( 0x0, proof ) );

        swap.state = State.AliceCancel;

        emit OnAliceCancel( in_guid );
    }


    function TransitionAliceRefund ( uint256 in_guid, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.AlicePropose );

        // Must provide proof of OnAliceCancel or OnBobReject
        require( m_verifier.Verify( 0x0, proof ) );

        swap.state = State.AliceRefund;

        emit OnAliceRefund( in_guid );
    }


    function TransitionAliceWithdraw ( uint256 in_guid )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.BobAccept );

        // No proof needed, as soon as Bob accepts (and provides proof)

        swap.state = State.AliceWithdraw;

        SafeTransfer( swap.bob_token, address(this), swap.bob_addr, swap.bob_amount );

        emit OnAliceWithdraw( in_guid );
    }


    function TransitionBobAccept ( uint256 in_guid, ERC20 alice_token, address alice_addr, uint256 alice_amount, ERC20 bob_token, address bob_addr, uint256 bob_amount, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.Invalid );

        // Must provide proof of OnAlicePropose
        require( m_verifier.Verify( 0x0, proof ) );

        swap.state = State.BobAccept;

        swap.alice_token = alice_token;
        swap.alice_addr = alice_addr;       // XXX: superfluous
        swap.alice_amount = alice_amount;   // XXX: superfluous

        swap.bob_token = bob_token;
        swap.bob_addr = bob_addr;
        swap.bob_amount = bob_amount;

        SafeTransfer( bob_token, bob_addr, address(this), bob_amount );

        emit OnBobAccept( in_guid );
    }


    function TransitionBobReject ( uint256 in_guid, ERC20 alice_token, address alice_addr, uint256 alice_amount, ERC20 bob_token, address bob_addr, uint256 bob_amount, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.Invalid );

        // Must provide proof of OnAlicePropose
        require( m_verifier.Verify( 0x0, proof ) );

        swap.state = State.BobReject;

        swap.alice_token = alice_token;
        swap.alice_addr = alice_addr;
        swap.alice_amount = alice_amount;

        swap.bob_token = bob_token;
        swap.bob_addr = bob_addr;
        swap.bob_amount = bob_amount;

        emit OnBobReject( in_guid );
    }


    function TransitionBobWithdraw ( uint256 in_guid, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.AlicePropose );

        // Must provide proof of BobAccept
        require( m_verifier.Verify( 0x0, proof ) );

        swap.state = State.BobWithdraw;

        // Transfer the funds Alice deposited to Bob
        SafeTransfer( swap.alice_token, address(this), swap.bob_addr, swap.alice_amount );

        emit OnBobWithdraw( in_guid );
    }


    function GetSwap( uint256 in_swapid )
        internal view returns (Swap storage out_swap)
    {
        out_swap = m_swaps[in_swapid];
        require( out_swap.state != State.Invalid );
    }

    /**
    * Performs a 'safer' ERC20 transferFrom call
    * Verifies the balance has been incremented correctly after the transfer
    * Some broken tokens don't return 'true', this works around it.
    */
    function SafeTransfer (ERC20 in_currency, address in_from, address in_to, uint256 in_value )
        internal
    {
        uint256 balance_before = in_currency.balanceOf(in_to);

        require( in_currency.transferFrom(in_from, in_to, in_value) );

        uint256 balance_after = in_currency.balanceOf(in_to);

        require( (balance_after - balance_before) == in_value );
    }
}
