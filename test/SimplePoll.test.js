const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const POLL_QUESTION = "Is Solidity fun?";

describe("SimplePoll Contract", function () {

  async function deployPollFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const SimplePoll = await ethers.getContractFactory("SimplePoll");
    const simplePoll = await SimplePoll.deploy(POLL_QUESTION);
    await simplePoll.waitForDeployment();

    return { simplePoll, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should set the correct question upon deployment", async function () {
      const { simplePoll } = await loadFixture(deployPollFixture);
      expect(await simplePoll.question()).to.equal(POLL_QUESTION);
    });

    it("Should initialize vote counts to zero", async function () {
      const { simplePoll } = await loadFixture(deployPollFixture);
      const [yesVotes, noVotes] = await simplePoll.getResults();
      expect(yesVotes).to.equal(0);
      expect(noVotes).to.equal(0);
    });
  });

  describe("Voting", function () {
    it("Should allow a user to vote Yes and increment the count", async function () {
      const { simplePoll, addr1 } = await loadFixture(deployPollFixture);
      await simplePoll.connect(addr1).vote(true);
      const [yesVotes, noVotes] = await simplePoll.getResults();
      expect(yesVotes).to.equal(1);
      expect(noVotes).to.equal(0);
    });

    it("Should allow a user to vote No and increment the count", async function () {
      const { simplePoll, addr1 } = await loadFixture(deployPollFixture);
      await simplePoll.connect(addr1).vote(false);
      const [yesVotes, noVotes] = await simplePoll.getResults();
      expect(yesVotes).to.equal(0);
      expect(noVotes).to.equal(1);
    });

    it("Should prevent a user from voting twice", async function () {
      const { simplePoll, addr1 } = await loadFixture(deployPollFixture);
      await simplePoll.connect(addr1).vote(true);
      await expect(simplePoll.connect(addr1).vote(false)).to.be.revertedWith("You have already voted.");
    });

    it("Should correctly record votes from multiple users", async function () {
      const { simplePoll, owner, addr1, addr2 } = await loadFixture(deployPollFixture);
      await simplePoll.connect(owner).vote(true);
      await simplePoll.connect(addr1).vote(false);
      await simplePoll.connect(addr2).vote(true);

      const [yesVotes, noVotes] = await simplePoll.getResults();
      expect(yesVotes).to.equal(2);
      expect(noVotes).to.equal(1);
    });

    it("Should emit a Voted event", async function () {
      const { simplePoll, addr1 } = await loadFixture(deployPollFixture);
      await expect(simplePoll.connect(addr1).vote(true))
        .to.emit(simplePoll, "Voted")
        .withArgs(addr1.address, true, 1, 0);
    });
  });
});
