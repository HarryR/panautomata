// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;

import "./Merkle.sol";


contract LithiumLink
{
    mapping(uint256 => uint256) internal m_blocks;

    uint256 public LatestBlock;

    address public Owner;

    constructor ( uint256 genesis )
        public
    {
        require( genesis > 0 );
        Owner = msg.sender;
        LatestBlock = genesis;
    }

    function Destroy ()
        public
    {
        require( msg.sender == Owner );

        selfdestruct( msg.sender );
    }

    function Update( uint256 in_start_height, uint256[] in_state )
        public
    {
        require( in_state.length > 0 );

        // Guard to prevent out-of-order updates
        require( in_start_height == LatestBlock );

        for (uint256 i = 0; i < in_state.length; i++)
        {
            m_blocks[in_start_height + i] = in_state[i];
        }

        LatestBlock = in_start_height + in_state.length;
    }

    function Verify( uint256 block_height, uint256 leaf_hash, uint256[] proof )
        public view returns (bool)
    {
        return Merkle.Verify( GetRoot(block_height), leaf_hash, proof );
    }

    function GetRoot( uint256 block_height )
        internal view returns (uint256 out_root)
    {
        out_root = m_blocks[block_height];

        require( out_root != 0 );
    }
}