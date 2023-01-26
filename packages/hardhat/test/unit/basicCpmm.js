const { ethers, utils } = require("hardhat");
const { expect } = require("chai");
const init = require('../test-init.js');

let tokenA;
let tokenB;
let marketMaker;
let testAmount = ethers.utils.parseEther("200");
let swapAmount = ethers.utils.parseEther("10");
let differenceAmount = ethers.utils.parseEther("1");

describe("Basic Constant Product Market Maker", function () {

  const setupTests = deployments.createFixture(async () => {
    const signers = await ethers.getSigners();
    const setup = await init.initialize(signers);

    root = setup.roles.root;
    user1 = setup.roles.user1;
    user2 = setup.roles.user2;

    tokenA = await init.token(setup, "Test Token A", "A");
    tokenB = await init.token(setup, "Test Token B", "B");

    marketMaker = await init.basicCpmm();

    await tokenA.approve(marketMaker.address, testAmount);
    await tokenB.approve(marketMaker.address, testAmount);

    await marketMaker.init(tokenA.address, testAmount, tokenB.address, testAmount);

  });

  /// Clean context before each test
  beforeEach("Setup", async () => {
    await setupTests();
  });

  describe("BasicCPMM Contract", function () {

    describe("swapAtoB()", function () {
      it("Should allow a user to swap from A to B", async function () {
        await tokenA.mint(user1.address, testAmount);
        await tokenA.connect(user1).approve(marketMaker.address, swapAmount);

        await marketMaker.connect(user1).swapAtoB(swapAmount);
        expect(await tokenB.balanceOf(user1.address)).to.be.approximately(swapAmount, differenceAmount);
      });
    });

    describe("swapBtoA()", function () {
      it("Should allow a user to swap from B to A", async function () {
        await tokenB.mint(user1.address, testAmount);
        await tokenB.connect(user1).approve(marketMaker.address, swapAmount);

        await marketMaker.connect(user1).swapBtoA(swapAmount);
        expect(await tokenA.balanceOf(user1.address)).to.be.approximately(swapAmount, differenceAmount);
      });
    });

    describe("deposit()", function () {
      it("Should allow a user to add liquidity to the LP", async function () {
        await tokenA.mint(user1.address, testAmount);
        await tokenB.mint(user1.address, testAmount);
        await tokenA.connect(user1).approve(marketMaker.address, swapAmount);
        await tokenB.connect(user1).approve(marketMaker.address, swapAmount);

        await marketMaker.connect(user1).deposit(swapAmount);
      });
    });

    describe("withdraw()", function () {
      it("Should allow a user to withdraw liquidity from the LP", async function () {
        await tokenA.mint(user1.address, swapAmount);
        await tokenB.mint(user1.address, swapAmount);
        await tokenA.connect(user1).approve(marketMaker.address, swapAmount);
        await tokenB.connect(user1).approve(marketMaker.address, swapAmount);

        await marketMaker.connect(user1).deposit(swapAmount);
        let liquidity = await marketMaker.viewProvidedLiquidity(user1.address);

        await tokenA.mint(user2.address, testAmount);
        await tokenB.mint(user2.address, testAmount);
        await tokenA.connect(user2).approve(marketMaker.address, swapAmount);
        await tokenB.connect(user2).approve(marketMaker.address, swapAmount);

        await marketMaker.connect(user2).swapAtoB(swapAmount);
        await marketMaker.connect(user2).swapBtoA(swapAmount);

        await marketMaker.connect(user1).withdraw(liquidity);

        expect(await tokenB.balanceOf(user1.address)).to.be.gt(swapAmount);
        expect(await tokenA.balanceOf(user1.address)).to.be.gt(swapAmount);
      });
    });

  });
});
