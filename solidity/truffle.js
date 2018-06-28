module.exports = {
    networks: {
        coverage: {
            host: "localhost",
            port: 8555,
            network_id: "*",
            gas: 0xFFFFFFFF,
            gasprice: 0x01
        },
        testrpc_a: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas: 0xFFFFFFFF,
            gasprice: 0x01
        },
        testrpc_b: {
            host: "localhost",
            port: 8546,
            network_id: "*", // Match any network id
            gas: 0xFFFFFFFF,
            gasprice: 0x01
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};