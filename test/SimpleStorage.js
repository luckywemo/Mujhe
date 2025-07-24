const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleStorage", function () {
  let simpleStorage;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    const SimpleStorage = await ethers.getContractFactory("SimpleStorage");
    simpleStorage = await SimpleStorage.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await simpleStorage.owner()).to.equal(owner.address);
    });

    it("Should have default favorite number of 42", async function () {
      expect(await simpleStorage.retrieve()).to.equal(42);
    });

    it("Should have default message 'Hello CELO!'", async function () {
      expect(await simpleStorage.getMessage()).to.equal("Hello CELO!");
    });
  });

  describe("Storage Functions", function () {
    it("Should store and retrieve a favorite number", async function () {
      await simpleStorage.store(123);
      expect(await simpleStorage.retrieve()).to.equal(123);
    });

    it("Should store and retrieve a message", async function () {
      const testMessage = "Testing on CELO blockchain!";
      await simpleStorage.setMessage(testMessage);
      expect(await simpleStorage.getMessage()).to.equal(testMessage);
    });

    it("Should emit NumberUpdated event when storing", async function () {
      await expect(simpleStorage.store(456))
        .to.emit(simpleStorage, "NumberUpdated")
        .withArgs(owner.address, 456);
    });

    it("Should emit MessageUpdated event when setting message", async function () {
      const testMessage = "Event test message";
      await expect(simpleStorage.setMessage(testMessage))
        .to.emit(simpleStorage, "MessageUpdated")
        .withArgs(owner.address, testMessage);
    });
  });

  describe("Address-specific Storage", function () {
    it("Should store different numbers for different addresses", async function () {
      await simpleStorage.connect(addr1).store(100);
      await simpleStorage.connect(addr2).store(200);

      expect(await simpleStorage.getFavoriteNumber(addr1.address)).to.equal(100);
      expect(await simpleStorage.getFavoriteNumber(addr2.address)).to.equal(200);
    });

    it("Should store different messages for different addresses", async function () {
      await simpleStorage.connect(addr1).setMessage("Message from addr1");
      await simpleStorage.connect(addr2).setMessage("Message from addr2");

      expect(await simpleStorage.getAddressMessage(addr1.address)).to.equal("Message from addr1");
      expect(await simpleStorage.getAddressMessage(addr2.address)).to.equal("Message from addr2");
    });
  });

  describe("Math Functions", function () {
    it("Should add to favorite number correctly", async function () {
      await simpleStorage.store(10);
      await simpleStorage.addToFavoriteNumber(5);
      expect(await simpleStorage.retrieve()).to.equal(15);
    });
  });

  describe("Owner Functions", function () {
    it("Should allow owner to reset", async function () {
      await simpleStorage.store(999);
      await simpleStorage.setMessage("Changed message");
      
      await simpleStorage.reset();
      
      expect(await simpleStorage.retrieve()).to.equal(42);
      expect(await simpleStorage.getMessage()).to.equal("Hello CELO!");
    });

    it("Should not allow non-owner to reset", async function () {
      await expect(
        simpleStorage.connect(addr1).reset()
      ).to.be.revertedWith("Only owner can reset");
    });
  });
});
