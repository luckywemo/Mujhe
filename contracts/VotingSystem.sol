// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title VotingSystem
 * @dev A decentralized voting system for creating proposals and conducting transparent votes
 * @author CELO Developer
 */
contract VotingSystem {
    // Structs
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool exists;
        ProposalState state;
        mapping(address => bool) hasVoted;
        mapping(address => VoteChoice) votes;
    }
    
    struct Vote {
        address voter;
        uint256 proposalId;
        VoteChoice choice;
        uint256 weight;
        uint256 timestamp;
        string reason;
    }
    
    struct Delegation {
        address delegate;
        uint256 timestamp;
        bool active;
    }
    
    // Enums
    enum VoteChoice { FOR, AGAINST, ABSTAIN }
    enum ProposalState { PENDING, ACTIVE, SUCCEEDED, DEFEATED, EXECUTED, CANCELLED }
    
    // State variables
    address public owner;
    uint256 public totalProposals;
    uint256 public votingDelay = 1 hours; // Time before voting starts
    uint256 public votingPeriod = 7 days; // Duration of voting
    uint256 public proposalThreshold = 1; // Minimum tokens to create proposal
    uint256 public quorumPercentage = 10; // 10% quorum required
    
    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower; // Could be token balance
    mapping(address => Delegation) public delegations;
    mapping(address => uint256[]) public userProposals;
    mapping(address => Vote[]) public userVotes;
    mapping(uint256 => Vote[]) public proposalVotes;
    
    // Arrays
    uint256[] public allProposals;
    address[] public allVoters;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startTime,
        uint256 endTime
    );
    
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        VoteChoice choice,
        uint256 weight,
        string reason
    );
    
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);
    
    event DelegationSet(
        address indexed delegator,
        address indexed delegate,
        uint256 timestamp
    );
    
    event DelegationRevoked(
        address indexed delegator,
        address indexed previousDelegate,
        uint256 timestamp
    );
    
    event VotingPowerUpdated(address indexed user, uint256 oldPower, uint256 newPower);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].exists, "Proposal does not exist");
        _;
    }
    
    modifier hasVotingPower() {
        require(getVotingPower(msg.sender) > 0, "No voting power");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        // Give initial voting power to deployer for testing
        votingPower[msg.sender] = 100;
        emit VotingPowerUpdated(msg.sender, 0, 100);
    }
    
    // Core Functions
    
    /**
     * @dev Create a new proposal
     */
    function createProposal(
        string memory _title,
        string memory _description
    ) public hasVotingPower returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_title).length <= 200, "Title too long");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_description).length <= 1000, "Description too long");
        require(getVotingPower(msg.sender) >= proposalThreshold, "Insufficient voting power");
        
        totalProposals++;
        uint256 proposalId = totalProposals;
        
        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = startTime + votingPeriod;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.startTime = startTime;
        newProposal.endTime = endTime;
        newProposal.exists = true;
        newProposal.state = ProposalState.PENDING;
        
        allProposals.push(proposalId);
        userProposals[msg.sender].push(proposalId);
        
        emit ProposalCreated(proposalId, msg.sender, _title, startTime, endTime);
        
        return proposalId;
    }
    
    /**
     * @dev Cast a vote on a proposal
     */
    function vote(
        uint256 proposalId,
        VoteChoice choice,
        string memory reason
    ) public proposalExists(proposalId) hasVotingPower {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(proposal.state == ProposalState.ACTIVE || proposal.state == ProposalState.PENDING, "Invalid proposal state");
        
        // Update proposal state if needed
        if (proposal.state == ProposalState.PENDING && block.timestamp >= proposal.startTime) {
            proposal.state = ProposalState.ACTIVE;
        }
        
        uint256 weight = getVotingPower(msg.sender);
        
        // Record the vote
        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = choice;
        
        // Update vote counts
        if (choice == VoteChoice.FOR) {
            proposal.forVotes += weight;
        } else if (choice == VoteChoice.AGAINST) {
            proposal.againstVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }
        
        // Store vote details
        Vote memory voteRecord = Vote({
            voter: msg.sender,
            proposalId: proposalId,
            choice: choice,
            weight: weight,
            timestamp: block.timestamp,
            reason: reason
        });
        
        userVotes[msg.sender].push(voteRecord);
        proposalVotes[proposalId].push(voteRecord);
        
        // Add to voters list if first time voting
        if (userVotes[msg.sender].length == 1) {
            allVoters.push(msg.sender);
        }
        
        emit VoteCast(msg.sender, proposalId, choice, weight, reason);
        
        // Update proposal state if voting ended
        _updateProposalState(proposalId);
    }
    
    /**
     * @dev Delegate voting power to another address
     */
    function delegate(address _delegate) public hasVotingPower {
        require(_delegate != address(0), "Cannot delegate to zero address");
        require(_delegate != msg.sender, "Cannot delegate to self");
        require(getVotingPower(_delegate) > 0, "Delegate has no voting power");
        
        // Revoke previous delegation if exists
        if (delegations[msg.sender].active) {
            emit DelegationRevoked(msg.sender, delegations[msg.sender].delegate, block.timestamp);
        }
        
        delegations[msg.sender] = Delegation({
            delegate: _delegate,
            timestamp: block.timestamp,
            active: true
        });
        
        emit DelegationSet(msg.sender, _delegate, block.timestamp);
    }
    
    /**
     * @dev Revoke delegation
     */
    function revokeDelegation() public {
        require(delegations[msg.sender].active, "No active delegation");
        
        address previousDelegate = delegations[msg.sender].delegate;
        delegations[msg.sender].active = false;
        
        emit DelegationRevoked(msg.sender, previousDelegate, block.timestamp);
    }
    
    /**
     * @dev Execute a successful proposal (placeholder for actual execution logic)
     */
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp > proposal.endTime, "Voting still active");
        require(!proposal.executed, "Already executed");
        
        // Check if proposal succeeded
        ProposalState currentState = getProposalState(proposalId);
        require(currentState == ProposalState.SUCCEEDED, "Proposal not succeeded");
        
        proposal.executed = true;
        proposal.state = ProposalState.EXECUTED;
        
        emit ProposalExecuted(proposalId, msg.sender);
        
        // Placeholder for actual execution logic
        // In a real implementation, this would execute the proposed changes
    }
    
    /**
     * @dev Cancel a proposal (only by proposer or owner)
     */
    function cancelProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        require(
            msg.sender == proposal.proposer || msg.sender == owner,
            "Only proposer or owner can cancel"
        );
        require(proposal.state == ProposalState.PENDING || proposal.state == ProposalState.ACTIVE, "Cannot cancel");
        
        proposal.state = ProposalState.CANCELLED;
        
        emit ProposalCancelled(proposalId, msg.sender);
    }
    
    // View Functions
    
    /**
     * @dev Get effective voting power (including delegations)
     */
    function getVotingPower(address user) public view returns (uint256) {
        uint256 power = votingPower[user];
        
        // Add delegated power
        for (uint256 i = 0; i < allVoters.length; i++) {
            address voter = allVoters[i];
            if (delegations[voter].active && delegations[voter].delegate == user) {
                power += votingPower[voter];
            }
        }
        
        return power;
    }
    
    /**
     * @dev Get proposal details
     */
    function getProposal(uint256 proposalId) public view proposalExists(proposalId) returns (
        uint256 id,
        string memory title,
        string memory description,
        address proposer,
        uint256 startTime,
        uint256 endTime,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        bool executed,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.proposer,
            proposal.startTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.state
        );
    }
    
    /**
     * @dev Check if user has voted on a proposal
     */
    function hasVoted(uint256 proposalId, address user) public view proposalExists(proposalId) returns (bool) {
        return proposals[proposalId].hasVoted[user];
    }
    
    /**
     * @dev Get user's vote on a proposal
     */
    function getUserVote(uint256 proposalId, address user) public view proposalExists(proposalId) returns (VoteChoice) {
        require(proposals[proposalId].hasVoted[user], "User has not voted");
        return proposals[proposalId].votes[user];
    }
    
    /**
     * @dev Get all proposals
     */
    function getAllProposals() public view returns (uint256[] memory) {
        return allProposals;
    }
    
    /**
     * @dev Get user's proposals
     */
    function getUserProposals(address user) public view returns (uint256[] memory) {
        return userProposals[user];
    }
    
    /**
     * @dev Get user's votes
     */
    function getUserVotes(address user) public view returns (Vote[] memory) {
        return userVotes[user];
    }
    
    /**
     * @dev Get votes for a proposal
     */
    function getProposalVotes(uint256 proposalId) public view proposalExists(proposalId) returns (Vote[] memory) {
        return proposalVotes[proposalId];
    }
    
    /**
     * @dev Get current proposal state
     */
    function getProposalState(uint256 proposalId) public view proposalExists(proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.state == ProposalState.CANCELLED || proposal.state == ProposalState.EXECUTED) {
            return proposal.state;
        }
        
        if (block.timestamp < proposal.startTime) {
            return ProposalState.PENDING;
        }
        
        if (block.timestamp <= proposal.endTime) {
            return ProposalState.ACTIVE;
        }
        
        // Voting ended, determine result
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        
        // Check quorum first
        if (totalVotes == 0) {
            return ProposalState.DEFEATED;
        }
        
        // For testing purposes, we'll use a simple total voting power calculation
        // In production, this should be more sophisticated
        uint256 totalPower = 1000; // Simplified for testing
        
        // Check quorum
        if (totalVotes * 100 < totalPower * quorumPercentage) {
            return ProposalState.DEFEATED;
        }
        
        // Check if majority voted for
        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.SUCCEEDED;
        } else {
            return ProposalState.DEFEATED;
        }
    }
    
    /**
     * @dev Get voting statistics
     */
    function getVotingStats() public view returns (
        uint256 totalProposalsCount,
        uint256 totalVotersCount,
        uint256 totalVotingPowerCount,
        uint256 activeProposalsCount
    ) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allProposals.length; i++) {
            ProposalState state = getProposalState(allProposals[i]);
            if (state == ProposalState.ACTIVE || state == ProposalState.PENDING) {
                activeCount++;
            }
        }
        
        return (
            totalProposals,
            allVoters.length,
            _getTotalVotingPower(),
            activeCount
        );
    }
    
    // Admin Functions
    
    /**
     * @dev Set voting power for a user (only owner)
     */
    function setVotingPower(address user, uint256 power) public onlyOwner {
        uint256 oldPower = votingPower[user];
        votingPower[user] = power;
        emit VotingPowerUpdated(user, oldPower, power);
    }
    
    /**
     * @dev Update voting parameters (only owner)
     */
    function updateVotingParameters(
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    ) public onlyOwner {
        require(_quorumPercentage <= 100, "Quorum cannot exceed 100%");
        
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumPercentage = _quorumPercentage;
    }
    
    /**
     * @dev Transfer ownership
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
    
    // Internal Functions
    
    /**
     * @dev Update proposal state based on current time and votes
     */
    function _updateProposalState(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        if (block.timestamp > proposal.endTime && proposal.state == ProposalState.ACTIVE) {
            ProposalState newState = getProposalState(proposalId);
            proposal.state = newState;
        }
    }
    
    /**
     * @dev Get total voting power in the system
     */
    function _getTotalVotingPower() internal pure returns (uint256) {
        // In a real implementation, this would be more efficient
        // For now, we'll use a simple approach for testing
        return 1000; // Placeholder - in real implementation, sum all voting power
    }
}
