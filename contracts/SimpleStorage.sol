// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SimpleStorage {
    // State variables
    uint256 private favoriteNumber;
    string private message;
    address public owner;
    
    // Mapping to store favorite numbers for different addresses
    mapping(address => uint256) public addressToFavoriteNumber;
    mapping(address => string) public addressToMessage;
    
    // Events
    event NumberUpdated(address indexed user, uint256 newNumber);
    event MessageUpdated(address indexed user, string newMessage);
    
    // Constructor
    constructor() {
        owner = msg.sender;
        favoriteNumber = 42; // Default favorite number
        message = "Hello CELO!"; // Default message
    }
    
    // Store a favorite number
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        addressToFavoriteNumber[msg.sender] = _favoriteNumber;
        emit NumberUpdated(msg.sender, _favoriteNumber);
    }
    
    // Retrieve the stored favorite number
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
    
    // Store a message
    function setMessage(string memory _message) public {
        message = _message;
        addressToMessage[msg.sender] = _message;
        emit MessageUpdated(msg.sender, _message);
    }
    
    // Retrieve the stored message
    function getMessage() public view returns (string memory) {
        return message;
    }
    
    // Get favorite number for a specific address
    function getFavoriteNumber(address _address) public view returns (uint256) {
        return addressToFavoriteNumber[_address];
    }
    
    // Get message for a specific address
    function getAddressMessage(address _address) public view returns (string memory) {
        return addressToMessage[_address];
    }
    
    // Add a number to the current favorite number
    function addToFavoriteNumber(uint256 _numberToAdd) public {
        favoriteNumber += _numberToAdd;
        addressToFavoriteNumber[msg.sender] = favoriteNumber;
        emit NumberUpdated(msg.sender, favoriteNumber);
    }
    
    // Reset to default values (only owner)
    function reset() public {
        require(msg.sender == owner, "Only owner can reset");
        favoriteNumber = 42;
        message = "Hello CELO!";
        emit NumberUpdated(msg.sender, favoriteNumber);
        emit MessageUpdated(msg.sender, message);
    }
}
