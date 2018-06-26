// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;


interface ProofVerifierInterface
{
    function Verify( bytes32 leaf_hash, bytes proof ) external view returns (bool);
}
