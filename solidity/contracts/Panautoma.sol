// Copyright (c) 2018 HarryR. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0+

pragma solidity 0.4.24;

import "./ProofVerifierInterface.sol";


library Panautoma
{
    struct RemoteContract {
        ProofVerifierInterface prover;
        uint64 nid;
        address addr;
    }
}


library RemoteContractLib
{
    function VerifyEvent( Panautoma.RemoteContract self, bytes32 in_event_sig, bytes in_event_args, bytes in_proof )
        internal view returns (bool)
    {
        bytes32 leaf_hash = keccak256(abi.encodePacked(
            self.addr,
            in_event_sig,   // topic
            keccak256(in_event_args)
        ));

        return self.prover.Verify(self.nid, leaf_hash, in_proof);
    }


    function VerifyTransaction( Panautoma.RemoteContract self, address in_from_addr, uint256 in_value, bytes4 in_selector, bytes in_args, bytes in_proof )
        internal view returns (bool)
    {   // Must explicitly specify bytes4() with `encodePacked` !
        bytes memory l_input = abi.encodePacked(bytes4(in_selector), in_args);

        bytes memory l_leaf = abi.encodePacked(
            in_from_addr,
            self.addr,  // destination
            in_value,
            keccak256(l_input)
        );
        bytes32 l_leaf_hash = keccak256(l_leaf);

        return self.prover.Verify(self.nid, l_leaf_hash, in_proof);
    }
} 
