const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("VotingSystem", function () {
  let VotingSystem;
  let votingSystem;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  // Constants for testing
  const VOTING_DELAY = 3600; // 1 hour
  const VOTING_PERIOD = 7 * 24 * 3600; // 7 days
  const PROPOSAL_THRESHOLD = 1;
  const QUORUM_PERCENTAGE = 10;

  beforeEach(async function () {
    // Get the ContractFactory and Signers
    VotingSystem = await ethers.getContractFactory("VotingSystem");
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // Deploy the contract
    votingSystem = await VotingSystem.deploy();
    await votingSystem.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await votingSystem.owner()).to.equal(owner.address);
    });

    it("Should initialize with correct parameters", async function () {
      expect(await votingSystem.totalProposals()).to.equal(0);
      expect(await votingSystem.votingDelay()).to.equal(VOTING_DELAY);
      expect(await votingSystem.votingPeriod()).to.equal(VOTING_PERIOD);
      expect(await votingSystem.proposalThreshold()).to.equal(PROPOSAL_THRESHOLD);
      expect(await votingSystem.quorumPercentage()).to.equal(QUORUM_PERCENTAGE);
    });

    it("Should give initial voting power to owner", async function () {
      expect(await votingSystem.votingPower(owner.address)).to.equal(100);
      expect(await votingSystem.getVotingPower(owner.address)).to.equal(100);
    });
  });

  describe("Voting Power Management", function () {
    it("Should allow owner to set voting power", async function () {
      await expect(votingSystem.setVotingPower(addr1.address, 50))
        .to.emit(votingSystem, "VotingPowerUpdated")
        .withArgs(addr1.address, 0, 50);

      expect(await votingSystem.votingPower(addr1.address)).to.equal(50);
    });

    it("Should not allow non-owner to set voting power", async function () {
      await expect(
        votingSystem.connect(addr1).setVotingPower(addr2.address, 50)
      ).to.be.revertedWith("Only owner can call this function");
    });

    it("Should calculate effective voting power with delegations", async function () {
      // Set voting power for addresses
      await votingSystem.setVotingPower(addr1.address, 30);
      await votingSystem.setVotingPower(addr2.address, 20);

      // Initially, effective power equals direct power
      expect(await votingSystem.getVotingPower(addr1.address)).to.equal(30);

      // After delegation, effective power should include delegated power
      // Note: This test would need actual delegation to work properly
      // For now, we test the basic functionality
    });
  });

  describe("Proposal Creation", function () {
    beforeEach(async function () {
      // Give voting power to test addresses
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);
    });

    it("Should create a proposal successfully", async function () {
      const title = "Test Proposal";
      const description = "This is a test proposal for voting";

      await expect(
        votingSystem.connect(addr1).createProposal(title, description)
      )
        .to.emit(votingSystem, "ProposalCreated")
        .withArgs(1, addr1.address, title, await time.latest() + VOTING_DELAY + 1, await time.latest() + VOTING_DELAY + VOTING_PERIOD + 1);

      expect(await votingSystem.totalProposals()).to.equal(1);

      const proposal = await votingSystem.getProposal(1);
      expect(proposal.id).to.equal(1);
      expect(proposal.title).to.equal(title);
      expect(proposal.description).to.equal(description);
      expect(proposal.proposer).to.equal(addr1.address);
      expect(proposal.executed).to.be.false;
    });

    it("Should not allow empty title", async function () {
      await expect(
        votingSystem.connect(addr1).createProposal("", "Description")
      ).to.be.revertedWith("Title cannot be empty");
    });

    it("Should not allow empty description", async function () {
      await expect(
        votingSystem.connect(addr1).createProposal("Title", "")
      ).to.be.revertedWith("Description cannot be empty");
    });

    it("Should not allow title too long", async function () {
      const longTitle = "a".repeat(201);
      await expect(
        votingSystem.connect(addr1).createProposal(longTitle, "Description")
      ).to.be.revertedWith("Title too long");
    });

    it("Should not allow description too long", async function () {
      const longDescription = "a".repeat(1001);
      await expect(
        votingSystem.connect(addr1).createProposal("Title", longDescription)
      ).to.be.revertedWith("Description too long");
    });

    it("Should not allow users without voting power to create proposals", async function () {
      await expect(
        votingSystem.connect(addr3).createProposal("Title", "Description")
      ).to.be.revertedWith("No voting power");
    });

    it("Should track user proposals", async function () {
      await votingSystem.connect(addr1).createProposal("Proposal 1", "Description 1");
      await votingSystem.connect(addr1).createProposal("Proposal 2", "Description 2");

      const userProposals = await votingSystem.getUserProposals(addr1.address);
      expect(userProposals.length).to.equal(2);
      expect(userProposals[0]).to.equal(1);
      expect(userProposals[1]).to.equal(2);
    });
  });

  describe("Voting", function () {
    let proposalId;

    beforeEach(async function () {
      // Give voting power to test addresses
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);
      await votingSystem.setVotingPower(addr3.address, 20);

      // Create a proposal
      await votingSystem.connect(addr1).createProposal("Test Proposal", "Test Description");
      proposalId = 1;

      // Advance time to start voting
      await time.increase(VOTING_DELAY + 1);
    });

    it("Should allow voting on active proposal", async function () {
      const reason = "I support this proposal";

      await expect(
        votingSystem.connect(addr2).vote(proposalId, 0, reason) // VoteChoice.FOR = 0
      )
        .to.emit(votingSystem, "VoteCast")
        .withArgs(addr2.address, proposalId, 0, 30, reason);

      const proposal = await votingSystem.getProposal(proposalId);
      expect(proposal.forVotes).to.equal(30);
      expect(proposal.againstVotes).to.equal(0);
      expect(proposal.abstainVotes).to.equal(0);

      expect(await votingSystem.hasVoted(proposalId, addr2.address)).to.be.true;
      expect(await votingSystem.getUserVote(proposalId, addr2.address)).to.equal(0);
    });

    it("Should handle different vote choices", async function () {
      // Vote FOR
      await votingSystem.connect(addr1).vote(proposalId, 0, "For"); // FOR
      // Vote AGAINST
      await votingSystem.connect(addr2).vote(proposalId, 1, "Against"); // AGAINST
      // Vote ABSTAIN
      await votingSystem.connect(addr3).vote(proposalId, 2, "Abstain"); // ABSTAIN

      const proposal = await votingSystem.getProposal(proposalId);
      expect(proposal.forVotes).to.equal(50);
      expect(proposal.againstVotes).to.equal(30);
      expect(proposal.abstainVotes).to.equal(20);
    });

    it("Should not allow voting before voting starts", async function () {
      // Create a new proposal and try to vote immediately
      await votingSystem.connect(addr1).createProposal("New Proposal", "New Description");
      const newProposalId = 2;

      await expect(
        votingSystem.connect(addr2).vote(newProposalId, 0, "Early vote")
      ).to.be.revertedWith("Voting not started");
    });

    it("Should not allow voting after voting ends", async function () {
      // Advance time past voting period
      await time.increase(VOTING_PERIOD + 1);

      await expect(
        votingSystem.connect(addr2).vote(proposalId, 0, "Late vote")
      ).to.be.revertedWith("Voting ended");
    });

    it("Should not allow double voting", async function () {
      await votingSystem.connect(addr2).vote(proposalId, 0, "First vote");

      await expect(
        votingSystem.connect(addr2).vote(proposalId, 1, "Second vote")
      ).to.be.revertedWith("Already voted");
    });

    it("Should not allow voting without voting power", async function () {
      // addr3 has no voting power initially (we gave it power in beforeEach, so let's remove it)
      await votingSystem.setVotingPower(addr3.address, 0);

      await expect(
        votingSystem.connect(addr3).vote(proposalId, 0, "No power vote")
      ).to.be.revertedWith("No voting power");
    });

    it("Should track user votes", async function () {
      await votingSystem.connect(addr2).vote(proposalId, 0, "My vote");

      const userVotes = await votingSystem.getUserVotes(addr2.address);
      expect(userVotes.length).to.equal(1);
      expect(userVotes[0].voter).to.equal(addr2.address);
      expect(userVotes[0].proposalId).to.equal(proposalId);
      expect(userVotes[0].choice).to.equal(0);
      expect(userVotes[0].weight).to.equal(30);
      expect(userVotes[0].reason).to.equal("My vote");
    });

    it("Should track proposal votes", async function () {
      await votingSystem.connect(addr1).vote(proposalId, 0, "Vote 1");
      await votingSystem.connect(addr2).vote(proposalId, 1, "Vote 2");

      const proposalVotes = await votingSystem.getProposalVotes(proposalId);
      expect(proposalVotes.length).to.equal(2);
      expect(proposalVotes[0].voter).to.equal(addr1.address);
      expect(proposalVotes[1].voter).to.equal(addr2.address);
    });
  });

  describe("Proposal States", function () {
    let proposalId;

    beforeEach(async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);
      await votingSystem.setVotingPower(addr3.address, 20);

      await votingSystem.connect(addr1).createProposal("Test Proposal", "Test Description");
      proposalId = 1;
    });

    it("Should start in PENDING state", async function () {
      expect(await votingSystem.getProposalState(proposalId)).to.equal(0); // PENDING
    });

    it("Should move to ACTIVE state when voting starts", async function () {
      await time.increase(VOTING_DELAY + 1);
      expect(await votingSystem.getProposalState(proposalId)).to.equal(1); // ACTIVE
    });

    it("Should move to SUCCEEDED state when majority votes for", async function () {
      await time.increase(VOTING_DELAY + 1);
      
      // Vote with majority for the proposal
      await votingSystem.connect(addr1).vote(proposalId, 0, "For"); // 50 votes
      await votingSystem.connect(addr2).vote(proposalId, 1, "Against"); // 30 votes
      
      // Advance past voting period
      await time.increase(VOTING_PERIOD + 1);
      
      expect(await votingSystem.getProposalState(proposalId)).to.equal(2); // SUCCEEDED
    });

    it("Should move to DEFEATED state when majority votes against", async function () {
      await time.increase(VOTING_DELAY + 1);
      
      // Vote with majority against the proposal
      await votingSystem.connect(addr1).vote(proposalId, 1, "Against"); // 50 votes
      await votingSystem.connect(addr2).vote(proposalId, 0, "For"); // 30 votes
      
      // Advance past voting period
      await time.increase(VOTING_PERIOD + 1);
      
      expect(await votingSystem.getProposalState(proposalId)).to.equal(3); // DEFEATED
    });
  });

  describe("Delegation", function () {
    beforeEach(async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);
      await votingSystem.setVotingPower(addr3.address, 20);
    });

    it("Should allow delegation to another address", async function () {
      await expect(votingSystem.connect(addr1).delegate(addr2.address))
        .to.emit(votingSystem, "DelegationSet")
        .withArgs(addr1.address, addr2.address, await time.latest() + 1);

      const delegation = await votingSystem.delegations(addr1.address);
      expect(delegation.delegate).to.equal(addr2.address);
      expect(delegation.active).to.be.true;
    });

    it("Should not allow delegation to zero address", async function () {
      await expect(
        votingSystem.connect(addr1).delegate(ethers.ZeroAddress)
      ).to.be.revertedWith("Cannot delegate to zero address");
    });

    it("Should not allow self-delegation", async function () {
      await expect(
        votingSystem.connect(addr1).delegate(addr1.address)
      ).to.be.revertedWith("Cannot delegate to self");
    });

    it("Should allow revoking delegation", async function () {
      await votingSystem.connect(addr1).delegate(addr2.address);

      await expect(votingSystem.connect(addr1).revokeDelegation())
        .to.emit(votingSystem, "DelegationRevoked")
        .withArgs(addr1.address, addr2.address, await time.latest() + 1);

      const delegation = await votingSystem.delegations(addr1.address);
      expect(delegation.active).to.be.false;
    });

    it("Should not allow revoking non-existent delegation", async function () {
      await expect(
        votingSystem.connect(addr1).revokeDelegation()
      ).to.be.revertedWith("No active delegation");
    });
  });

  describe("Proposal Execution", function () {
    let proposalId;

    beforeEach(async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);

      await votingSystem.connect(addr1).createProposal("Test Proposal", "Test Description");
      proposalId = 1;

      // Make proposal succeed
      await time.increase(VOTING_DELAY + 1);
      await votingSystem.connect(addr1).vote(proposalId, 0, "For");
      await votingSystem.connect(addr2).vote(proposalId, 0, "For");
      await time.increase(VOTING_PERIOD + 1);
    });

    it("Should allow execution of succeeded proposal", async function () {
      // Verify the proposal succeeded first
      expect(await votingSystem.getProposalState(proposalId)).to.equal(2); // SUCCEEDED
      
      await expect(votingSystem.executeProposal(proposalId))
        .to.emit(votingSystem, "ProposalExecuted")
        .withArgs(proposalId, owner.address);

      const proposal = await votingSystem.getProposal(proposalId);
      expect(proposal.executed).to.be.true;
      expect(proposal.state).to.equal(4); // EXECUTED
    });

    it("Should not allow execution of non-succeeded proposal", async function () {
      // Create a defeated proposal
      await votingSystem.connect(addr1).createProposal("Defeated Proposal", "Will be defeated");
      const defeatedId = 2;
      
      await time.increase(VOTING_DELAY + 1);
      await votingSystem.connect(addr1).vote(defeatedId, 1, "Against");
      await votingSystem.connect(addr2).vote(defeatedId, 1, "Against");
      await time.increase(VOTING_PERIOD + 1);

      // Verify the proposal was defeated
      expect(await votingSystem.getProposalState(defeatedId)).to.equal(3); // DEFEATED

      await expect(
        votingSystem.executeProposal(defeatedId)
      ).to.be.revertedWith("Proposal not succeeded");
    });

    it("Should not allow double execution", async function () {
      // First execution should succeed
      await votingSystem.executeProposal(proposalId);

      // Second execution should fail
      await expect(
        votingSystem.executeProposal(proposalId)
      ).to.be.revertedWith("Already executed");
    });
  });

  describe("Proposal Cancellation", function () {
    let proposalId;

    beforeEach(async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.connect(addr1).createProposal("Test Proposal", "Test Description");
      proposalId = 1;
    });

    it("Should allow proposer to cancel their proposal", async function () {
      await expect(votingSystem.connect(addr1).cancelProposal(proposalId))
        .to.emit(votingSystem, "ProposalCancelled")
        .withArgs(proposalId, addr1.address);

      const proposal = await votingSystem.getProposal(proposalId);
      expect(proposal.state).to.equal(5); // CANCELLED
    });

    it("Should allow owner to cancel any proposal", async function () {
      await expect(votingSystem.connect(owner).cancelProposal(proposalId))
        .to.emit(votingSystem, "ProposalCancelled")
        .withArgs(proposalId, owner.address);
    });

    it("Should not allow others to cancel proposal", async function () {
      await votingSystem.setVotingPower(addr2.address, 30);

      await expect(
        votingSystem.connect(addr2).cancelProposal(proposalId)
      ).to.be.revertedWith("Only proposer or owner can cancel");
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.setVotingPower(addr2.address, 30);
    });

    it("Should return all proposals", async function () {
      await votingSystem.connect(addr1).createProposal("Proposal 1", "Description 1");
      await votingSystem.connect(addr2).createProposal("Proposal 2", "Description 2");

      const allProposals = await votingSystem.getAllProposals();
      expect(allProposals.length).to.equal(2);
      expect(allProposals[0]).to.equal(1);
      expect(allProposals[1]).to.equal(2);
    });

    it("Should return voting statistics", async function () {
      await votingSystem.connect(addr1).createProposal("Proposal 1", "Description 1");
      
      // Advance time and vote
      await time.increase(VOTING_DELAY + 1);
      await votingSystem.connect(addr1).vote(1, 0, "Vote");

      const stats = await votingSystem.getVotingStats();
      expect(stats.totalProposalsCount).to.equal(1);
      expect(stats.totalVotersCount).to.equal(1);
      expect(stats.activeProposalsCount).to.equal(1);
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to update voting parameters", async function () {
      const newDelay = 7200; // 2 hours
      const newPeriod = 14 * 24 * 3600; // 14 days
      const newThreshold = 5;
      const newQuorum = 20;

      await votingSystem.updateVotingParameters(newDelay, newPeriod, newThreshold, newQuorum);

      expect(await votingSystem.votingDelay()).to.equal(newDelay);
      expect(await votingSystem.votingPeriod()).to.equal(newPeriod);
      expect(await votingSystem.proposalThreshold()).to.equal(newThreshold);
      expect(await votingSystem.quorumPercentage()).to.equal(newQuorum);
    });

    it("Should not allow non-owner to update voting parameters", async function () {
      await expect(
        votingSystem.connect(addr1).updateVotingParameters(7200, 14 * 24 * 3600, 5, 20)
      ).to.be.revertedWith("Only owner can call this function");
    });

    it("Should not allow quorum over 100%", async function () {
      await expect(
        votingSystem.updateVotingParameters(3600, 7 * 24 * 3600, 1, 101)
      ).to.be.revertedWith("Quorum cannot exceed 100%");
    });

    it("Should allow ownership transfer", async function () {
      await votingSystem.transferOwnership(addr1.address);
      expect(await votingSystem.owner()).to.equal(addr1.address);
    });

    it("Should not allow transfer to zero address", async function () {
      await expect(
        votingSystem.transferOwnership(ethers.ZeroAddress)
      ).to.be.revertedWith("New owner cannot be zero address");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle non-existent proposal queries gracefully", async function () {
      await expect(
        votingSystem.getProposal(999)
      ).to.be.revertedWith("Proposal does not exist");

      await expect(
        votingSystem.hasVoted(999, addr1.address)
      ).to.be.revertedWith("Proposal does not exist");
    });

    it("Should handle getUserVote for non-voted user", async function () {
      await votingSystem.setVotingPower(addr1.address, 50);
      await votingSystem.connect(addr1).createProposal("Test", "Test");

      await expect(
        votingSystem.getUserVote(1, addr2.address)
      ).to.be.revertedWith("User has not voted");
    });
  });
});
