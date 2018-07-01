const MockProofVerifier = artifacts.require("MockProofVerifier");
const ExampleSwap = artifacts.require("ExampleSwap");
const LithiumLink = artifacts.require("LithiumLink");
const ExampleERC20Token = artifacts.require("ExampleERC20Token");
const ExamplePingPongA = artifacts.require("ExamplePingPongA");
const ExamplePingPongB = artifacts.require("ExamplePingPongB");

module.exports = async (deployer) => {
    await deployer.deploy(MockProofVerifier);
    await deployer.deploy(LithiumLink, 0);

    // Deploy examples
    await deployer.deploy(ExampleSwap);
    await deployer.deploy(ExampleERC20Token);
    await deployer.deploy(ExamplePingPongA);
    await deployer.deploy(ExamplePingPongB);
};
