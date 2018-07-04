// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;


import "../Panautoma.sol";


/**
 * The ping pong example requires two contracts on two separate networks.
 * It demonstrates the passing of both events and transactions to each other.
 *
 * The process is started on one side. Lets call that side 'A'
 * Proof of the Start transaction is sent to the other side. Lets call that side 'B'
 * `B` then emits an event acknowledging proof of the `Start` transaction, the 'Ping'
 * Proof of that event is passed to `A`, which in turn emits the 'Pong' event.
 *
 * At each step the counter for the Guid is incremented, this ensures that the
 * next event processed by either side is what was expected.
 *
 * The 'Start' transaction binds the process between two contracts on different
 * networks, and specifies the 'Prover' contract they use. This binds the `A` side
 * to a specific configuration.
 *
 * Then the `ReceiveStart` function binds `B`s side to the same details.
 *
 * After that both sides can exchange events without having to specify the full
 * details upon every call to `ReceivePing` and `ReceievePong`.
 */
contract ExamplePingPongCommon
{
    using RemoteContractLib for Panautoma.RemoteContract;

    struct Session {
        Panautoma.RemoteContract alice;
        Panautoma.RemoteContract bob;
        uint256 counter;
    }


    mapping( uint256 => Session ) internal m_sessions;

    event Ping( uint256 session_guid, uint256 incr );

    event Pong( uint256 session_guid, uint256 incr );


    /**
    * Initiate PingPong session on Alice's side
    */
    function Start (uint256 in_guid, Session in_session)
        public
    {
        // Session must not already exist
        require( m_sessions[in_guid].counter == 0 );

        // New session counter must start at 1
        require( in_session.counter == 1 );

        // The 'alice' side must be us
        // TODO: verify in_session.alice.nid
        require( in_session.alice.addr == address(this) );

        m_sessions[in_guid] = in_session;
    }


    /**
    * Bob's side receives proof of the 'Start' transaction from Alice's contract
    * This emits a Ping event which will be passed back to Alice
    * The counter is incremented
    */
    function ReceiveStart (uint256 in_guid, Session in_session, bytes in_proof )
        public
    {
        require( m_sessions[in_guid].counter == 0 );

        require( in_session.counter == 1 );

        // The 'bob' side must be us
        // TODO: verify in_session.bob.nid
        require( in_session.bob.addr == address(this) );

        bool tx_ok = in_session.alice.VerifyTransaction(msg.sender, 0, bytes4(this.Start.selector), abi.encode(in_guid, in_session), in_proof);

        require( true == tx_ok );

        in_session.counter += 1;

        m_sessions[in_guid] = in_session;

        emit Ping(in_guid, in_session.counter);
    }


    /**
    * Alice's side receives proof of the `Ping` event from Bob's side
    * Emits a `Pong` event
    */
    function ReceivePing (uint256 in_guid, bytes in_proof )
        public
    {
        Session storage l_session = m_sessions[in_guid];

        require( l_session.counter > 0 );

        bytes32 l_event_sig = keccak256(abi.encodePacked("Ping(uint256,uint256)"));

        require( true == l_session.bob.VerifyEvent(l_event_sig, abi.encode(in_guid, l_session.counter + 1), in_proof) );

        l_session.counter += 2;

        emit Pong(in_guid, l_session.counter);
    }


    /**
    * Recieves proof of the `Pong` event
    * Emits a `Ping` event
    */
    function ReceivePong (uint256 in_guid, bytes in_proof ) public
    {
        Session storage l_session = m_sessions[in_guid];

        require( l_session.counter > 1 );

        bytes32 l_event_sig = keccak256(abi.encodePacked("Pong(uint256,uint256)"));

        require( true == l_session.alice.VerifyEvent(l_event_sig, abi.encode(in_guid, l_session.counter + 1), in_proof) );

        l_session.counter += 2;

        emit Ping(in_guid, l_session.counter);
    }
}


contract ExamplePingPongA is ExamplePingPongCommon
{

}


contract ExamplePingPongB is ExamplePingPongCommon
{

}
