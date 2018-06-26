// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;

import "./Merkle.sol";


contract LithiumLink
{
    struct Block
    {
        uint256 root;
        uint256 prev;
        uint256 time;
    }

    mapping(uint256 => Block) internal m_blocks;

    uint256 public LatestBlock;

    address public Owner;

    constructor ( uint256 genesis )
        public
    {
        Owner = msg.sender;
        LatestBlock = genesis;
    }

    function Destroy ()
        public
    {
        require( msg.sender == Owner );

        selfdestruct( msg.sender );
    }

    function GetTime( uint256 block_id )
        public view returns (uint256)
    {
        return GetBlock(block_id).time;
    }

    function GetPrevious( uint256 block_id )
        public view returns (uint256)
    {
        return GetBlock(block_id).prev;
    }

    function GetRoot( uint256 block_id )
        public view returns (uint256)
    {
        return GetBlock(block_id).root;
    }

    /**
    * Supplies a sequence of merkle roots which create a hash-chain
    *
    *   hash = H(hash, root)
    */
    function Update( uint256[] in_state )
        public
    {
        require( in_state.length > 1 );

        uint256 prev_hash = LatestBlock;

        for (uint256 i = 0; i < in_state.length; i++)
        {
            uint256 block_hash = uint256(keccak256(abi.encodePacked(
                prev_hash, in_state[i]
            )));

            Block storage blk = GetBlock(block_hash);

            blk.root = in_state[i];

            // Record state at time of block creation
            blk.prev = prev_hash;
            blk.time = block.timestamp;

            prev_hash = block_hash;
        }

        LatestBlock = prev_hash;
    }

    function Verify( uint256 block_id, uint256 leaf_hash, uint256[] proof )
        public view
        returns (bool)
    {
        return Merkle.Verify( GetRoot(block_id), leaf_hash, proof );
    }

    function GetBlock( uint256 block_id )
        internal view returns (Block storage)
    {
        Block storage blk = m_blocks[block_id];

        require( blk.root != 0 );

        return blk;
    }
}