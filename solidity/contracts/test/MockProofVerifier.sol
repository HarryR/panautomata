// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;


import "../ProofVerifierInterface.sol";


contract MockProofVerifier is ProofVerifierInterface
{
    function Verify( uint64 network_id, bytes32 leaf_hash, bytes proof )
        external view returns (bool)
    {
        require( network_id > 0 );
        require( leaf_hash != 0x0 );
        require( proof.length > 0 );
        return true;
    }

    function Timestamp( bytes proof )
        external view returns (uint256)
    {
        require( proof.length > 0 );
        return 0;
    }
}
