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
}
