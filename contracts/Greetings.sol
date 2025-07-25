// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Greetings {
    // State variables
    string public defaultGreeting;
    address public owner;
    uint256 public totalGreetings;
    
    // Mapping to store personal greetings for each address
    mapping(address => string) public personalGreetings;
    mapping(address => uint256) public greetingCount;
    mapping(address => bool) public hasGreeting;
    
    // Array to keep track of all addresses that have set greetings
    address[] public greeters;
    
    // Events
    event GreetingSet(address indexed user, string greeting, uint256 timestamp);
    event GreetingUpdated(address indexed user, string oldGreeting, string newGreeting, uint256 timestamp);
    event DefaultGreetingChanged(string oldDefault, string newDefault, uint256 timestamp);
    
    // Constructor
    constructor() {
        owner = msg.sender;
        defaultGreeting = "Hello from CELO blockchain!";
        totalGreetings = 0;
    }
    
    // Modifier to check if caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Set a personal greeting
    function setGreeting(string memory _greeting) public {
        require(bytes(_greeting).length > 0, "Greeting cannot be empty");
        require(bytes(_greeting).length <= 280, "Greeting too long (max 280 characters)");
        
        string memory oldGreeting = personalGreetings[msg.sender];
        bool hadGreeting = hasGreeting[msg.sender];
        
        personalGreetings[msg.sender] = _greeting;
        
        if (!hadGreeting) {
            hasGreeting[msg.sender] = true;
            greeters.push(msg.sender);
            totalGreetings++;
            emit GreetingSet(msg.sender, _greeting, block.timestamp);
        } else {
            emit GreetingUpdated(msg.sender, oldGreeting, _greeting, block.timestamp);
        }
        
        greetingCount[msg.sender]++;
    }
    
    // Get greeting for a specific address
    function getGreeting(address _user) public view returns (string memory) {
        if (hasGreeting[_user]) {
            return personalGreetings[_user];
        } else {
            return defaultGreeting;
        }
    }
    
    // Get your own greeting
    function getMyGreeting() public view returns (string memory) {
        return getGreeting(msg.sender);
    }
    
    // Get all greeters (addresses that have set greetings)
    function getAllGreeters() public view returns (address[] memory) {
        return greeters;
    }
    
    // Get the latest N greetings
    function getLatestGreetings(uint256 _count) public view returns (address[] memory, string[] memory) {
        uint256 count = _count;
        if (count > greeters.length) {
            count = greeters.length;
        }
        
        address[] memory latestAddresses = new address[](count);
        string[] memory latestGreetings = new string[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 index = greeters.length - 1 - i;
            latestAddresses[i] = greeters[index];
            latestGreetings[i] = personalGreetings[greeters[index]];
        }
        
        return (latestAddresses, latestGreetings);
    }
    
    // Check if an address has set a greeting
    function hasSetGreeting(address _user) public view returns (bool) {
        return hasGreeting[_user];
    }
    
    // Get greeting statistics for an address
    function getGreetingStats(address _user) public view returns (bool hasSet, uint256 updateCount, string memory currentGreeting) {
        hasSet = hasGreeting[_user];
        updateCount = greetingCount[_user];
        currentGreeting = hasSet ? personalGreetings[_user] : defaultGreeting;
    }
    
    // Owner functions
    function setDefaultGreeting(string memory _newDefault) public onlyOwner {
        require(bytes(_newDefault).length > 0, "Default greeting cannot be empty");
        
        string memory oldDefault = defaultGreeting;
        defaultGreeting = _newDefault;
        
        emit DefaultGreetingChanged(oldDefault, _newDefault, block.timestamp);
    }
    
    // Get contract statistics
    function getContractStats() public view returns (
        uint256 totalUsers,
        uint256 totalUpdates,
        string memory currentDefault,
        address contractOwner
    ) {
        totalUsers = totalGreetings;
        
        uint256 updates = 0;
        for (uint256 i = 0; i < greeters.length; i++) {
            updates += greetingCount[greeters[i]];
        }
        totalUpdates = updates;
        
        currentDefault = defaultGreeting;
        contractOwner = owner;
    }
    
    // Fun function: Get a random greeting (pseudo-random)
    function getRandomGreeting() public view returns (address greeter, string memory greeting) {
        require(greeters.length > 0, "No greetings available");
        
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % greeters.length;
        greeter = greeters[randomIndex];
        greeting = personalGreetings[greeter];
    }
    
    // Emergency function to transfer ownership
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
}
