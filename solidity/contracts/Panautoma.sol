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
	function Verify( Panautoma.RemoteContract self, bytes32 leaf_hash, bytes proof )
		internal view returns (bool)
	{
		return self.prover.Verify(self.nid, self.addr, leaf_hash, proof);
	}
} 
