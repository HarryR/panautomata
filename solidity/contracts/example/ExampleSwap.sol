// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "../Panautoma.sol";


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

---------------------------------------------------------

Notes on reducing gas, storage costs, complexity etc.

It should be possible to remove nearly all storage required, instead of
emitting an event and then using the event as proof (which duplicates all
of the parameters passed into the function in both an event and as storage),
proof of the transaction can be passed (which includes all of the info) to
anything which needs proof of the OnAlicePromise step.

Then, to remove the necessity of storage completely, only the 'in_guid' 
needs to be flagged as being unusable (or its state saved) in order for
further actions on the state machine to be handled properly.

All the other side needs to perform a withdraw is proof of an event
from the other chain which contains the token address, reciever and 
amount.
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
        Panautoma.RemoteContract swap_contract;
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
    event OnAlicePropose( uint256 guid, Swap swap );
    bytes32 constant public SIG_ON_ALICE_PROPOSE = keccak256("OnAlicePropose(uint256)");

    event OnAliceWithdraw( uint256 guid );
    bytes32 constant public SIG_ON_ALICE_WITHDRAW = keccak256("OnAliceWithdraw(uint256)");

    event OnAliceRefund( uint256 guid );
    bytes32 constant public SIG_ON_ALICE_REFUND = keccak256("OnAliceRefund(uint256)");

    event OnAliceCancel( uint256 guid );
    bytes32 constant public SIG_ON_ALICE_CANCEL = keccak256("OnAliceCancel(uint256)");

    event OnBobAccept( uint256 guid );
    bytes32 constant public SIG_ON_BOB_ACCEPT = keccak256("OnBobAccept(uint256)");

    event OnBobReject( uint256 guid );
    bytes32 constant public SIG_ON_BOB_REJECT = keccak256("OnBobReject(uint256)");

    event OnBobWithdraw( uint256 guid );
    bytes32 constant public SIG_ON_BOB_WITHDRAW = keccak256("OnBobWithdraw(uint256)");

  
    function TransitionAlicePropose ( uint256 in_guid, Swap in_swap )
        public returns (bool)
    {
        require( SwapDoesNotExist(in_guid) );

        require( in_swap.state == State.AlicePropose );

        require( in_swap.alice.swap_contract.addr == address(this) );

        swaps[in_guid] = in_swap;

        // Transfer must occur after storing swap to storage
        // Otherwise Swap will still be in Invalid state...
        SafeTransfer( in_swap.alice.token, in_swap.alice.addr, address(this), in_swap.alice.amount );

        return true;
    }


    /**
    * On Bobs chain, Alice pre-emptively cancels the swap
    * Alice provides proof of TransitionAlicePropose on chain A to chain B
    */
    function TransitionAliceCancel ( uint256 in_guid, Swap in_swap, bytes in_proof )
        public
    {
        // Swap must not exist on Bobs chain
        require( SwapDoesNotExist(in_guid) );

        require( in_swap.bob.swap_contract.addr == address(this) );

        require( in_swap.alice.swap_contract.VerifyTransaction(
            in_swap.alice.addr,                 // from
            0,                                  // value
            this.TransitionAlicePropose.selector,    // selector
            abi.encode(in_guid, in_swap),       // args
            in_proof                            // proof
        ));

        in_swap.state = State.AliceCancel;

        swaps[in_guid] = in_swap;

        emit OnAliceCancel( in_guid );
    }


    /**
    * Alice provides proof of OnAliceCancel on chain B to chain A
    */
    function TransitionAliceRefundAfterCancel ( uint256 in_guid, bytes in_proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.bob.swap_contract.addr == address(this) );

        require( swap.state == State.AlicePropose );

        require( swap.bob.swap_contract.VerifyEvent(SIG_ON_ALICE_CANCEL, abi.encode(in_guid), in_proof) );

        swap.state = State.AliceRefund;

        emit OnAliceRefund( in_guid );
    }


    /**
    * Alice must provide proof of OnBobReject on chain B to chain A
    */
    function TransitionAliceRefundAfterReject ( uint256 in_guid, bytes in_proof )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.bob.swap_contract.addr == address(this) );

        require( swap.state == State.AlicePropose );

        require( swap.bob.swap_contract.VerifyEvent(SIG_ON_BOB_REJECT, abi.encode(in_guid), in_proof) );

        swap.state = State.AliceRefund;

        emit OnAliceRefund( in_guid );
    }

    /**
    * As soon as Bob has accepted on chain B, Alice can withdraw from chain B
    */
    function TransitionAliceWithdraw ( uint256 in_guid )
        public
    {
        Swap storage swap = GetSwap(in_guid);

        require( swap.bob.swap_contract.addr == address(this) );

        require( swap.state == State.BobAccept );

        // No proof needed, as soon as Bob accepts (and provides proof)

        swap.state = State.AliceWithdraw;

        SafeTransfer( swap.bob.token, address(this), swap.alice.addr, swap.bob.amount );

        emit OnAliceWithdraw( in_guid );
    }


    /**
    * Bob accepts Alice's proposal by providing proof of her TransitionAlicePropose transaction
    */
    function TransitionBobAccept ( uint256 in_guid, Swap in_swap, bytes in_proof )
        public
    {
        // Swap must not already exist on Bobs chain to Accept
        require( SwapDoesNotExist(in_guid) );

        require( in_swap.state == State.AlicePropose );

        require( in_swap.bob.swap_contract.addr == address(this) );

        // Must provide proof of OnAlicePropose
        require( in_swap.alice.swap_contract.VerifyTransaction(
            in_swap.alice.addr,                     // from
            0,                                      // value
            this.TransitionAlicePropose.selector,   // selector
            abi.encode(in_guid, in_swap),           // args
            in_proof                                // proof
        ) );

        in_swap.state = State.BobAccept;

        swaps[in_guid] = in_swap;

        SafeTransfer( in_swap.bob.token, in_swap.bob.addr, address(this), in_swap.bob.amount );

        emit OnBobAccept( in_guid );
    }


    function TransitionBobReject ( uint256 in_guid, Swap in_swap, bytes in_proof )
        public
    {
        // Swap must not already exist on Bobs chain to Reject
        require( SwapDoesNotExist(in_guid) );

        require( in_swap.bob.swap_contract.addr == address(this) );

        in_swap.state = State.BobReject;

        swaps[in_guid] = in_swap;

        // Must provide proof of OnAlicePropose
        require( in_swap.alice.swap_contract.VerifyEvent(SIG_ON_ALICE_PROPOSE, abi.encode(in_guid, in_swap), in_proof) );

        emit OnBobReject( in_guid );
    }


    function TransitionBobWithdraw ( uint256 in_guid, bytes in_proof )
        public
    {
        // Swap must exist on Bobs chain to Withdraw
        Swap storage swap = GetSwapInState(in_guid, State.AlicePropose);

        require( swap.alice.swap_contract.addr == address(this) );

        // Must provide proof of BobAccept
        require( swap.bob.swap_contract.VerifyEvent( SIG_ON_BOB_ACCEPT, abi.encode(in_guid), in_proof ) );

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


    function GetSwapInState( uint256 in_swap_id, State state )
        internal view returns (Swap storage out_swap)
    {
        out_swap = swaps[in_swap_id];
        require( out_swap.state == state );
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
