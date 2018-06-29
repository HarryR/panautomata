const MockProofVerifier = artifacts.require("MockProofVerifier");
const ExampleSwap = artifacts.require("ExampleSwap");
const LithiumLink = artifacts.require("LithiumLink");
const ExampleERC20Token = artifacts.require("ExampleERC20Token");

module.exports = async (deployer) => {
    await deployer.deploy(MockProofVerifier);
    await deployer.deploy(LithiumLink, 1);
    await deployer.deploy(ExampleSwap);
    await deployer.deploy(ExampleERC20Token);
};
