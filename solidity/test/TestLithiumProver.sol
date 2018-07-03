pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "../contracts/LithiumProver.sol";
import "../contracts/example/ExamplePingPong.sol";


contract TestLithiumProver
{
	using LithiumProofObj for LithiumProver.Proof;

	function testExtractProof () public
	{
		bytes memory l_proof_bytes = hex"107f0dabebec72ed1530a194f351489c0b108ce9dd96ab85b43fb81897f75da65015084426392b81479120687beb1bb84dc4bb7cea0c82e8f4360d7506499be478d4a2f59e914788af07c80a44332cfee635bdce9f1ea35faf90966816395c4526bde061e4ca095e9ebb33d68b1d8669929e9abc47f4552ccf9edfc9bf3349503f13cef6a3c1b4c5dc41ce02f7acba57951562612b259c5e6142939e973f1b76";

		LithiumProver.Proof memory l_proof;

		l_proof.ExtractFromBytes(l_proof_bytes);

		Assert.equal(l_proof.block_id, 7461489512258163374041530170852127195527652993822138159417364311477008686502, "Block id doesnt match");

		Assert.equal(l_proof.path.length, 4, "Path length doesnt match");

		Assert.equal(l_proof.path[0], 36222188726294190264724830160807535941260076560650537550934797372035380648932, "path[0] doesnt match");

		Assert.equal(l_proof.path[1], 54653238112519204180324512860157472072788888548741498024736590441498952686661, "path[1] doesnt match");

		Assert.equal(l_proof.path[2], 17523370971798060733335806876259516988655538119343184483725259609467205667152, "path[2] doesnt match");

		Assert.equal(l_proof.path[3], 28530707964116480372682371050079588246784656947532125351656222333555892493174, "path[3] doesnt match");
	}

	/**
	* From the PingPong example, verify the 'input' field of the 'Start'
	* transaction matches what is reconstructed as the leaf.
	*/
	function testFunctionSignature () public
	{
		uint256 tx_value = 0x0;
		bytes20 tx_from = 0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1;
		bytes20 tx_to = 0xd833215cbcc3f914bd1c9ece3ee7bf8b14f841bb;

		bytes memory tx_input = hex"79a821d91de6c5cbaef4de786531ffb6b5a16c0b967ad18e963eb73ed5c8b6b5e533d29d000000000000000000000000e982e462b094850f12af94d21d470e21be9d0e9c0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d833215cbcc3f914bd1c9ece3ee7bf8b14f841bb000000000000000000000000e982e462b094850f12af94d21d470e21be9d0e9c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000009561c133dd8580860b6b7e504bc5aa500f0f06a70000000000000000000000000000000000000000000000000000000000000001";

		Assert.equal(keccak256(tx_input), 0x75f0523b73d82ed4ea7c41c79bf046145b163aaeef0a866da4b78eb37372c533, "Input hashed not equal");

		bytes32 leaf_hashed = 0x984fee66fb992624026a0dbb84c516e00d92de5d2386540bfa8fdf3187a70e68;

		bytes memory leaf = hex"90f8bf6a479f320ead074411a4b0e7944ea8c9c1d833215cbcc3f914bd1c9ece3ee7bf8b14f841bb000000000000000000000000000000000000000000000000000000000000000075f0523b73d82ed4ea7c41c79bf046145b163aaeef0a866da4b78eb37372c533";

		Assert.equal(keccak256(leaf), leaf_hashed, "Leaf not equal!");

		uint256 merkle_root = 36185417635931376017670461218398888083340015553905443899945117225861057408299;

		bytes memory merkle_proof = hex"000000000000000000000000000000000000000000000000000000000000001fe6843bf393570479a2656a819bf8d219c1dde89fe0b6f73c6299bf202fe755d1";

		bytes memory tested_leaf = abi.encodePacked(address(tx_from), address(tx_to), uint256(tx_value), keccak256(tx_input));

		Assert.equal(tested_leaf.length, leaf.length, "Leaf length not equal");

		Assert.equal(keccak256(tested_leaf), leaf_hashed, "Packed hashed leaf not equal");

		uint256 guid = 13524812569138316855581441566737569768985335134419243598477260189797046276765;
		bytes20 prover_addr = 0xe982e462b094850f12af94d21d470e21be9d0e9c;
		bytes20 contract_a = 0xd833215cbcc3f914bd1c9ece3ee7bf8b14f841bb;
		bytes20 contract_b = 0x9561c133dd8580860b6b7e504bc5aa500f0f06a7;
	}
}
