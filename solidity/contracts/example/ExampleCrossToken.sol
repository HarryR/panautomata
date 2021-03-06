// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;
pragma experimental "v0.5.0";
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../Panautoma.sol";


/*
* Provides a mechanism for depositing Ether on one chain and then
* using it tokenized form on another chain. Any tokens given to anybody
* on the other chain can be redeemed on the other chain for its original
* value.
*
* This is made possible by making sure that value can only be on one place
* at any one point in time. To use value on another chain you must first
* ensure that it can't be used anywhere else.
*
* So, you deposit your value onto a lock on Chain A, in a way which can only
* be withdrawn on Chain B (in tokenized form), this creates N 'meta tokens'
* of 'N of X from A on B'.
*
* If you are given M tokens of the 'N of X from A on B' tokens, you can
* 'burn' then on chain B, then on Chain A the proof of Burn can be redeemed
* for M tokens of the original value.
*/


/**
* The lock contract can have Ether deposited into it, to be redeemed on
* another chain in tokenized form by the specified address. Once deposited
* it cannot be withdrawn until the person it was deposited for provides
* proof of burn from the other chain.
*/
contract ExampleCrossTokenLock
{
    using RemoteContractLib for Panautoma.RemoteContract;

    using SafeMath for uint256;


    mapping( bytes32 => uint256 ) internal m_deposits;


    function Deposit ( Panautoma.RemoteContract in_remote )
        public payable
    {
        // Deposit creates proof that value has been locked

        bytes32 l_rchash = in_remote.GUID();

        m_deposits[l_rchash] = m_deposits[l_rchash].add(msg.value);
    }


    function Withdraw ( Panautoma.RemoteContract in_remote, uint256 in_amount, bytes in_proof )
        public
    {
        // Proof of Burn allows Withdraw

        bytes32 l_rchash = in_remote.GUID();

        // Verify m_deposits is greater or equal to withdraw amount
        require( m_deposits[l_rchash] >= in_amount );

        bool tx_ok = in_remote.VerifyTransaction(
            msg.sender,
            0,
            bytes4(ExampleCrossTokenProxy(this).Burn.selector),
            abi.encode(in_amount),
            in_proof
        );
        require( tx_ok );

        m_deposits[l_rchash] = m_deposits[l_rchash].sub(in_amount);

        msg.sender.transfer(in_amount);
    }
}


// TODO: add a factory contract which creates the token contracts for each source
//       you query the main contract for which contract exists that can be a proxy
//       if it returns none, then you tell it to create a contract, which can be used
//       in future if you request tokens from the same source.


/**
* The proxy token contract allows others to redeem tokens of
* equivalent value if deposited on the original chain.
*
* Upon 'Burning' these tokens, the proof of burn can be used
* to 'Withdraw' the original value on the original chain.
*/
contract ExampleCrossTokenProxy is StandardToken
{
    using RemoteContractLib for Panautoma.RemoteContract;

    using SafeMath for uint256;

    bytes32 internal m_locked_to;


    // Proof of Deposit allows Redeem on this chain
    function Redeem ( Panautoma.RemoteContract in_lock_remote, Panautoma.RemoteContract in_self_remote, uint256 in_amount, bytes in_proof )
        public
    {
        // Upon first redemption this contract is locked to a specific remote
        // lock contract, this prevents mixing of tokens from multiple sources.
        if (m_locked_to != 0x0) {
            require( m_locked_to == in_lock_remote.GUID() );
        } else {
            m_locked_to = in_lock_remote.GUID();
        }

        // Remote contract must be ourselves
        require( in_self_remote.addr == address(this) );

        // Proof of a Deposit transaction on the other side
        bool tx_ok = in_lock_remote.VerifyTransaction(
            msg.sender,
            in_amount,
            bytes4(ExampleCrossTokenLock(this).Deposit.selector),
            abi.encode(in_self_remote),
            in_proof
        );
        require( tx_ok );

        totalSupply_ = totalSupply_.add(in_amount);

        balances[msg.sender] = balances[msg.sender].add(in_amount);
    }


    function Burn ( uint256 in_amount )
        public
    {
        // Proof of Burn allows Withdraw on original chain

        balances[msg.sender] = balances[msg.sender].sub(in_amount);

        totalSupply_ = totalSupply_.sub(in_amount);
    }
}
