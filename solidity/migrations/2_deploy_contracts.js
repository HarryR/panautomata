const MockProofVerifier = artifacts.require("MockProofVerifier");
const ExampleSwap = artifacts.require("ExampleSwap");

module.exports = async (deployer) => {
    await deployer.deploy(MockProofVerifier);
	await deployer.deploy(ExampleSwap, MockProofVerifier.address);
};