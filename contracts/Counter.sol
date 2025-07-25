// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Counter {
    // State variables
    int256 public count;
    address public owner;
    uint256 public totalInteractions;
    
    // Struct to track counter changes
    struct CounterChange {
        address user;
        int256 previousCount;
        int256 newCount;
        string action; // "increment", "decrement", "reset"
        uint256 timestamp;
    }
    
    // Array to store counter history
    CounterChange[] public history;
    
    // Mappings to track user interactions
    mapping(address => uint256) public userIncrements;
    mapping(address => uint256) public userDecrements;
    mapping(address => uint256) public userTotalInteractions;
    
    // Events
    event CounterIncremented(address indexed user, int256 previousCount, int256 newCount, uint256 timestamp);
    event CounterDecremented(address indexed user, int256 previousCount, int256 newCount, uint256 timestamp);
    event CounterReset(address indexed owner, int256 previousCount, uint256 timestamp);
    event MilestoneReached(int256 count, string milestone, uint256 timestamp);
    
    // Constructor
    constructor() {
        owner = msg.sender;
        count = 0;
        totalInteractions = 0;
    }
    
    // Modifier to check if caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Increment the counter by 1
    function increment() public {
        int256 previousCount = count;
        count++;
        totalInteractions++;
        userIncrements[msg.sender]++;
        userTotalInteractions[msg.sender]++;
        
        // Record the change in history
        history.push(CounterChange({
            user: msg.sender,
            previousCount: previousCount,
            newCount: count,
            action: "increment",
            timestamp: block.timestamp
        }));
        
        emit CounterIncremented(msg.sender, previousCount, count, block.timestamp);
        
        // Check for milestones
        _checkMilestones(count);
    }
    
    // Decrement the counter by 1
    function decrement() public {
        int256 previousCount = count;
        count--;
        totalInteractions++;
        userDecrements[msg.sender]++;
        userTotalInteractions[msg.sender]++;
        
        // Record the change in history
        history.push(CounterChange({
            user: msg.sender,
            previousCount: previousCount,
            newCount: count,
            action: "decrement",
            timestamp: block.timestamp
        }));
        
        emit CounterDecremented(msg.sender, previousCount, count, block.timestamp);
        
        // Check for milestones
        _checkMilestones(count);
    }
    
    // Increment by a custom amount
    function incrementBy(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 100, "Amount too large (max 100)");
        
        int256 previousCount = count;
        count += int256(_amount);
        totalInteractions++;
        userIncrements[msg.sender] += _amount;
        userTotalInteractions[msg.sender]++;
        
        // Record the change in history
        history.push(CounterChange({
            user: msg.sender,
            previousCount: previousCount,
            newCount: count,
            action: string(abi.encodePacked("increment_by_", _amount)),
            timestamp: block.timestamp
        }));
        
        emit CounterIncremented(msg.sender, previousCount, count, block.timestamp);
        
        // Check for milestones
        _checkMilestones(count);
    }
    
    // Decrement by a custom amount
    function decrementBy(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 100, "Amount too large (max 100)");
        
        int256 previousCount = count;
        count -= int256(_amount);
        totalInteractions++;
        userDecrements[msg.sender] += _amount;
        userTotalInteractions[msg.sender]++;
        
        // Record the change in history
        history.push(CounterChange({
            user: msg.sender,
            previousCount: previousCount,
            newCount: count,
            action: string(abi.encodePacked("decrement_by_", _amount)),
            timestamp: block.timestamp
        }));
        
        emit CounterDecremented(msg.sender, previousCount, count, block.timestamp);
        
        // Check for milestones
        _checkMilestones(count);
    }
    
    // Get current count (view function)
    function getCount() public view returns (int256) {
        return count;
    }
    
    // Get total number of changes made
    function getHistoryLength() public view returns (uint256) {
        return history.length;
    }
    
    // Get the latest N changes
    function getLatestChanges(uint256 _count) public view returns (
        address[] memory users,
        int256[] memory previousCounts,
        int256[] memory newCounts,
        string[] memory actions,
        uint256[] memory timestamps
    ) {
        uint256 length = history.length;
        uint256 count = _count;
        if (count > length) {
            count = length;
        }
        
        users = new address[](count);
        previousCounts = new int256[](count);
        newCounts = new int256[](count);
        actions = new string[](count);
        timestamps = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 index = length - 1 - i;
            CounterChange memory change = history[index];
            users[i] = change.user;
            previousCounts[i] = change.previousCount;
            newCounts[i] = change.newCount;
            actions[i] = change.action;
            timestamps[i] = change.timestamp;
        }
    }
    
    // Get user statistics
    function getUserStats(address _user) public view returns (
        uint256 increments,
        uint256 decrements,
        uint256 totalInteractions,
        int256 netContribution
    ) {
        increments = userIncrements[_user];
        decrements = userDecrements[_user];
        totalInteractions = userTotalInteractions[_user];
        netContribution = int256(increments) - int256(decrements);
    }
    
    // Get contract statistics
    function getContractStats() public view returns (
        int256 currentCount,
        uint256 totalChanges,
        uint256 totalUsers,
        address contractOwner
    ) {
        currentCount = count;
        totalChanges = totalInteractions;
        
        // Count unique users (simplified - counts all interactions)
        totalUsers = history.length > 0 ? history.length : 0;
        contractOwner = owner;
    }
    
    // Check if count is positive, negative, or zero
    function getCountStatus() public view returns (string memory) {
        if (count > 0) {
            return "positive";
        } else if (count < 0) {
            return "negative";
        } else {
            return "zero";
        }
    }
    
    // Get the user who made the last change
    function getLastUser() public view returns (address, string memory, uint256) {
        require(history.length > 0, "No changes made yet");
        CounterChange memory lastChange = history[history.length - 1];
        return (lastChange.user, lastChange.action, lastChange.timestamp);
    }
    
    // Reset counter to zero (owner only)
    function reset() public onlyOwner {
        int256 previousCount = count;
        count = 0;
        totalInteractions++;
        
        // Record the reset in history
        history.push(CounterChange({
            user: msg.sender,
            previousCount: previousCount,
            newCount: 0,
            action: "reset",
            timestamp: block.timestamp
        }));
        
        emit CounterReset(msg.sender, previousCount, block.timestamp);
    }
    
    // Transfer ownership
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
    
    // Internal function to check for milestones
    function _checkMilestones(int256 _count) internal {
        if (_count == 10) {
            emit MilestoneReached(_count, "First 10!", block.timestamp);
        } else if (_count == 100) {
            emit MilestoneReached(_count, "Century!", block.timestamp);
        } else if (_count == 1000) {
            emit MilestoneReached(_count, "Thousand!", block.timestamp);
        } else if (_count == -10) {
            emit MilestoneReached(_count, "Negative 10!", block.timestamp);
        } else if (_count == -100) {
            emit MilestoneReached(_count, "Negative Century!", block.timestamp);
        } else if (_count == 0 && history.length > 1) {
            emit MilestoneReached(_count, "Back to Zero!", block.timestamp);
        }
    }
}
