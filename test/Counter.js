const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Counter Contract", function () {
  let Counter;
  let counter;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy Counter contract
    Counter = await ethers.getContractFactory("Counter");
    counter = await Counter.deploy();
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await counter.owner()).to.equal(owner.address);
    });

    it("Should initialize count to 0", async function () {
      expect(await counter.count()).to.equal(0);
    });

    it("Should initialize totalInteractions to 0", async function () {
      expect(await counter.totalInteractions()).to.equal(0);
    });

    it("Should have empty history initially", async function () {
      expect(await counter.getHistoryLength()).to.equal(0);
    });
  });

  describe("Increment Function", function () {
    it("Should increment count by 1", async function () {
      await counter.increment();
      expect(await counter.count()).to.equal(1);
    });

    it("Should track user increments", async function () {
      await counter.connect(user1).increment();
      const [increments] = await counter.getUserStats(user1.address);
      expect(increments).to.equal(1);
    });

    it("Should emit CounterIncremented event", async function () {
      await expect(counter.increment())
        .to.emit(counter, "CounterIncremented")
        .withArgs(owner.address, 0, 1, await time.latest() + 1);
    });

    it("Should record change in history", async function () {
      await counter.increment();
      expect(await counter.getHistoryLength()).to.equal(1);
      
      const change = await counter.history(0);
      expect(change.user).to.equal(owner.address);
      expect(change.previousCount).to.equal(0);
      expect(change.newCount).to.equal(1);
      expect(change.action).to.equal("increment");
    });

    it("Should handle multiple increments", async function () {
      await counter.increment();
      await counter.increment();
      await counter.increment();
      
      expect(await counter.count()).to.equal(3);
      expect(await counter.totalInteractions()).to.equal(3);
    });
  });

  describe("Decrement Function", function () {
    it("Should decrement count by 1", async function () {
      await counter.decrement();
      expect(await counter.count()).to.equal(-1);
    });

    it("Should track user decrements", async function () {
      await counter.connect(user1).decrement();
      const [, decrements] = await counter.getUserStats(user1.address);
      expect(decrements).to.equal(1);
    });

    it("Should emit CounterDecremented event", async function () {
      await expect(counter.decrement())
        .to.emit(counter, "CounterDecremented")
        .withArgs(owner.address, 0, -1, await time.latest() + 1);
    });

    it("Should handle negative numbers", async function () {
      await counter.decrement();
      await counter.decrement();
      await counter.decrement();
      
      expect(await counter.count()).to.equal(-3);
    });
  });

  describe("Custom Amount Functions", function () {
    it("Should increment by custom amount", async function () {
      await counter.incrementBy(5);
      expect(await counter.count()).to.equal(5);
    });

    it("Should decrement by custom amount", async function () {
      await counter.decrementBy(3);
      expect(await counter.count()).to.equal(-3);
    });

    it("Should reject zero amount", async function () {
      await expect(counter.incrementBy(0))
        .to.be.revertedWith("Amount must be greater than 0");
    });

    it("Should reject amount greater than 100", async function () {
      await expect(counter.incrementBy(101))
        .to.be.revertedWith("Amount too large (max 100)");
    });

    it("Should track custom increments correctly", async function () {
      await counter.connect(user1).incrementBy(10);
      const [increments] = await counter.getUserStats(user1.address);
      expect(increments).to.equal(10);
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await counter.increment();
      await counter.connect(user1).decrement();
      await counter.connect(user2).incrementBy(5);
    });

    it("Should return correct count", async function () {
      expect(await counter.getCount()).to.equal(5); // 1 - 1 + 5 = 5
    });

    it("Should return correct history length", async function () {
      expect(await counter.getHistoryLength()).to.equal(3);
    });

    it("Should return latest changes", async function () {
      const [users, previousCounts, newCounts, actions, timestamps] = 
        await counter.getLatestChanges(2);
      
      expect(users.length).to.equal(2);
      expect(users[0]).to.equal(user2.address); // Most recent
      expect(actions[0]).to.include("increment_by_5");
    });

    it("Should return user statistics", async function () {
      const [increments, decrements, totalInteractions, netContribution] = 
        await counter.getUserStats(user1.address);
      
      expect(increments).to.equal(0);
      expect(decrements).to.equal(1);
      expect(totalInteractions).to.equal(1);
      expect(netContribution).to.equal(-1);
    });

    it("Should return contract statistics", async function () {
      const [currentCount, totalChanges, totalUsers, contractOwner] = 
        await counter.getContractStats();
      
      expect(currentCount).to.equal(5);
      expect(totalChanges).to.equal(3);
      expect(contractOwner).to.equal(owner.address);
    });

    it("Should return correct count status", async function () {
      expect(await counter.getCountStatus()).to.equal("positive");
      
      // Test zero
      await counter.reset();
      expect(await counter.getCountStatus()).to.equal("zero");
      
      // Test negative
      await counter.decrement();
      expect(await counter.getCountStatus()).to.equal("negative");
    });

    it("Should return last user info", async function () {
      const [lastUser, lastAction, timestamp] = await counter.getLastUser();
      expect(lastUser).to.equal(user2.address);
      expect(lastAction).to.include("increment_by_5");
    });
  });

  describe("Reset Function", function () {
    beforeEach(async function () {
      await counter.increment();
      await counter.increment();
    });

    it("Should reset count to 0", async function () {
      await counter.reset();
      expect(await counter.count()).to.equal(0);
    });

    it("Should only allow owner to reset", async function () {
      await expect(counter.connect(user1).reset())
        .to.be.revertedWith("Only owner can call this function");
    });

    it("Should emit CounterReset event", async function () {
      await expect(counter.reset())
        .to.emit(counter, "CounterReset")
        .withArgs(owner.address, 2, await time.latest() + 1);
    });

    it("Should record reset in history", async function () {
      await counter.reset();
      const historyLength = await counter.getHistoryLength();
      const lastChange = await counter.history(historyLength - 1);
      
      expect(lastChange.action).to.equal("reset");
      expect(lastChange.newCount).to.equal(0);
    });
  });

  describe("Ownership Functions", function () {
    it("Should transfer ownership", async function () {
      await counter.transferOwnership(user1.address);
      expect(await counter.owner()).to.equal(user1.address);
    });

    it("Should only allow owner to transfer ownership", async function () {
      await expect(counter.connect(user1).transferOwnership(user2.address))
        .to.be.revertedWith("Only owner can call this function");
    });

    it("Should reject zero address as new owner", async function () {
      await expect(counter.transferOwnership(ethers.ZeroAddress))
        .to.be.revertedWith("New owner cannot be zero address");
    });
  });

  describe("Milestone Events", function () {
    it("Should emit milestone at 10", async function () {
      // Increment to 10
      for (let i = 0; i < 10; i++) {
        await counter.increment();
      }
      
      // Check if milestone event was emitted (would need to check events in the last transaction)
      const events = await counter.queryFilter("MilestoneReached");
      expect(events.length).to.be.greaterThan(0);
    });

    it("Should emit milestone at -10", async function () {
      // Decrement to -10
      for (let i = 0; i < 10; i++) {
        await counter.decrement();
      }
      
      const events = await counter.queryFilter("MilestoneReached");
      expect(events.length).to.be.greaterThan(0);
    });
  });

  describe("Multiple Users Interaction", function () {
    it("Should handle multiple users correctly", async function () {
      await counter.connect(user1).increment();
      await counter.connect(user2).incrementBy(3);
      await counter.connect(user1).decrement();
      
      expect(await counter.count()).to.equal(3); // 1 + 3 - 1 = 3
      
      const [inc1, dec1, total1] = await counter.getUserStats(user1.address);
      expect(inc1).to.equal(1);
      expect(dec1).to.equal(1);
      expect(total1).to.equal(2);
      
      const [inc2, dec2, total2] = await counter.getUserStats(user2.address);
      expect(inc2).to.equal(3);
      expect(dec2).to.equal(0);
      expect(total2).to.equal(1);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle large positive numbers", async function () {
      for (let i = 0; i < 50; i++) {
        await counter.incrementBy(100);
      }
      expect(await counter.count()).to.equal(5000);
    });

    it("Should handle large negative numbers", async function () {
      for (let i = 0; i < 50; i++) {
        await counter.decrementBy(100);
      }
      expect(await counter.count()).to.equal(-5000);
    });

    it("Should revert when getting last user with no history", async function () {
      const freshCounter = await Counter.deploy();
      await expect(freshCounter.getLastUser())
        .to.be.revertedWith("No changes made yet");
    });
  });
});

// Helper to get latest block timestamp
const time = {
  latest: async () => {
    const block = await ethers.provider.getBlock("latest");
    return block.timestamp;
  }
};
