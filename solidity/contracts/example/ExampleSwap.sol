// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

import "../std/ERC20.sol";

import "../Panautoma.sol";

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
    using RemoteContractLib for Panautoma.RemoteContract;

    mapping(uint256 => Swap) internal swaps;


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


    struct SwapSide {
        Panautoma.RemoteContract remote;
        ERC20 token;
        address addr;
        uint256 amount;
    }


    struct Swap
    {
        State state;
        SwapSide alice;
        SwapSide bob;
    }


    // Events emitted after state transitions
    event OnAlicePropose( uint256 guid );
    event OnAliceWithdraw( uint256 guid );
    event OnAliceRefund( uint256 guid );
    event OnAliceCancel( uint256 guid );
    event OnBobAccept( uint256 guid );
    event OnBobReject( uint256 guid );
    event OnBobWithdraw( uint256 guid );


    constructor( )
        public
    {
        // TODO: put fancy stuff here
    }

  
    function TransitionAlicePropose ( uint256 in_guid, Swap in_swap )
        public returns (bool)
    {
        require( SwapDoesNotExist(in_guid) );

        SafeTransfer( in_swap.alice.token, in_swap.alice.addr, address(this), in_swap.alice.amount );

        swaps[in_guid] = in_swap;

        // TODO: add more fields to OnAlicePropose event
        // the event must have sufficient information to be provable on other chain
        emit OnAlicePropose( in_guid );

        return true;
    }


    /**
    * On Bobs chain, Alice pre-emptively cancels the swap
    */
    function TransitionAliceCancel ( uint256 in_guid, Swap in_swap, bytes in_proof )
        public
    {
        // Swap must not exist on Bobs chain
        require( SwapDoesNotExist(in_guid) );

        swaps[in_guid] = in_swap;

        // Must provide proof of OnAlicePropose
        require( in_swap.alice.remote.Verify(0x0, in_proof) );

        emit OnAliceCancel( in_guid );
    }


    function TransitionAliceRefund ( uint256 in_guid, bytes proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.AlicePropose );

        // Must provide proof of OnAliceCancel or OnBobReject
        require( swap.alice.remote.Verify(0x0, proof) );

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

        SafeTransfer( swap.bob.token, address(this), swap.bob.addr, swap.bob.amount );

        emit OnAliceWithdraw( in_guid );
    }


    function TransitionBobAccept ( uint256 in_guid, Swap in_swap, bytes proof )
        public
    {
        // Swap must not already exist on Bobs chain to Accept
        require( SwapDoesNotExist(in_guid) );

        swaps[in_guid] = in_swap;

        // Must provide proof of OnAlicePropose
        require( in_swap.bob.remote.Verify(0x0, proof) );

        SafeTransfer( in_swap.bob.token, in_swap.bob.addr, address(this), in_swap.bob.amount );

        emit OnBobAccept( in_guid );
    }


    function TransitionBobReject ( uint256 in_guid, Swap in_swap, bytes proof )
        public
    {
        // Swap must not already exist on Bobs chain to Reject
        require( SwapDoesNotExist(in_guid) );

        swaps[in_guid] = in_swap;

        // Must provide proof of OnAlicePropose
        require( in_swap.bob.remote.Verify(0x0, proof) );

        emit OnBobReject( in_guid );
    }


    function TransitionBobWithdraw ( uint256 in_guid, bytes proof )
        public
    {
        // Swap must exist on Bobs chain to Withdraw
        Swap storage swap = GetSwap(in_guid);

        require( swap.state == State.AlicePropose );

        // Must provide proof of BobAccept
        require( swap.bob.remote.Verify( 0x0, proof ) );

        swap.state = State.BobWithdraw;

        // Transfer the funds Alice deposited to Bob
        SafeTransfer( swap.alice.token, address(this), swap.bob.addr, swap.alice.amount );

        emit OnBobWithdraw( in_guid );
    }


    function SwapDoesNotExist( uint256 in_swap_id )
        internal view returns (bool)
    {
        return SwapStateIs(in_swap_id, State.Invalid);
    }


    function SwapStateIs( uint256 in_swap_id, State state )
        internal view returns (bool)
    {
        return swaps[in_swap_id].state == state;
    }


    function GetSwap( uint256 in_swap_id )
        internal view returns (Swap storage out_swap)
    {
        out_swap = swaps[in_swap_id];
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
