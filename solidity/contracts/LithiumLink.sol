// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;

import "./Merkle.sol";


contract LithiumLink
{
    mapping(uint256 => uint256) internal m_roots;

    uint256 internal m_height;

    uint64 internal m_network_id;


    constructor ( uint64 in_network_id, uint256 in_height )
        public
    {
        require( in_height >= 0 );

        m_height = in_height;

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


    function Update( uint256 in_start_height, uint256[] in_state )
        public
    {
        require( in_state.length > 0 );

        // TODO: verify owner matches

        // Guard to prevent out-of-order updates
        require( in_start_height == m_height );

        for (uint256 i = 0; i < in_state.length; i++)
        {
            m_roots[in_start_height + 1 + i] = in_state[i];
        }

        m_height = in_start_height + in_state.length;
    }


    function Verify( uint256 block_height, uint256 leaf_hash, uint256[] proof )
        public view returns (bool)
    {
        return Merkle.Verify( GetRoot(block_height), leaf_hash, proof );
    }


    function GetRoot( uint256 in_height )
        public view returns (uint256 out_root)
    {
        out_root = m_roots[in_height];

        require( out_root != 0 );
    }
}
