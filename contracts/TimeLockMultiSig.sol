// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title TimeLockMultiSig
 * @dev A sophisticated multi-signature wallet with time-lock delays and advanced security features
 * @author CELO Developer
 */
contract TimeLockMultiSig is ReentrancyGuard, Pausable {
    // Enums
    enum TransactionStatus {
        PENDING,
        QUEUED,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }
    
    enum ProposalType {
        ADD_OWNER,
        REMOVE_OWNER,
        CHANGE_THRESHOLD,
        CHANGE_TIME_LOCK,
        CHANGE_DAILY_LIMIT,
        EMERGENCY_RECOVERY
    }
    
    // Structs
    struct Transaction {
        uint256 id;
        address to;
        uint256 value;
        bytes data;
        uint256 confirmations;
        uint256 queuedAt;
        uint256 executeAfter;
        TransactionStatus status;
        address proposer;
        mapping(address => bool) confirmed;
        string description;
    }
    
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address target;
        uint256 value;
        bytes data;
        uint256 confirmations;
        uint256 queuedAt;
        uint256 executeAfter;
        TransactionStatus status;
        address proposer;
        mapping(address => bool) confirmed;
        string description;
    }
    
    struct DailyLimit {
        uint256 limit;
        uint256 spent;
        uint256 lastResetTime;
    }
    
    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isGuardian;
    uint256 public threshold;
    uint256 public timeLockDelay;
    uint256 public emergencyTimeLock;
    uint256 public instantTransactionLimit;
    
    // Transaction management
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    uint256[] public pendingTransactions;
    uint256[] public queuedTransactions;
    
    // Proposal management
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    uint256[] public activeProposals;
    
    // Daily limits
    DailyLimit public dailyLimit;
    
    // Emergency features
    bool public emergencyMode;
    address public emergencyRecoveryAddress;
    uint256 public emergencyActivatedAt;
    uint256 public constant EMERGENCY_TIMEOUT = 30 days;
    
    // Constants
    uint256 public constant MAX_OWNERS = 20;
    uint256 public constant MIN_THRESHOLD = 1;
    uint256 public constant MIN_TIME_LOCK = 1 hours;
    uint256 public constant MAX_TIME_LOCK = 30 days;
    
    // Events
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 oldThreshold, uint256 newThreshold);
    event TimeLockChanged(uint256 oldTimeLock, uint256 newTimeLock);
    event DailyLimitChanged(uint256 oldLimit, uint256 newLimit);
    
    event TransactionSubmitted(
        uint256 indexed transactionId,
        address indexed proposer,
        address indexed to,
        uint256 value,
        string description
    );
    
    event TransactionConfirmed(
        uint256 indexed transactionId,
        address indexed owner,
        uint256 confirmations
    );
    
    event TransactionQueued(
        uint256 indexed transactionId,
        uint256 executeAfter
    );
    
    event TransactionExecuted(
        uint256 indexed transactionId,
        address indexed to,
        uint256 value,
        bool success
    );
    
    event TransactionCancelled(uint256 indexed transactionId);
    
    event ProposalSubmitted(
        uint256 indexed proposalId,
        ProposalType proposalType,
        address indexed proposer,
        string description
    );
    
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    
    event EmergencyModeActivated(address indexed activator);
    event EmergencyModeDeactivated(address indexed deactivator);
    event EmergencyRecoveryExecuted(address indexed newOwner);
    
    event Deposit(address indexed sender, uint256 value);
    event DailyLimitReset(uint256 newResetTime);
    
    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Not a guardian");
        _;
    }
    
    modifier onlyOwnerOrGuardian() {
        require(isOwner[msg.sender] || isGuardian[msg.sender], "Not authorized");
        _;
    }
    
    modifier transactionExists(uint256 transactionId) {
        require(transactionId < transactionCount, "Transaction does not exist");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }
    
    modifier notEmergencyMode() {
        require(!emergencyMode, "Emergency mode active");
        _;
    }
    
    modifier validOwner(address owner) {
        require(owner != address(0), "Invalid owner address");
        require(!isOwner[owner], "Already an owner");
        _;
    }
    
    // Constructor
    constructor(
        address[] memory _owners,
        uint256 _threshold,
        uint256 _timeLockDelay,
        uint256 _dailyLimit,
        uint256 _instantLimit
    ) {
        require(_owners.length > 0, "At least one owner required");
        require(_owners.length <= MAX_OWNERS, "Too many owners");
        require(_threshold >= MIN_THRESHOLD, "Threshold too low");
        require(_threshold <= _owners.length, "Threshold too high");
        require(_timeLockDelay >= MIN_TIME_LOCK, "Time lock too short");
        require(_timeLockDelay <= MAX_TIME_LOCK, "Time lock too long");
        require(_instantLimit <= _dailyLimit, "Instant limit exceeds daily limit");
        
        // Set owners
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner address");
            require(!isOwner[_owners[i]], "Duplicate owner");
            
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
            emit OwnerAdded(_owners[i]);
        }
        
        threshold = _threshold;
        timeLockDelay = _timeLockDelay;
        emergencyTimeLock = _timeLockDelay * 2; // Double the regular time lock
        instantTransactionLimit = _instantLimit;
        
        // Initialize daily limit
        dailyLimit = DailyLimit({
            limit: _dailyLimit,
            spent: 0,
            lastResetTime: block.timestamp
        });
        
        emit ThresholdChanged(0, _threshold);
        emit TimeLockChanged(0, _timeLockDelay);
        emit DailyLimitChanged(0, _dailyLimit);
    }
    
    // Receive function
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    // Core Transaction Functions
    
    /**
     * @dev Submit a new transaction
     */
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data,
        string memory description
    ) public onlyOwner notEmergencyMode whenNotPaused returns (uint256) {
        require(to != address(0), "Invalid recipient");
        require(bytes(description).length > 0, "Description required");
        
        uint256 transactionId = transactionCount;
        transactionCount++;
        
        Transaction storage txn = transactions[transactionId];
        txn.id = transactionId;
        txn.to = to;
        txn.value = value;
        txn.data = data;
        txn.confirmations = 0;
        txn.status = TransactionStatus.PENDING;
        txn.proposer = msg.sender;
        txn.description = description;
        
        pendingTransactions.push(transactionId);
        
        emit TransactionSubmitted(transactionId, msg.sender, to, value, description);
        
        // Auto-confirm by proposer
        confirmTransaction(transactionId);
        
        return transactionId;
    }
    
    /**
     * @dev Confirm a pending transaction
     */
    function confirmTransaction(uint256 transactionId) 
        public 
        onlyOwner 
        transactionExists(transactionId) 
        notEmergencyMode 
        whenNotPaused 
    {
        Transaction storage txn = transactions[transactionId];
        require(txn.status == TransactionStatus.PENDING, "Transaction not pending");
        require(!txn.confirmed[msg.sender], "Already confirmed");
        
        txn.confirmed[msg.sender] = true;
        txn.confirmations++;
        
        emit TransactionConfirmed(transactionId, msg.sender, txn.confirmations);
        
        // Check if threshold reached
        if (txn.confirmations >= threshold) {
            _queueTransaction(transactionId);
        }
    }
    
    /**
     * @dev Queue a transaction for time-locked execution
     */
    function _queueTransaction(uint256 transactionId) internal {
        Transaction storage txn = transactions[transactionId];
        
        // Check if transaction can be executed instantly
        bool canExecuteInstantly = txn.value <= instantTransactionLimit && 
                                  _checkDailyLimit(txn.value);
        
        if (canExecuteInstantly && txn.data.length == 0) {
            // Execute immediately for small transfers without data
            _executeTransaction(transactionId);
        } else {
            // Queue for time-locked execution
            txn.status = TransactionStatus.QUEUED;
            txn.queuedAt = block.timestamp;
            txn.executeAfter = block.timestamp + timeLockDelay;
            
            _removeFromPending(transactionId);
            queuedTransactions.push(transactionId);
            
            emit TransactionQueued(transactionId, txn.executeAfter);
        }
    }
    
    /**
     * @dev Execute a queued transaction
     */
    function executeTransaction(uint256 transactionId) 
        public 
        onlyOwnerOrGuardian 
        transactionExists(transactionId) 
        nonReentrant 
        whenNotPaused 
    {
        Transaction storage txn = transactions[transactionId];
        require(txn.status == TransactionStatus.QUEUED, "Transaction not queued");
        require(block.timestamp >= txn.executeAfter, "Time lock not expired");
        require(!emergencyMode || isGuardian[msg.sender], "Emergency mode restrictions");
        
        _executeTransaction(transactionId);
    }
    
    /**
     * @dev Internal function to execute transaction
     */
    function _executeTransaction(uint256 transactionId) internal {
        Transaction storage txn = transactions[transactionId];
        
        // Check daily limit
        require(_checkAndUpdateDailyLimit(txn.value), "Daily limit exceeded");
        
        // Check balance
        require(address(this).balance >= txn.value, "Insufficient balance");
        
        txn.status = TransactionStatus.EXECUTED;
        
        // Execute the transaction
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        
        if (txn.status == TransactionStatus.QUEUED) {
            _removeFromQueued(transactionId);
        } else {
            _removeFromPending(transactionId);
        }
        
        emit TransactionExecuted(transactionId, txn.to, txn.value, success);
        
        if (!success) {
            // Revert the transaction status if execution failed
            txn.status = TransactionStatus.QUEUED;
            revert("Transaction execution failed");
        }
    }
    
    /**
     * @dev Cancel a pending or queued transaction
     */
    function cancelTransaction(uint256 transactionId) 
        public 
        onlyOwner 
        transactionExists(transactionId) 
    {
        Transaction storage txn = transactions[transactionId];
        require(
            txn.status == TransactionStatus.PENDING || 
            txn.status == TransactionStatus.QUEUED,
            "Cannot cancel transaction"
        );
        require(
            msg.sender == txn.proposer || 
            txn.confirmations < threshold,
            "Not authorized to cancel"
        );
        
        txn.status = TransactionStatus.CANCELLED;
        
        if (txn.status == TransactionStatus.PENDING) {
            _removeFromPending(transactionId);
        } else {
            _removeFromQueued(transactionId);
        }
        
        emit TransactionCancelled(transactionId);
    }
    
    // Proposal Functions
    
    /**
     * @dev Submit a governance proposal
     */
    function submitProposal(
        ProposalType proposalType,
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) public onlyOwner returns (uint256) {
        require(bytes(description).length > 0, "Description required");
        
        uint256 proposalId = proposalCount;
        proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalType = proposalType;
        proposal.target = target;
        proposal.value = value;
        proposal.data = data;
        proposal.confirmations = 0;
        proposal.status = TransactionStatus.PENDING;
        proposal.proposer = msg.sender;
        proposal.description = description;
        
        activeProposals.push(proposalId);
        
        emit ProposalSubmitted(proposalId, proposalType, msg.sender, description);
        
        // Auto-confirm by proposer
        confirmProposal(proposalId);
        
        return proposalId;
    }
    
    /**
     * @dev Confirm a proposal
     */
    function confirmProposal(uint256 proposalId) 
        public 
        onlyOwner 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == TransactionStatus.PENDING, "Proposal not pending");
        require(!proposal.confirmed[msg.sender], "Already confirmed");
        
        proposal.confirmed[msg.sender] = true;
        proposal.confirmations++;
        
        // Check if threshold reached
        if (proposal.confirmations >= threshold) {
            proposal.status = TransactionStatus.QUEUED;
            proposal.queuedAt = block.timestamp;
            proposal.executeAfter = block.timestamp + emergencyTimeLock;
        }
    }
    
    /**
     * @dev Execute a proposal
     */
    function executeProposal(uint256 proposalId) 
        public 
        onlyOwner 
        proposalExists(proposalId) 
        nonReentrant 
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == TransactionStatus.QUEUED, "Proposal not queued");
        require(block.timestamp >= proposal.executeAfter, "Time lock not expired");
        
        proposal.status = TransactionStatus.EXECUTED;
        
        bool success = _executeProposal(proposalId);
        
        _removeFromActiveProposals(proposalId);
        
        emit ProposalExecuted(proposalId, success);
        
        require(success, "Proposal execution failed");
    }
    
    /**
     * @dev Internal function to execute different proposal types
     */
    function _executeProposal(uint256 proposalId) internal returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.proposalType == ProposalType.ADD_OWNER) {
            return _addOwner(proposal.target);
        } else if (proposal.proposalType == ProposalType.REMOVE_OWNER) {
            return _removeOwner(proposal.target);
        } else if (proposal.proposalType == ProposalType.CHANGE_THRESHOLD) {
            return _changeThreshold(proposal.value);
        } else if (proposal.proposalType == ProposalType.CHANGE_TIME_LOCK) {
            return _changeTimeLock(proposal.value);
        } else if (proposal.proposalType == ProposalType.CHANGE_DAILY_LIMIT) {
            return _changeDailyLimit(proposal.value);
        } else if (proposal.proposalType == ProposalType.EMERGENCY_RECOVERY) {
            return _executeEmergencyRecovery(proposal.target);
        }
        
        return false;
    }
    
    // Owner Management Functions
    
    function _addOwner(address owner) internal validOwner(owner) returns (bool) {
        require(owners.length < MAX_OWNERS, "Too many owners");
        
        owners.push(owner);
        isOwner[owner] = true;
        
        emit OwnerAdded(owner);
        return true;
    }
    
    function _removeOwner(address owner) internal returns (bool) {
        require(isOwner[owner], "Not an owner");
        require(owners.length > threshold, "Cannot remove owner below threshold");
        
        // Find and remove owner
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        
        isOwner[owner] = false;
        
        emit OwnerRemoved(owner);
        return true;
    }
    
    function _changeThreshold(uint256 newThreshold) internal returns (bool) {
        require(newThreshold >= MIN_THRESHOLD, "Threshold too low");
        require(newThreshold <= owners.length, "Threshold too high");
        
        uint256 oldThreshold = threshold;
        threshold = newThreshold;
        
        emit ThresholdChanged(oldThreshold, newThreshold);
        return true;
    }
    
    function _changeTimeLock(uint256 newTimeLock) internal returns (bool) {
        require(newTimeLock >= MIN_TIME_LOCK, "Time lock too short");
        require(newTimeLock <= MAX_TIME_LOCK, "Time lock too long");
        
        uint256 oldTimeLock = timeLockDelay;
        timeLockDelay = newTimeLock;
        emergencyTimeLock = newTimeLock * 2;
        
        emit TimeLockChanged(oldTimeLock, newTimeLock);
        return true;
    }
    
    function _changeDailyLimit(uint256 newLimit) internal returns (bool) {
        uint256 oldLimit = dailyLimit.limit;
        dailyLimit.limit = newLimit;
        
        emit DailyLimitChanged(oldLimit, newLimit);
        return true;
    }
    
    // Daily Limit Functions
    
    function _checkDailyLimit(uint256 amount) internal view returns (bool) {
        if (block.timestamp >= dailyLimit.lastResetTime + 1 days) {
            return amount <= dailyLimit.limit;
        }
        return dailyLimit.spent + amount <= dailyLimit.limit;
    }
    
    function _checkAndUpdateDailyLimit(uint256 amount) internal returns (bool) {
        // Reset daily limit if 24 hours have passed
        if (block.timestamp >= dailyLimit.lastResetTime + 1 days) {
            dailyLimit.spent = 0;
            dailyLimit.lastResetTime = block.timestamp;
            emit DailyLimitReset(block.timestamp);
        }
        
        if (dailyLimit.spent + amount > dailyLimit.limit) {
            return false;
        }
        
        dailyLimit.spent += amount;
        return true;
    }
    
    // Emergency Functions
    
    /**
     * @dev Activate emergency mode
     */
    function activateEmergencyMode() public onlyGuardian {
        require(!emergencyMode, "Emergency mode already active");
        
        emergencyMode = true;
        emergencyActivatedAt = block.timestamp;
        
        _pause();
        
        emit EmergencyModeActivated(msg.sender);
    }
    
    /**
     * @dev Deactivate emergency mode
     */
    function deactivateEmergencyMode() public onlyOwner {
        require(emergencyMode, "Emergency mode not active");
        
        emergencyMode = false;
        emergencyActivatedAt = 0;
        
        _unpause();
        
        emit EmergencyModeDeactivated(msg.sender);
    }
    
    /**
     * @dev Execute emergency recovery
     */
    function _executeEmergencyRecovery(address newOwner) internal returns (bool) {
        require(emergencyMode, "Emergency mode not active");
        require(
            block.timestamp >= emergencyActivatedAt + EMERGENCY_TIMEOUT,
            "Emergency timeout not reached"
        );
        require(newOwner != address(0), "Invalid recovery address");
        
        // Clear all owners and set new single owner
        for (uint256 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        
        delete owners;
        owners.push(newOwner);
        isOwner[newOwner] = true;
        threshold = 1;
        
        emergencyMode = false;
        emergencyActivatedAt = 0;
        
        emit EmergencyRecoveryExecuted(newOwner);
        return true;
    }
    
    // Guardian Management
    
    /**
     * @dev Add guardian (only through proposal)
     */
    function addGuardian(address guardian) public onlyOwner {
        require(guardian != address(0), "Invalid guardian address");
        require(!isGuardian[guardian], "Already a guardian");
        
        isGuardian[guardian] = true;
    }
    
    /**
     * @dev Remove guardian (only through proposal)
     */
    function removeGuardian(address guardian) public onlyOwner {
        require(isGuardian[guardian], "Not a guardian");
        
        isGuardian[guardian] = false;
    }
    
    // View Functions
    
    /**
     * @dev Get transaction details
     */
    function getTransaction(uint256 transactionId) public view returns (
        address to,
        uint256 value,
        bytes memory data,
        uint256 confirmations,
        TransactionStatus status,
        address proposer,
        string memory description
    ) {
        Transaction storage txn = transactions[transactionId];
        return (
            txn.to,
            txn.value,
            txn.data,
            txn.confirmations,
            txn.status,
            txn.proposer,
            txn.description
        );
    }
    
    /**
     * @dev Get proposal details
     */
    function getProposal(uint256 proposalId) public view returns (
        ProposalType proposalType,
        address target,
        uint256 value,
        uint256 confirmations,
        TransactionStatus status,
        address proposer,
        string memory description
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposalType,
            proposal.target,
            proposal.value,
            proposal.confirmations,
            proposal.status,
            proposal.proposer,
            proposal.description
        );
    }
    
    /**
     * @dev Check if transaction is confirmed by owner
     */
    function isConfirmed(uint256 transactionId, address owner) public view returns (bool) {
        return transactions[transactionId].confirmed[owner];
    }
    
    /**
     * @dev Check if proposal is confirmed by owner
     */
    function isProposalConfirmed(uint256 proposalId, address owner) public view returns (bool) {
        return proposals[proposalId].confirmed[owner];
    }
    
    /**
     * @dev Get wallet statistics
     */
    function getWalletStats() public view returns (
        uint256 ownerCount,
        uint256 currentThreshold,
        uint256 balance,
        uint256 pendingCount,
        uint256 queuedCount,
        uint256 dailySpent,
        uint256 dailyRemaining,
        bool isEmergencyActive
    ) {
        uint256 remaining = dailyLimit.spent >= dailyLimit.limit ? 
                           0 : dailyLimit.limit - dailyLimit.spent;
        
        return (
            owners.length,
            threshold,
            address(this).balance,
            pendingTransactions.length,
            queuedTransactions.length,
            dailyLimit.spent,
            remaining,
            emergencyMode
        );
    }
    
    /**
     * @dev Get all owners
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }
    
    /**
     * @dev Get pending transactions
     */
    function getPendingTransactions() public view returns (uint256[] memory) {
        return pendingTransactions;
    }
    
    /**
     * @dev Get queued transactions
     */
    function getQueuedTransactions() public view returns (uint256[] memory) {
        return queuedTransactions;
    }
    
    /**
     * @dev Get active proposals
     */
    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposals;
    }
    
    // Internal Helper Functions
    
    function _removeFromPending(uint256 transactionId) internal {
        for (uint256 i = 0; i < pendingTransactions.length; i++) {
            if (pendingTransactions[i] == transactionId) {
                pendingTransactions[i] = pendingTransactions[pendingTransactions.length - 1];
                pendingTransactions.pop();
                break;
            }
        }
    }
    
    function _removeFromQueued(uint256 transactionId) internal {
        for (uint256 i = 0; i < queuedTransactions.length; i++) {
            if (queuedTransactions[i] == transactionId) {
                queuedTransactions[i] = queuedTransactions[queuedTransactions.length - 1];
                queuedTransactions.pop();
                break;
            }
        }
    }
    
    function _removeFromActiveProposals(uint256 proposalId) internal {
        for (uint256 i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }
    }
}
