 const {assert, expert} = require("chai")
 const {network, deployments, ethers, getNamedAccounts } = require("hardhat")
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace")
 const {developmentChains} = require("../../helper-hardhat-config")

 !developmentChains.includes(network.name)
 ? describe.skip
 : describe ("Markplace Tests", function () {
    let marketplace, basicNft, deployer, player
    const PRICES = ethers.utils.parseEther("0.1")
    const TOKEN_ID = 0
    beforeEach(async function(){
        deployer = (await getNamedAccounts()).deployer
        //player = (await getNamedAccounts()).player
        const accounts = await ethers.getSigners()
        player = account[1]
        await deployments.fixture(["all"])
        marketplace = await ethers.getContractAt("Marketplace")
        basicNft= await ethers.getContractAt("basicNft")
        await basicNft.mintNft()
        await basicNft.approve(marketplace.address, TOKEN_ID)
    })

    it("lists and can be brought", async function(){
        await marketplace.listItem(basicNft.address, TOKEN_ID, PRICES)
        const playerConnectedMarketPlace = marketplace.connect(player)
        await playerConnectedMarketPlace.buyItem(basicNft.address, TOKEN_ID,{
            value: PRICES,
        })
        const newOwner = await basicNft.ownerOf(TOKEN_ID)
        const deployerProceeds = await marketplace.getProceeds(deployer)
        assert(newOwner.toString()== player.address)
        assert (deployerProceeds.toString() == PRICES.toString())
    })

 })

 /// npx hardhat coverage- make the coverage to 100%