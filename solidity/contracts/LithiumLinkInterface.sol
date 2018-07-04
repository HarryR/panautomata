// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;


contract LithiumLinkInterface
{
	function Update( uint256 in_start_height, uint256[] in_state ) public;

    function Verify( uint256 block_height, uint256 leaf_hash, uint256[] proof ) public view returns (bool);

	function GetRoot( uint256 block_height ) public view returns (uint256);    

	function GetNetworkId () public view returns (uint64);

	function GetHeight () public view returns (uint256);
}
