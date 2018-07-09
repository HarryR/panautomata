// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "./Merkle.sol";


contract LithiumLink
{
    mapping(uint64 => Block) internal m_blocks;

    uint64 internal m_height;

    uint64 internal m_network_id;

    struct Block {
        uint256 merkle_root;
        uint256 block_hash;
    }


    constructor ( uint64 in_network_id, uint64 in_start_height )
        public
    {
        require( in_start_height >= 0 );

        m_height = in_start_height;

        m_network_id = in_network_id;
    }


    function GetNetworkId () public view returns (uint64)
    {
        return m_network_id;
    }


    function GetHeight () public view returns (uint256)
    {
        return m_height;
    }


    // TODO: verify owner matches
    /**
    * Update blocks by providing the new merkle roots and block hashes
    * in_blocks is supplied in pairs of (merkle_root, block_hash)
    *
    * The current height must be provided to avoid out of order updates.
    */
    function Update( uint64 in_start_height, uint256[] in_blocks )
        public
    {
        uint64 l_offset = in_start_height;

        require( in_blocks.length > 0 );

        require( in_blocks.length % 2 == 0 );

        // Guard to prevent out-of-order updates
        require( in_start_height == m_height );

        for (uint64 i = 0; i < in_blocks.length; i += 2)
        {
            m_blocks[++l_offset] = Block(in_blocks[i], in_blocks[i + 1]);
        }

        m_height = l_offset;
    }


    function Verify( uint64 block_height, uint256 leaf_hash, uint256[] proof )
        public view returns (bool)
    {
        return Merkle.Verify( GetMerkleRoot(block_height), leaf_hash, proof );
    }


    function GetBlockHash( uint64 in_height )
        public view returns (uint256 out_hash)
    {
        out_hash = m_blocks[in_height].block_hash;

        require( out_hash != 0 );
    }


    function GetMerkleRoot( uint64 in_height )
        public view returns (uint256 out_root)
    {
        Block storage l_block = m_blocks[in_height];

        require( l_block.block_hash != 0 );

        out_root = l_block.merkle_root;
    }
}
