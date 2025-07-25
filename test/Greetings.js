const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greetings", function () {
  let greetings;
  let owner;
  let addr1;
  let addr2;
  let addr3;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
    const Greetings = await ethers.getContractFactory("Greetings");
    greetings = await Greetings.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await greetings.owner()).to.equal(owner.address);
    });

    it("Should have default greeting", async function () {
      expect(await greetings.defaultGreeting()).to.equal("Hello from CELO blockchain! 🌟");
    });

    it("Should start with zero total greetings", async function () {
      expect(await greetings.totalGreetings()).to.equal(0);
    });
  });

  describe("Setting Greetings", function () {
    it("Should allow users to set personal greetings", async function () {
      const greeting = "Hello from Alice!";
      await greetings.connect(addr1).setGreeting(greeting);
      
      expect(await greetings.getGreeting(addr1.address)).to.equal(greeting);
      expect(await greetings.hasSetGreeting(addr1.address)).to.be.true;
      expect(await greetings.totalGreetings()).to.equal(1);
    });

    it("Should emit GreetingSet event for new greetings", async function () {
      const greeting = "Hello World!";
      await expect(greetings.connect(addr1).setGreeting(greeting))
        .to.emit(greetings, "GreetingSet")
        .withArgs(addr1.address, greeting, await ethers.provider.getBlock('latest').then(b => b.timestamp + 1));
    });

    it("Should emit GreetingUpdated event for updated greetings", async function () {
      const firstGreeting = "Hello!";
      const secondGreeting = "Updated Hello!";
      
      await greetings.connect(addr1).setGreeting(firstGreeting);
      
      await expect(greetings.connect(addr1).setGreeting(secondGreeting))
        .to.emit(greetings, "GreetingUpdated")
        .withArgs(addr1.address, firstGreeting, secondGreeting, await ethers.provider.getBlock('latest').then(b => b.timestamp + 1));
    });

    it("Should not allow empty greetings", async function () {
      await expect(greetings.connect(addr1).setGreeting(""))
        .to.be.revertedWith("Greeting cannot be empty");
    });

    it("Should not allow greetings longer than 280 characters", async function () {
      const longGreeting = "a".repeat(281);
      await expect(greetings.connect(addr1).setGreeting(longGreeting))
        .to.be.revertedWith("Greeting too long (max 280 characters)");
    });

    it("Should allow exactly 280 character greetings", async function () {
      const maxGreeting = "a".repeat(280);
      await greetings.connect(addr1).setGreeting(maxGreeting);
      expect(await greetings.getGreeting(addr1.address)).to.equal(maxGreeting);
    });
  });

  describe("Getting Greetings", function () {
    it("Should return default greeting for users who haven't set one", async function () {
      const defaultGreeting = await greetings.defaultGreeting();
      expect(await greetings.getGreeting(addr1.address)).to.equal(defaultGreeting);
    });

    it("Should return personal greeting for users who have set one", async function () {
      const personalGreeting = "My personal greeting!";
      await greetings.connect(addr1).setGreeting(personalGreeting);
      expect(await greetings.getGreeting(addr1.address)).to.equal(personalGreeting);
    });

    it("Should allow users to get their own greeting", async function () {
      const personalGreeting = "My greeting!";
      await greetings.connect(addr1).setGreeting(personalGreeting);
      expect(await greetings.connect(addr1).getMyGreeting()).to.equal(personalGreeting);
    });
  });

  describe("Greeters Management", function () {
    it("Should track all greeters", async function () {
      await greetings.connect(addr1).setGreeting("Hello from addr1");
      await greetings.connect(addr2).setGreeting("Hello from addr2");
      
      const greeters = await greetings.getAllGreeters();
      expect(greeters).to.include(addr1.address);
      expect(greeters).to.include(addr2.address);
      expect(greeters.length).to.equal(2);
    });

    it("Should not duplicate greeters when updating greetings", async function () {
      await greetings.connect(addr1).setGreeting("First greeting");
      await greetings.connect(addr1).setGreeting("Updated greeting");
      
      const greeters = await greetings.getAllGreeters();
      expect(greeters.length).to.equal(1);
      expect(greeters[0]).to.equal(addr1.address);
    });
  });

  describe("Latest Greetings", function () {
    beforeEach(async function () {
      await greetings.connect(addr1).setGreeting("First greeting");
      await greetings.connect(addr2).setGreeting("Second greeting");
      await greetings.connect(addr3).setGreeting("Third greeting");
    });

    it("Should return latest greetings in reverse order", async function () {
      const [addresses, greetingTexts] = await greetings.getLatestGreetings(2);
      
      expect(addresses[0]).to.equal(addr3.address);
      expect(addresses[1]).to.equal(addr2.address);
      expect(greetingTexts[0]).to.equal("Third greeting");
      expect(greetingTexts[1]).to.equal("Second greeting");
    });

    it("Should handle requests for more greetings than available", async function () {
      const [addresses, greetingTexts] = await greetings.getLatestGreetings(10);
      
      expect(addresses.length).to.equal(3);
      expect(greetingTexts.length).to.equal(3);
    });
  });

  describe("Greeting Statistics", function () {
    it("Should track greeting update counts", async function () {
      await greetings.connect(addr1).setGreeting("First");
      await greetings.connect(addr1).setGreeting("Second");
      await greetings.connect(addr1).setGreeting("Third");
      
      const [hasSet, updateCount, currentGreeting] = await greetings.getGreetingStats(addr1.address);
      
      expect(hasSet).to.be.true;
      expect(updateCount).to.equal(3);
      expect(currentGreeting).to.equal("Third");
    });

    it("Should return correct stats for users without greetings", async function () {
      const [hasSet, updateCount, currentGreeting] = await greetings.getGreetingStats(addr1.address);
      
      expect(hasSet).to.be.false;
      expect(updateCount).to.equal(0);
      expect(currentGreeting).to.equal(await greetings.defaultGreeting());
    });
  });

  describe("Contract Statistics", function () {
    it("Should return correct contract statistics", async function () {
      await greetings.connect(addr1).setGreeting("First");
      await greetings.connect(addr1).setGreeting("Updated");
      await greetings.connect(addr2).setGreeting("Second");
      
      const [totalUsers, totalUpdates, currentDefault, contractOwner] = await greetings.getContractStats();
      
      expect(totalUsers).to.equal(2);
      expect(totalUpdates).to.equal(3);
      expect(currentDefault).to.equal("Hello from CELO blockchain! 🌟");
      expect(contractOwner).to.equal(owner.address);
    });
  });

  describe("Random Greeting", function () {
    it("Should return a random greeting when greetings exist", async function () {
      await greetings.connect(addr1).setGreeting("Greeting 1");
      await greetings.connect(addr2).setGreeting("Greeting 2");
      
      const [greeter, greeting] = await greetings.getRandomGreeting();
      
      expect([addr1.address, addr2.address]).to.include(greeter);
      expect(["Greeting 1", "Greeting 2"]).to.include(greeting);
    });

    it("Should revert when no greetings are available", async function () {
      await expect(greetings.getRandomGreeting())
        .to.be.revertedWith("No greetings available");
    });
  });

  describe("Owner Functions", function () {
    it("Should allow owner to change default greeting", async function () {
      const newDefault = "New default greeting!";
      await greetings.setDefaultGreeting(newDefault);
      
      expect(await greetings.defaultGreeting()).to.equal(newDefault);
    });

    it("Should emit event when default greeting changes", async function () {
      const oldDefault = await greetings.defaultGreeting();
      const newDefault = "New default!";
      
      await expect(greetings.setDefaultGreeting(newDefault))
        .to.emit(greetings, "DefaultGreetingChanged")
        .withArgs(oldDefault, newDefault, await ethers.provider.getBlock('latest').then(b => b.timestamp + 1));
    });

    it("Should not allow non-owner to change default greeting", async function () {
      await expect(greetings.connect(addr1).setDefaultGreeting("Unauthorized change"))
        .to.be.revertedWith("Only owner can call this function");
    });

    it("Should not allow empty default greeting", async function () {
      await expect(greetings.setDefaultGreeting(""))
        .to.be.revertedWith("Default greeting cannot be empty");
    });

    it("Should allow owner to transfer ownership", async function () {
      await greetings.transferOwnership(addr1.address);
      expect(await greetings.owner()).to.equal(addr1.address);
    });

    it("Should not allow non-owner to transfer ownership", async function () {
      await expect(greetings.connect(addr1).transferOwnership(addr2.address))
        .to.be.revertedWith("Only owner can call this function");
    });

    it("Should not allow transfer to zero address", async function () {
      await expect(greetings.transferOwnership(ethers.ZeroAddress))
        .to.be.revertedWith("New owner cannot be zero address");
    });
  });
});
