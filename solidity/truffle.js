module.exports = {
    networks: {
        testrpca: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        testrpcb: {
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