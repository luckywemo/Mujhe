const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleToken", function () {
  let simpleToken;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    const SimpleToken = await ethers.getContractFactory("SimpleToken");
    simpleToken = await SimpleToken.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await simpleToken.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await simpleToken.balanceOf(owner.address);
      expect(await simpleToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Should have correct name and symbol", async function () {
      expect(await simpleToken.name()).to.equal("SimpleToken");
      expect(await simpleToken.symbol()).to.equal("STK");
    });

    it("Should have 18 decimals", async function () {
      expect(await simpleToken.decimals()).to.equal(18);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      await simpleToken.transfer(addr1.address, 50);
      const addr1Balance = await simpleToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(50);

      await simpleToken.connect(addr1).transfer(addr2.address, 50);
      const addr2Balance = await simpleToken.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await simpleToken.balanceOf(owner.address);
      await expect(
        simpleToken.connect(addr1).transfer(owner.address, 1)
      ).to.be.reverted;

      expect(await simpleToken.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint tokens", async function () {
      const initialSupply = await simpleToken.totalSupply();
      await simpleToken.mint(addr1.address, 1000);
      
      expect(await simpleToken.balanceOf(addr1.address)).to.equal(1000);
      expect(await simpleToken.totalSupply()).to.equal(initialSupply + 1000n);
    });

    it("Should not allow non-owner to mint tokens", async function () {
      await expect(
        simpleToken.connect(addr1).mint(addr2.address, 1000)
      ).to.be.reverted;
    });
  });

  describe("Burning", function () {
    it("Should allow users to burn their tokens", async function () {
      await simpleToken.transfer(addr1.address, 1000);
      const initialBalance = await simpleToken.balanceOf(addr1.address);
      const initialSupply = await simpleToken.totalSupply();
      
      await simpleToken.connect(addr1).burn(500);
      
      expect(await simpleToken.balanceOf(addr1.address)).to.equal(initialBalance - 500n);
      expect(await simpleToken.totalSupply()).to.equal(initialSupply - 500n);
    });
  });
});
