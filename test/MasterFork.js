const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("MasterFork", async function () {


    async function deploy() {

        const TestToken = await hre.ethers.getContractFactory("TestToken");
        testToken = await TestToken.deploy();
        
        await testToken.deployed();

        console.log("TestToken deployed to:", testToken.address);

        const  LpToken = await hre.ethers.getContractFactory("LpToken");
        lpToken = await LpToken.deploy();
        await lpToken.deployed();
        
        console.log("LpToken deployed to:", lpToken.address);
      
      
        const _myadress = "0x3769C1F158DB28A5a098C00ACC8EE6cdF91B27E3";
        const _tokenPerBlock = 5;
        const _startBlock = 0
      
      
        const MasterFork = await hre.ethers.getContractFactory("MasterFork");
        masterFork = await MasterFork.deploy(testToken.address, _myadress , _tokenPerBlock, _startBlock);
      
        await masterFork.deployed();
      
        console.log("MasterFork deployed to:", masterFork.address);
      
    }

    before("Before", async () => {
        accounts = await ethers.getSigners();

        await deploy();

    })

    it("minting testToken", async () => {
        await testToken.mint(accounts[1].address, ethers.utils.parseEther("1000000"))
        console.log("Balance of account", await testToken.balanceOf(accounts[1].address));
        await testToken.connect(accounts[1]).approve(masterFork.address, await testToken.balanceOf(accounts[1].address))
        
        console.log("allowance given", await testToken.allowance(accounts[1].address, masterFork.address))
    })

    it("minting LpToken", async () => {
        await lpToken.mint(accounts[1].address, ethers.utils.parseEther("10000000"))
        console.log("Balance of account", await lpToken.balanceOf(accounts[1].address));
        await lpToken.connect(accounts[1]).approve(masterFork.address, await lpToken.balanceOf(accounts[1].address))
        
        console.log("allowance given", await lpToken.allowance(accounts[1].address, masterFork.address))
    })

    it("add", async () => {
        await masterFork.add(lpToken.address, 100)
        console.log("lptoken added to the pool", await masterFork.poolInfo(1));
    }) 
    
    it("set", async () => {
        await masterFork.set(1, 200)
        console.log("alloc point set for pid 1", await masterFork.poolInfo(1));
    })

    it("deposit", async () => {
        console.log("Balance of contract Before", await lpToken.balanceOf(masterFork.address));

        await lpToken.connect(accounts[1]).transfer(masterFork.address, ethers.utils.parseEther("100"))
        await masterFork.connect(accounts[1]).deposit(1,ethers.utils.parseEther("100"));
        console.log("lptoken added to the pool", await masterFork.poolInfo(1));


    })

    it("withdraw", async () => {

        await masterFork.connect(accounts[1]).withdraw(1,ethers.utils.parseEther("20"));

        console.log("lptoken withdrawn from the pool", await masterFork.poolInfo(1));

    })

    it("stakingCakeToken to the pool", async () => {
    console.log("Balance of contract Before", await testToken.balanceOf(masterFork.address));

    await testToken.connect(accounts[1]).transfer(masterFork.address, ethers.utils.parseEther("100"))
    await masterFork.connect(accounts[1]).enterStaking(ethers.utils.parseEther("100"));        
    
    console.log("testToken added to staking pool", await masterFork.poolInfo(0));

    })

    it("LeaveStakingCakeToken to the pool", async () => {
        await masterFork.connect(accounts[1]).leaveStaking(ethers.utils.parseEther("20"));

        console.log("testToken removed staking pool", await masterFork.poolInfo(0));
    
        })


})
