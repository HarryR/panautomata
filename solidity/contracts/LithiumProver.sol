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
    // TODO: replace these with a more generic version?
    // TODO: reduce duplication

    function bytesToUint64 (bytes b, uint offset)
        private view returns (uint64)
    {
        uint256[1] memory out;
        assembly {
            let baddr := add(add(b, 32), offset)
            let ret := staticcall(3000, 4, baddr, 32, add(out, 24), 8)
        }
        return uint64(out[0]);
    }


    function bytesToUint32 (bytes b, uint offset)
        private view returns (uint32)
    {
        uint256[1] memory out;
        assembly {
            let baddr := add(add(b, 32), offset)
            let ret := staticcall(3000, 4, baddr, 32,add(out, 28), 4)
        }
        return uint32(out[0]);
    }


    function bytesToUint256 (bytes b, uint offset)
        private view returns (uint256)
    {
        uint256[1] memory out;
        assembly {
            let baddr := add(add(b, 32), offset)
            let ret := staticcall(3000, 4, baddr, 32, out, 32)
        }
        return out[0];
    }


    function ExtractFromBytes ( LithiumProver.Proof memory self, bytes memory in_proof )
        internal view
    {
        uint n;
        uint k = 0;
        uint m = 16;

        // Encoded as (uint64,uint32,uint32) then array of uint256 path elements
        // No length specifier is needed, as that's deducible from total length
        // Minimum size: 16 bytes + (N * 32 bytes) where N >= 1

        uint paths_len_bytes = (in_proof.length - 16);

        require( in_proof.length >= 48 );
        require( paths_len_bytes % 32 == 0 );

        // Extract 'proof header' fields
        self.block_id = bytesToUint64(in_proof, 0);
        self.tx_idx = bytesToUint32(in_proof, 8);       // offset 64 bits
        self.log_idx = bytesToUint32(in_proof, 12);     // offset 96 bits

        // Then extract each item in the path
        self.path = new uint256[]( paths_len_bytes / 32 );

        for( n = 16; n < in_proof.length; n += 32 )
        {
            self.path[ k++ ] = bytesToUint256(in_proof, m);

            m += 32;
        }
    }
}


contract LithiumProver
{
    using LithiumProofObj for Proof;

    struct Proof
    {
        uint64 block_id;
        uint32 tx_idx;
        uint32 log_idx;

        uint256[] path;
    }

    LithiumLink internal m_link;


    constructor ( LithiumLink in_link )
        public
    {
        m_link = in_link;
    }


    function Verify( bytes32 in_leaf_hash, bytes in_proof_bytes )
        external view returns (bool)
    {
        require( in_leaf_hash != 0x0 );

        Proof memory l_proof;

        l_proof.ExtractFromBytes(in_proof_bytes);

        // Leaf is hashed with parameters from proof to make it unique to that proof
        bytes32 l_leaf_hash = keccak256(abi.encodePacked(
            //uint64(m_link.GetNetworkId()),
            uint64(l_proof.block_id),
            uint32(l_proof.tx_idx),
            uint32(l_proof.log_idx),
            in_leaf_hash
        ));

        return m_link.Verify( l_proof.block_id, uint256(l_leaf_hash), l_proof.path );
    }
}
