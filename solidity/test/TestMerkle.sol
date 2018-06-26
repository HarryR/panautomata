pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "../contracts/Merkle.sol";


contract TestMerkle
{
	function testPythonCompatibility () public
	{
		uint256 root = 0x6d38ae87a66a8e96b41739f932c76f4a577c6d44543f425ee6c69f38ac603c4d;

		uint256 leaf = 98;

		uint256 leaf_hash = uint256(keccak256(abi.encodePacked(leaf)));

		uint256[] memory path = new uint256[](7);

		path[0] = 0x38dfe4635b27babeca8be38d3b448cb5161a639b899a14825ba9c8d7892eb8c3;
		path[1] = 0x6b7baf03c6f2cb1c99b2d1dadfb5d9e6a3d170d5e9ce5c18525534035da8d03a;
		path[2] = 0x7a0e7e83029773e518588d81b6263df0ca2940c1a1ae70b66f0b0dce0a628e66;
		path[3] = 0xd3bfcdc03ae4570ba8f1b90e25c0ff296f2af852a93212161883694a3455fd16;
		path[4] = 0xff339310cd67a48c344c2f3125281710c49e849b2b5ea11323a669cee10c68c1;
		path[5] = 0x3bfe32d4b8eac1269bf9678ffc006360b7b2ebddcc5bbb1edfb63ed4e9006ed3;
		path[6] = 0xbd9879a422e8982cc2dce347da545502778b5ce5c63123504f87a152d48f373e;

		bool result = Merkle.Verify( root, leaf_hash, path );

		Assert.equal(result, true, "Python compatibility check failed" );
	}
}
