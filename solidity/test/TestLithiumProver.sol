pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "../contracts/LithiumProver.sol";
import "../contracts/example/ExamplePingPong.sol";


contract TestLithiumProver
{
    using LithiumProofObj for LithiumProver.Proof;

    function testExtractProof () public
    {
        bytes memory l_proof_bytes = hex"8d9ccdca4ce221658d32a950df33c0f6b1ce9e77dbc8c9eb7c4e8233ecdfbc79bc1c4a94a3986694937f101743b7d480425fcd91f83a3318dee26da0fb6f83a2d0c4b1ded41be05fbb3474ad595ece81";

        LithiumProver.Proof memory l_proof;

        l_proof.ExtractFromBytes(l_proof_bytes);

        Assert.equal(uint256(l_proof.block_id), 10204257124471677285, "Block id doesnt match");

        Assert.equal(uint256(l_proof.tx_idx), 2368907600, "Transaction index doesnt match");

        Assert.equal(uint256(l_proof.log_idx), 3744710902, "Log index doesnt match");

        Assert.equal(l_proof.path.length, 2, "Path length doesnt match");

        Assert.equal(l_proof.path[0], 80424438401884935789970964740987389972556002562470641060097768235088337163392, "path[0] doesnt match");

        Assert.equal(l_proof.path[1], 30021917270984277206208152510958953294091162003115278692267036093961027374721, "path[1] doesnt match");
    }

    function testVerifyProof () public
    {
        bytes memory outer_leaf_bytes = hex"000000000000000a0000000000000000351cae316a571ad60d38b8f87666d79e47314b66cafd00cebca4d0b6f435a175";
        bytes32 outer_leaf_hash = keccak256(outer_leaf_bytes);
        bytes32 inner_leaf_hash = 0x351cae316a571ad60d38b8f87666d79e47314b66cafd00cebca4d0b6f435a175;

        bytes memory proof_bytes = hex"000000000000000a0000000000000000e6843bf393570479a2656a819bf8d219c1dde89fe0b6f73c6299bf202fe755d1";

        uint256[] memory l_roots = new uint256[](1);
        l_roots[0] = 18816486038835455661079455548344429740997917459031915165980477461056310113737;

        uint block_height = 10;

        LithiumLink l_link = new LithiumLink(1, block_height - 1);
        l_link.Update(block_height - 1, l_roots);
        Assert.equal( l_link.GetHeight(), block_height, "Link height incorrect!" );
        Assert.equal( l_link.GetRoot(block_height), l_roots[0], "Root incorrect!" );

        // Check it's extracted properly
        LithiumProver.Proof memory l_proof;
        l_proof.ExtractFromBytes(proof_bytes);
        Assert.equal( l_proof.block_id, block_height, "Block ID mismatch" );
        Assert.equal( l_link.GetHeight(), l_proof.block_id, "Link height incorrect!" );

        // Check the merkle root verifies
        Assert.equal( Merkle.Verify( l_roots[0], uint256(outer_leaf_hash), l_proof.path ), true, "Merkle path invalid!" );

        // Then verify that, when combining the two, it works
        LithiumProver l_prover = new LithiumProver(l_link);
        Assert.equal( l_prover.Verify( 1, inner_leaf_hash, proof_bytes ), true, "LithiumProver failed" );
    }
}
