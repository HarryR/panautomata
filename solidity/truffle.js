module.exports = {
    networks: {
        coverage: {
            host: "localhost",
            port: 8555,
            network_id: "*",
            gas: 0xFFFFFFFF,
            gasPrice: 0x1
        },
        testrpc_a: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        testrpc_b: {
            host: "localhost",
            port: 8546,
            network_id: "*" // Match any network id
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};