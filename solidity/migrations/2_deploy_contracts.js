const MockProofVerifier = artifacts.require("MockProofVerifier");
const ExampleSwap = artifacts.require("ExampleSwap");
const LithiumLink = artifacts.require("LithiumLink");
const LithiumProver = artifacts.require("LithiumProver");
const ExampleERC20Token = artifacts.require("ExampleERC20Token");
const ExamplePingPongA = artifacts.require("ExamplePingPongA");
const ExamplePingPongB = artifacts.require("ExamplePingPongB");
const Registrar = artifacts.require("Registrar");

module.exports = async (deployer, network, accounts) => {
    await deployer.deploy(MockProofVerifier);
    let link = await deployer.deploy(LithiumLink, deployer.network_id, 0);

    // Deploy examples
    await deployer.deploy(ExampleSwap);
    await deployer.deploy(ExampleERC20Token);
    await deployer.deploy(ExamplePingPongA);
    await deployer.deploy(ExamplePingPongB);

    await deployer.deploy(LithiumProver, link.address);

    await deployer.deploy(Registrar, accounts[0]);
};
