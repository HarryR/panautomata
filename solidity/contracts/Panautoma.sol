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
    function VerifyEvent( Panautoma.RemoteContract self, bytes32 in_event_sig, bytes in_event_args, bytes proof )
        internal view returns (bool)
    {
        bytes32 leaf_hash = keccak256(abi.encodePacked(
            self.addr,
            in_event_sig,   // topic
            keccak256(in_event_args)
        ));
        return self.prover.Verify(self.nid, leaf_hash, proof);
    }


    function VerifyTransaction( Panautoma.RemoteContract self, address in_from_addr, uint256 in_value, bytes in_input, bytes proof )
        internal view returns (bool)
    {
        bytes32 leaf_hash = keccak256(abi.encodePacked(
            in_from_addr,
            self.addr,  // destination
            in_value,
            keccak256(in_input)
        ));
        return self.prover.Verify(self.nid, leaf_hash, proof);
    }
} 
