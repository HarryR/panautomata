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


    function testVerifyProof () public
    {
        bytes32 leaf_hash = 0x0df1aef7cd1f602cde3f892440bf40f458c52e228b37476c02c59990d7978da3;

        bytes memory leaf_proof = hex"000000000000000000000000000000000000000000000000000000000000001ee6843bf393570479a2656a819bf8d219c1dde89fe0b6f73c6299bf202fe755d1";

        uint256[] memory l_state = new uint256[](1);
        l_state[0] = 36309678569118526148872637980630051425706212671800593816880788491663080654976;

        LithiumLink l_link = new LithiumLink(1, 29);
        l_link.Update(29, l_state);
        Assert.equal( l_link.GetHeight(), 30, "Link height incorrect!" );
        Assert.equal( l_link.GetRoot(30), l_state[0], "Root incorrect!" );

        // Check it's extracted properly
        LithiumProver.Proof memory l_proof;
        l_proof.ExtractFromBytes(leaf_proof);
        Assert.equal( l_proof.block_id, 30, "Block ID mismatch" );
        Assert.equal( l_link.GetHeight(), l_proof.block_id, "Link height incorrect!" );

        // Check the merkle root verifies
        Assert.equal( Merkle.Verify( l_state[0], uint256(leaf_hash), l_proof.path ), true, "Merkle path invalid!" );

        // Then verify that, when combining the two, it works
        LithiumProver l_prover = new LithiumProver(l_link);
        Assert.equal( l_prover.Verify( 1, leaf_hash, leaf_proof ), true, "LithiumProver failed" );
    }
}
