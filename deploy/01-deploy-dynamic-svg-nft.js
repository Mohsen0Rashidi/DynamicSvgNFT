const { deployments, getNamedAccounts, network, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const fs = require("fs")
const { verify } = require("../utils/verify")

module.exports = async ({ deployments, getNamedAccounts }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    let dynamicSvgNft, mockV3Aggregator, ethUsdPriceFeedAddress

    if (developmentChains.includes(network.name)) {
        // Find ETH/USD price feed
        mockV3Aggregator = await ethers.getContract("MockV3Aggregator")
        ethUsdPriceFeedAddress = mockV3Aggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeed
    }

    const lowSvg = fs.readFileSync("./images/frown.svg", { encoding: "utf-8" })
    const highSvg = fs.readFileSync("./images/happy.svg", { encoding: "utf-8" })

    const arguments = [ethUsdPriceFeedAddress, lowSvg, highSvg]

    dynamicSvgNft = await deploy("DynamicSvgNft", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log("Dynamic NFT Deployed!")
    log("----------------------------------------")

    // Verify the deployment

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(dynamicSvgNft.address, arguments)
    }
}

module.exports.tags = ["all", "dynamicsvgnft"]
