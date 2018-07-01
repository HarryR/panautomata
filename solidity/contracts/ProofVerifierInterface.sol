// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;


interface ProofVerifierInterface
{
    function Verify( uint64 network_id, bytes32 leaf_hash, bytes proof ) external view returns (bool);

    function Timestamp( bytes proof ) external view returns (uint256);
}
