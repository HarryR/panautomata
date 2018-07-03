// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;
//pragma experimental "v0.5.0";

import "./ProofVerifierInterface.sol";
import "./Merkle.sol";
import "./LithiumLink.sol";


library LithiumProofObj
{
    function bytesToUint256(bytes b, uint offset)
        private pure returns (uint256)
    {
        bytes32 out;

        // XXX: replace with
        // staticcall(3000, 4, add(b, add(offset, 32)), 32, out, 32)
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }

        return uint256(out);
    }


    function ExtractFromBytes ( LithiumProver.Proof memory self, bytes memory in_proof )
        internal pure
    {
        uint n;
        uint k = 0;
        uint m = 0;

        // Encoded as uint256, then array of uint256 path elements
        // No length specifier is needed, as that's deducible from total length
        require( in_proof.length > 32 );
        require( in_proof.length % 32 == 0 );

        self.block_id = bytesToUint256(in_proof, 0); // uint256(in_proof[0]);

        self.path = new uint256[]( (in_proof.length - 32) / 32 );

        for( n = 32; n < in_proof.length; n += 32 )
        {
            m += 32;
            self.path[ k++ ] = bytesToUint256(in_proof, m);
        }
    }   
}


contract LithiumProver
{
    using LithiumProofObj for Proof;

    struct Proof
    {
        uint256 block_id;
        uint256[] path;
    }

    LithiumLink m_link;


    function LithiumProver ( LithiumLink in_link )
        public
    {
        m_link = in_link;
    }


    function Verify( uint64 in_network_id, bytes32 in_leaf_hash, bytes in_proof_bytes )
        external view returns (bool)
    {
        require( in_network_id == m_link.NetworkId() );

        require( in_leaf_hash != 0x0 );

        Proof memory l_proof;

        l_proof.ExtractFromBytes(in_proof_bytes);

        return m_link.Verify( l_proof.block_id, uint256(in_leaf_hash), l_proof.path );
    }


    function Timestamp( bytes in_proof_bytes )
        external view returns (uint256)
    {
        Proof memory l_proof;

        l_proof.ExtractFromBytes(in_proof_bytes);

        return l_proof.block_id;
    }
}
