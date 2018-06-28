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


library RemoteContractLib {
	function VerifyEvent( Panautoma.RemoteContract self, bytes32 in_event_sig, bytes in_event_args, bytes proof )
		internal view returns (bool)
	{
		return self.prover.Verify(self.nid, self.addr, keccak256(abi.encodePacked(in_event_sig, in_event_args)), proof);
	}
} 
