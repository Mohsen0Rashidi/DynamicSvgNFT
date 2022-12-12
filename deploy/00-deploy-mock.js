const { deployments, getNamedAccounts, network } = require("hardhat")
const {
    developmentChains,
    DECIMALS,
    INITIAL_ANSWER,
} = require("../helper-hardhat-config")

module.exports = async ({ deployments, getNamedAccounts }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    if (developmentChains.includes(network.name)) {
        console.log("Local Network Detected!")

        const mockV3Aggreagtor = await deploy("MockV3Aggregator", {
            from: deployer,
            args: [ DECIMALS, INITIAL_ANSWER],
            log: true,
        })
    }
    log("Mock Deployed!")
    log("-----------------------------------------")
}

module.exports.tags = ["all", "mocks"]
