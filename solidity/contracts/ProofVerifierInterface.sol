// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: LGPL-3.0+

pragma solidity 0.4.24;


interface ProofVerifierInterface {
    function Verify( uint256 block_no, uint256 leaf_hash, uint256[] proof ) external view returns (bool);
}
