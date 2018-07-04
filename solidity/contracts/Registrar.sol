// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;


/**
* Allows contracts to associate a name with their address,
* and to lookup the address for a name.
*
* e.g.
* ```solidity
*   constructor (Registrar in_registry)
*   {
*       in_registry.RegisterSelf("MyName");
*   }
* ```
*
* Then in another contract you can do
* ```solidity
*   function UseMyName (Registrar in_registry) public {
*       MyName l_contract = MyName(in_registry.Lookup("MyName"));
*       l_contract.DoStuff();
*   }
* ```
*
* The idea is that a suite of contracts will can be linked to a single
* common registry, this should make life simpler for clients as they
* can lookup the address of a contract from a single entry point.
*
* For `RegisterSelf` the transaction origin must be the owner.
* For `RegisterByOwner` the sender must be the owner.
*
* There is an edge case in `RegisterSelf` where the owner may call
* a contract, which then proceeds to perform a malicious registration,
* however - because names cannot be overwritten or removed this is
* of limited use for a potential attack, but must be considered. 
*/
contract Registrar
{
	mapping(bytes32 => address) m_names;

	address m_owner;


	constructor (address in_owner) public
	{
		require( in_owner != address(0x0) );

		m_owner = in_owner;
	}


	function InternalRegister (bytes32 in_name_hash, address in_addr)
		internal
	{
		// Name must not be registered
		require( m_names[in_name_hash] == address(0x0) );

		// Must be a contract
		uint256 code_length;
        assembly {
            code_length := extcodesize(in_addr)
        }
        require( code_length > 0 );

        // Associate the name with the address
		m_names[in_name_hash] = in_addr;
	}


	function RegisterByOwner (bytes32 in_name_hash, address in_addr)
		public
	{
		require( msg.sender == m_owner );

		InternalRegister(in_name_hash, in_addr);
	}


	function RegisterByOwner (string in_name, address in_addr)
		public
	{
		RegisterByOwner(keccak256(abi.encodePacked(in_name)), in_addr);
	}


	function RegisterSelf (string in_name)
		public
	{
		RegisterSelf(keccak256(abi.encodePacked(in_name)));
	}


	function RegisterSelf (bytes32 name_hash)
		public
	{
		// Only the owner may be the origin of the transaction
		require( tx.origin == m_owner );

		InternalRegister(name_hash, msg.sender);
	}


	function Lookup (string in_name)
		public view returns (address)
	{
		return Lookup(keccak256(abi.encodePacked(in_name)));
	}


	function Lookup (bytes32 name_hash)
		public view returns (address)
	{
		require( m_names[name_hash] != address(0x0) );

		return m_names[name_hash];
	}
}
