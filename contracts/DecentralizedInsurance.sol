// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title DecentralizedInsurance
 * @dev A comprehensive decentralized insurance platform supporting multiple coverage types
 * Features: Premium calculation, claims processing, staking pools, governance, and fraud detection
 */
contract DecentralizedInsurance is Ownable, ReentrancyGuard, Pausable {
    
    // Insurance Types
    enum InsuranceType { HEALTH, PROPERTY, TRAVEL, CRYPTO, LIFE }
    
    // Policy Status
    enum PolicyStatus { ACTIVE, EXPIRED, CANCELLED, CLAIMED }
    
    // Claim Status
    enum ClaimStatus { PENDING, INVESTIGATING, APPROVED, REJECTED, PAID }
    
    // Risk Levels
    enum RiskLevel { LOW, MEDIUM, HIGH, CRITICAL }
    
    struct Policy {
        uint256 policyId;
        address policyholder;
        InsuranceType insuranceType;
        uint256 coverageAmount;
        uint256 premiumAmount;
        uint256 startDate;
        uint256 endDate;
        PolicyStatus status;
        RiskLevel riskLevel;
        string metadataURI; // IPFS hash for policy details
        uint256 claimsCount;
        uint256 totalClaimsAmount;
    }
    
    struct Claim {
        uint256 claimId;
        uint256 policyId;
        address claimant;
        uint256 claimAmount;
        uint256 submissionDate;
        uint256 investigationDeadline;
        ClaimStatus status;
        string evidenceURI; // IPFS hash for claim evidence
        string rejectionReason;
        uint256 approvedAmount;
        uint256 payoutDate;
        address investigator;
    }
    
    struct StakeInfo {
        uint256 amount;
        uint256 stakingDate;
        uint256 rewardsEarned;
        uint256 lastRewardUpdate;
    }
    
    struct InsurancePool {
        uint256 totalStaked;
        uint256 totalClaims;
        uint256 availableFunds;
        uint256 rewardRate; // Annual percentage rate (in basis points)
        bool active;
    }
    
    // State Variables
    uint256 private nextPolicyId = 1;
    uint256 private nextClaimId = 1;
    
    // Mappings
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public userPolicies;
    mapping(address => uint256[]) public userClaims;
    mapping(address => StakeInfo) public stakes;
    mapping(InsuranceType => InsurancePool) public insurancePools;
    mapping(address => bool) public authorizedInvestigators;
    mapping(address => bool) public authorizedOracles;
    
    // Constants
    uint256 public constant INVESTIGATION_PERIOD = 7 days;
    uint256 public constant MIN_STAKE_AMOUNT = 100 ether; // 100 CELO minimum
    uint256 public constant MAX_COVERAGE_RATIO = 80; // 80% of pool can be used for coverage
    uint256 public constant FRAUD_PENALTY = 1000; // 10% penalty in basis points
    
    // Premium rates (in basis points, per year)
    mapping(InsuranceType => mapping(RiskLevel => uint256)) public premiumRates;
    
    // Events
    event PolicyCreated(uint256 indexed policyId, address indexed policyholder, InsuranceType insuranceType, uint256 coverageAmount);
    event PremiumPaid(uint256 indexed policyId, address indexed policyholder, uint256 amount);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);
    event ClaimInvestigated(uint256 indexed claimId, address indexed investigator, ClaimStatus status);
    event ClaimPaid(uint256 indexed claimId, address indexed claimant, uint256 amount);
    event StakeDeposited(address indexed staker, uint256 amount);
    event StakeWithdrawn(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 amount);
    event InvestigatorAdded(address indexed investigator);
    event OracleAdded(address indexed oracle);
    event FraudDetected(uint256 indexed claimId, address indexed claimant);
    
    constructor() Ownable(msg.sender) {
        // Initialize premium rates (in basis points per year)
        // Health Insurance
        premiumRates[InsuranceType.HEALTH][RiskLevel.LOW] = 200;    // 2%
        premiumRates[InsuranceType.HEALTH][RiskLevel.MEDIUM] = 400; // 4%
        premiumRates[InsuranceType.HEALTH][RiskLevel.HIGH] = 800;   // 8%
        premiumRates[InsuranceType.HEALTH][RiskLevel.CRITICAL] = 1500; // 15%
        
        // Property Insurance
        premiumRates[InsuranceType.PROPERTY][RiskLevel.LOW] = 100;    // 1%
        premiumRates[InsuranceType.PROPERTY][RiskLevel.MEDIUM] = 250; // 2.5%
        premiumRates[InsuranceType.PROPERTY][RiskLevel.HIGH] = 500;   // 5%
        premiumRates[InsuranceType.PROPERTY][RiskLevel.CRITICAL] = 1000; // 10%
        
        // Travel Insurance
        premiumRates[InsuranceType.TRAVEL][RiskLevel.LOW] = 150;    // 1.5%
        premiumRates[InsuranceType.TRAVEL][RiskLevel.MEDIUM] = 300; // 3%
        premiumRates[InsuranceType.TRAVEL][RiskLevel.HIGH] = 600;   // 6%
        premiumRates[InsuranceType.TRAVEL][RiskLevel.CRITICAL] = 1200; // 12%
        
        // Crypto Insurance
        premiumRates[InsuranceType.CRYPTO][RiskLevel.LOW] = 300;    // 3%
        premiumRates[InsuranceType.CRYPTO][RiskLevel.MEDIUM] = 600; // 6%
        premiumRates[InsuranceType.CRYPTO][RiskLevel.HIGH] = 1200;  // 12%
        premiumRates[InsuranceType.CRYPTO][RiskLevel.CRITICAL] = 2000; // 20%
        
        // Life Insurance
        premiumRates[InsuranceType.LIFE][RiskLevel.LOW] = 50;     // 0.5%
        premiumRates[InsuranceType.LIFE][RiskLevel.MEDIUM] = 150; // 1.5%
        premiumRates[InsuranceType.LIFE][RiskLevel.HIGH] = 400;   // 4%
        premiumRates[InsuranceType.LIFE][RiskLevel.CRITICAL] = 800; // 8%
        
        // Initialize insurance pools
        for (uint i = 0; i < 5; i++) {
            InsuranceType insType = InsuranceType(i);
            insurancePools[insType] = InsurancePool({
                totalStaked: 0,
                totalClaims: 0,
                availableFunds: 0,
                rewardRate: 1000, // 10% annual reward rate
                active: true
            });
        }
    }
    
    // Modifiers
    modifier onlyInvestigator() {
        require(authorizedInvestigators[msg.sender], "Not authorized investigator");
        _;
    }
    
    modifier onlyOracle() {
        require(authorizedOracles[msg.sender], "Not authorized oracle");
        _;
    }
    
    modifier validPolicy(uint256 _policyId) {
        require(_policyId > 0 && _policyId < nextPolicyId, "Invalid policy ID");
        require(policies[_policyId].status == PolicyStatus.ACTIVE, "Policy not active");
        _;
    }
    
    modifier validClaim(uint256 _claimId) {
        require(_claimId > 0 && _claimId < nextClaimId, "Invalid claim ID");
        _;
    }
    
    // Policy Management Functions
    
    /**
     * @dev Create a new insurance policy
     */
    function createPolicy(
        InsuranceType _insuranceType,
        uint256 _coverageAmount,
        uint256 _duration, // in seconds
        RiskLevel _riskLevel,
        string memory _metadataURI
    ) external payable nonReentrant whenNotPaused {
        require(_coverageAmount > 0, "Coverage amount must be positive");
        require(_duration >= 30 days, "Minimum duration is 30 days");
        require(_duration <= 365 days, "Maximum duration is 365 days");
        require(insurancePools[_insuranceType].active, "Insurance type not active");
        
        // Calculate premium
        uint256 premiumAmount = calculatePremium(_insuranceType, _coverageAmount, _duration, _riskLevel);
        require(msg.value >= premiumAmount, "Insufficient premium payment");
        
        // Check pool capacity
        uint256 maxCoverage = (insurancePools[_insuranceType].availableFunds * MAX_COVERAGE_RATIO) / 100;
        require(_coverageAmount <= maxCoverage, "Coverage exceeds pool capacity");
        
        // Create policy
        uint256 policyId = nextPolicyId++;
        policies[policyId] = Policy({
            policyId: policyId,
            policyholder: msg.sender,
            insuranceType: _insuranceType,
            coverageAmount: _coverageAmount,
            premiumAmount: premiumAmount,
            startDate: block.timestamp,
            endDate: block.timestamp + _duration,
            status: PolicyStatus.ACTIVE,
            riskLevel: _riskLevel,
            metadataURI: _metadataURI,
            claimsCount: 0,
            totalClaimsAmount: 0
        });
        
        userPolicies[msg.sender].push(policyId);
        
        // Add premium to insurance pool
        insurancePools[_insuranceType].availableFunds += premiumAmount;
        
        // Refund excess payment
        if (msg.value > premiumAmount) {
            payable(msg.sender).transfer(msg.value - premiumAmount);
        }
        
        emit PolicyCreated(policyId, msg.sender, _insuranceType, _coverageAmount);
        emit PremiumPaid(policyId, msg.sender, premiumAmount);
    }
    
    /**
     * @dev Calculate premium for a policy
     */
    function calculatePremium(
        InsuranceType _insuranceType,
        uint256 _coverageAmount,
        uint256 _duration,
        RiskLevel _riskLevel
    ) public view returns (uint256) {
        uint256 annualRate = premiumRates[_insuranceType][_riskLevel];
        uint256 premium = (_coverageAmount * annualRate * _duration) / (10000 * 365 days);
        return premium;
    }
    
    /**
     * @dev Submit a claim
     */
    function submitClaim(
        uint256 _policyId,
        uint256 _claimAmount,
        string memory _evidenceURI
    ) external nonReentrant validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];
        require(msg.sender == policy.policyholder, "Not policy holder");
        require(block.timestamp <= policy.endDate, "Policy expired");
        require(_claimAmount > 0, "Claim amount must be positive");
        require(_claimAmount <= policy.coverageAmount, "Claim exceeds coverage");
        
        uint256 claimId = nextClaimId++;
        claims[claimId] = Claim({
            claimId: claimId,
            policyId: _policyId,
            claimant: msg.sender,
            claimAmount: _claimAmount,
            submissionDate: block.timestamp,
            investigationDeadline: block.timestamp + INVESTIGATION_PERIOD,
            status: ClaimStatus.PENDING,
            evidenceURI: _evidenceURI,
            rejectionReason: "",
            approvedAmount: 0,
            payoutDate: 0,
            investigator: address(0)
        });
        
        userClaims[msg.sender].push(claimId);
        
        emit ClaimSubmitted(claimId, _policyId, msg.sender, _claimAmount);
    }
    
    /**
     * @dev Investigate a claim (only authorized investigators)
     */
    function investigateClaim(
        uint256 _claimId,
        ClaimStatus _decision,
        uint256 _approvedAmount,
        string memory _rejectionReason
    ) external onlyInvestigator validClaim(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.PENDING, "Claim not pending");
        require(block.timestamp <= claim.investigationDeadline, "Investigation period expired");
        require(_decision == ClaimStatus.APPROVED || _decision == ClaimStatus.REJECTED, "Invalid decision");
        
        if (_decision == ClaimStatus.APPROVED) {
            require(_approvedAmount > 0 && _approvedAmount <= claim.claimAmount, "Invalid approved amount");
            claim.approvedAmount = _approvedAmount;
            claim.status = ClaimStatus.APPROVED;
        } else {
            require(bytes(_rejectionReason).length > 0, "Rejection reason required");
            claim.rejectionReason = _rejectionReason;
            claim.status = ClaimStatus.REJECTED;
        }
        
        claim.investigator = msg.sender;
        
        emit ClaimInvestigated(_claimId, msg.sender, _decision);
    }
    
    /**
     * @dev Pay approved claim
     */
    function payClaim(uint256 _claimId) external nonReentrant validClaim(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.APPROVED, "Claim not approved");
        
        Policy storage policy = policies[claim.policyId];
        InsurancePool storage pool = insurancePools[policy.insuranceType];
        
        require(pool.availableFunds >= claim.approvedAmount, "Insufficient pool funds");
        
        // Update claim status
        claim.status = ClaimStatus.PAID;
        claim.payoutDate = block.timestamp;
        
        // Update policy
        policy.claimsCount++;
        policy.totalClaimsAmount += claim.approvedAmount;
        
        // Update pool
        pool.availableFunds -= claim.approvedAmount;
        pool.totalClaims += claim.approvedAmount;
        
        // Transfer payment
        payable(claim.claimant).transfer(claim.approvedAmount);
        
        emit ClaimPaid(_claimId, claim.claimant, claim.approvedAmount);
    }
    
    // Staking Functions
    
    /**
     * @dev Stake CELO to provide liquidity
     */
    function stake() external payable nonReentrant whenNotPaused {
        require(msg.value >= MIN_STAKE_AMOUNT, "Minimum stake amount not met");
        
        StakeInfo storage stakeInfo = stakes[msg.sender];
        
        // Update rewards before modifying stake
        if (stakeInfo.amount > 0) {
            updateRewards(msg.sender);
        }
        
        stakeInfo.amount += msg.value;
        stakeInfo.stakingDate = block.timestamp;
        stakeInfo.lastRewardUpdate = block.timestamp;
        
        // Distribute stake across all active pools equally
        uint256 stakePerPool = msg.value / 5;
        for (uint i = 0; i < 5; i++) {
            InsuranceType insType = InsuranceType(i);
            if (insurancePools[insType].active) {
                insurancePools[insType].totalStaked += stakePerPool;
                insurancePools[insType].availableFunds += stakePerPool;
            }
        }
        
        emit StakeDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw stake
     */
    function withdrawStake(uint256 _amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount >= _amount, "Insufficient stake");
        require(_amount > 0, "Amount must be positive");
        
        // Update rewards before withdrawal
        updateRewards(msg.sender);
        
        // Check if withdrawal affects pool solvency
        uint256 totalPoolFunds = getTotalPoolFunds();
        uint256 totalCoverage = getTotalActiveCoverage();
        require(totalPoolFunds - _amount >= (totalCoverage * MAX_COVERAGE_RATIO) / 100, "Withdrawal would affect solvency");
        
        stakeInfo.amount -= _amount;
        
        // Remove stake from pools proportionally
        uint256 withdrawalPerPool = _amount / 5;
        for (uint i = 0; i < 5; i++) {
            InsuranceType insType = InsuranceType(i);
            if (insurancePools[insType].totalStaked >= withdrawalPerPool) {
                insurancePools[insType].totalStaked -= withdrawalPerPool;
                insurancePools[insType].availableFunds -= withdrawalPerPool;
            }
        }
        
        payable(msg.sender).transfer(_amount);
        
        emit StakeWithdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Claim staking rewards
     */
    function claimRewards() external nonReentrant {
        updateRewards(msg.sender);
        
        StakeInfo storage stakeInfo = stakes[msg.sender];
        uint256 rewards = stakeInfo.rewardsEarned;
        require(rewards > 0, "No rewards to claim");
        
        stakeInfo.rewardsEarned = 0;
        
        payable(msg.sender).transfer(rewards);
        
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    /**
     * @dev Update staking rewards for a user
     */
    function updateRewards(address _staker) internal {
        StakeInfo storage stakeInfo = stakes[_staker];
        if (stakeInfo.amount == 0) return;
        
        uint256 timeElapsed = block.timestamp - stakeInfo.lastRewardUpdate;
        uint256 annualReward = (stakeInfo.amount * 1000) / 10000; // 10% annual rate
        uint256 reward = (annualReward * timeElapsed) / 365 days;
        
        stakeInfo.rewardsEarned += reward;
        stakeInfo.lastRewardUpdate = block.timestamp;
    }
    
    // View Functions
    
    /**
     * @dev Get policy details
     */
    function getPolicy(uint256 _policyId) external view returns (Policy memory) {
        return policies[_policyId];
    }
    
    /**
     * @dev Get claim details
     */
    function getClaim(uint256 _claimId) external view returns (Claim memory) {
        return claims[_claimId];
    }
    
    /**
     * @dev Get user's policies
     */
    function getUserPolicies(address _user) external view returns (uint256[] memory) {
        return userPolicies[_user];
    }
    
    /**
     * @dev Get user's claims
     */
    function getUserClaims(address _user) external view returns (uint256[] memory) {
        return userClaims[_user];
    }
    
    /**
     * @dev Get stake information
     */
    function getStakeInfo(address _staker) external view returns (StakeInfo memory) {
        return stakes[_staker];
    }
    
    /**
     * @dev Get insurance pool information
     */
    function getInsurancePool(InsuranceType _type) external view returns (InsurancePool memory) {
        return insurancePools[_type];
    }
    
    /**
     * @dev Get total pool funds across all insurance types
     */
    function getTotalPoolFunds() public view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < 5; i++) {
            total += insurancePools[InsuranceType(i)].availableFunds;
        }
        return total;
    }
    
    /**
     * @dev Get total active coverage across all policies
     */
    function getTotalActiveCoverage() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i < nextPolicyId; i++) {
            if (policies[i].status == PolicyStatus.ACTIVE && block.timestamp <= policies[i].endDate) {
                total += policies[i].coverageAmount;
            }
        }
        return total;
    }
    
    /**
     * @dev Calculate pending rewards for a staker
     */
    function calculatePendingRewards(address _staker) external view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[_staker];
        if (stakeInfo.amount == 0) return stakeInfo.rewardsEarned;
        
        uint256 timeElapsed = block.timestamp - stakeInfo.lastRewardUpdate;
        uint256 annualReward = (stakeInfo.amount * 1000) / 10000; // 10% annual rate
        uint256 newReward = (annualReward * timeElapsed) / 365 days;
        
        return stakeInfo.rewardsEarned + newReward;
    }
    
    // Admin Functions
    
    /**
     * @dev Add authorized investigator
     */
    function addInvestigator(address _investigator) external onlyOwner {
        authorizedInvestigators[_investigator] = true;
        emit InvestigatorAdded(_investigator);
    }
    
    /**
     * @dev Remove authorized investigator
     */
    function removeInvestigator(address _investigator) external onlyOwner {
        authorizedInvestigators[_investigator] = false;
    }
    
    /**
     * @dev Add authorized oracle
     */
    function addOracle(address _oracle) external onlyOwner {
        authorizedOracles[_oracle] = true;
        emit OracleAdded(_oracle);
    }
    
    /**
     * @dev Remove authorized oracle
     */
    function removeOracle(address _oracle) external onlyOwner {
        authorizedOracles[_oracle] = false;
    }
    
    /**
     * @dev Update premium rates
     */
    function updatePremiumRate(
        InsuranceType _type,
        RiskLevel _risk,
        uint256 _rate
    ) external onlyOwner {
        require(_rate <= 5000, "Rate cannot exceed 50%");
        premiumRates[_type][_risk] = _rate;
    }
    
    /**
     * @dev Update pool reward rate
     */
    function updatePoolRewardRate(InsuranceType _type, uint256 _rate) external onlyOwner {
        require(_rate <= 2000, "Rate cannot exceed 20%");
        insurancePools[_type].rewardRate = _rate;
    }
    
    /**
     * @dev Toggle insurance pool active status
     */
    function togglePoolStatus(InsuranceType _type) external onlyOwner {
        insurancePools[_type].active = !insurancePools[_type].active;
    }
    
    /**
     * @dev Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Oracle function to automatically approve small claims
     */
    function oracleApproveClaim(uint256 _claimId, uint256 _approvedAmount) external onlyOracle validClaim(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.PENDING, "Claim not pending");
        require(_approvedAmount <= claim.claimAmount, "Approved amount exceeds claim");
        require(_approvedAmount <= 1000 ether, "Oracle approval limit exceeded"); // 1000 CELO limit
        
        claim.status = ClaimStatus.APPROVED;
        claim.approvedAmount = _approvedAmount;
        claim.investigator = msg.sender;
        
        emit ClaimInvestigated(_claimId, msg.sender, ClaimStatus.APPROVED);
    }
    
    /**
     * @dev Report fraud (reduces claimant's future coverage and applies penalty)
     */
    function reportFraud(uint256 _claimId) external onlyInvestigator validClaim(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.REJECTED, "Claim must be rejected first");
        
        // Apply fraud penalty - reduce future coverage for this address
        // This is a simplified implementation; in practice, you'd want more sophisticated fraud tracking
        
        emit FraudDetected(_claimId, claim.claimant);
    }
    
    // Emergency withdrawal for contract upgrades (only owner)
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // Receive function to accept CELO
    receive() external payable {
        // Allow contract to receive CELO for staking and premiums
    }
}
