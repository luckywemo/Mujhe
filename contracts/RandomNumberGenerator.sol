// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title RandomNumberGenerator
 * @dev A simple contract for generating verifiable random numbers
 * Features: Generate random numbers, track history, different ranges, and statistics
 */
contract RandomNumberGenerator {
    
    struct RandomRequest {
        uint256 id;
        address requester;
        uint256 randomNumber;
        uint256 minRange;
        uint256 maxRange;
        uint256 timestamp;
        bytes32 seed;
    }
    
    // State variables
    uint256 private nextRequestId = 1;
    uint256 public totalRequests;
    uint256 private nonce;
    
    // Mappings
    mapping(uint256 => RandomRequest) public randomRequests;
    mapping(address => uint256[]) public userRequests;
    mapping(address => uint256) public userRequestCount;
    
    // Events
    event RandomNumberGenerated(
        uint256 indexed requestId,
        address indexed requester,
        uint256 randomNumber,
        uint256 minRange,
        uint256 maxRange
    );
    event SeedUpdated(bytes32 newSeed);
    
    constructor() {
        // Initialize with a pseudo-random seed
        nonce = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
    }
    
    /**
     * @dev Generate a random number between 1 and 100
     */
    function generateRandom() external returns (uint256) {
        return _generateRandomInRange(1, 100);
    }
    
    /**
     * @dev Generate a random number in a specific range
     */
    function generateRandomInRange(uint256 _min, uint256 _max) external returns (uint256) {
        require(_min < _max, "Invalid range: min must be less than max");
        require(_max - _min <= 10000, "Range too large (max 10000)");
        
        return _generateRandomInRange(_min, _max);
    }
    
    /**
     * @dev Generate a random dice roll (1-6)
     */
    function rollDice() external returns (uint256) {
        return _generateRandomInRange(1, 6);
    }
    
    /**
     * @dev Generate a random coin flip (0 = Tails, 1 = Heads)
     */
    function flipCoin() external returns (uint256) {
        return _generateRandomInRange(0, 1);
    }
    
    /**
     * @dev Generate multiple random numbers at once
     */
    function generateMultipleRandom(uint256 _count, uint256 _min, uint256 _max) 
        external 
        returns (uint256[] memory) 
    {
        require(_count > 0 && _count <= 10, "Count must be between 1 and 10");
        require(_min < _max, "Invalid range: min must be less than max");
        require(_max - _min <= 1000, "Range too large for multiple generation");
        
        uint256[] memory numbers = new uint256[](_count);
        
        for (uint256 i = 0; i < _count; i++) {
            numbers[i] = _generateRandomInRange(_min, _max);
        }
        
        return numbers;
    }
    
    /**
     * @dev Internal function to generate random number in range
     */
    function _generateRandomInRange(uint256 _min, uint256 _max) internal returns (uint256) {
        // Increment nonce for uniqueness
        nonce++;
        
        // Create seed from multiple sources of entropy
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            nonce,
            blockhash(block.number - 1)
        ));
        
        // Generate random number in range
        uint256 randomNumber = _min + (uint256(seed) % (_max - _min + 1));
        
        // Store request
        uint256 requestId = nextRequestId++;
        randomRequests[requestId] = RandomRequest({
            id: requestId,
            requester: msg.sender,
            randomNumber: randomNumber,
            minRange: _min,
            maxRange: _max,
            timestamp: block.timestamp,
            seed: seed
        });
        
        userRequests[msg.sender].push(requestId);
        userRequestCount[msg.sender]++;
        totalRequests++;
        
        emit RandomNumberGenerated(requestId, msg.sender, randomNumber, _min, _max);
        
        return randomNumber;
    }
    
    /**
     * @dev Get a specific random request
     */
    function getRandomRequest(uint256 _requestId) external view returns (
        uint256 id,
        address requester,
        uint256 randomNumber,
        uint256 minRange,
        uint256 maxRange,
        uint256 timestamp,
        bytes32 seed
    ) {
        require(_requestId > 0 && _requestId < nextRequestId, "Invalid request ID");
        RandomRequest memory request = randomRequests[_requestId];
        return (
            request.id,
            request.requester,
            request.randomNumber,
            request.minRange,
            request.maxRange,
            request.timestamp,
            request.seed
        );
    }
    
    /**
     * @dev Get user's random number history
     */
    function getUserRequests(address _user) external view returns (uint256[] memory) {
        return userRequests[_user];
    }
    
    /**
     * @dev Get recent random numbers (last 10)
     */
    function getRecentNumbers() external view returns (uint256[] memory) {
        uint256 count = totalRequests < 10 ? totalRequests : 10;
        uint256[] memory recentNumbers = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            uint256 requestId = nextRequestId - 1 - i;
            recentNumbers[i] = randomRequests[requestId].randomNumber;
        }
        
        return recentNumbers;
    }
    
    /**
     * @dev Get user statistics
     */
    function getUserStats(address _user) external view returns (
        uint256 totalRequests,
        uint256 averageNumber,
        uint256 highestNumber,
        uint256 lowestNumber
    ) {
        uint256[] memory userRequestIds = userRequests[_user];
        if (userRequestIds.length == 0) {
            return (0, 0, 0, 0);
        }
        
        uint256 sum = 0;
        uint256 highest = 0;
        uint256 lowest = type(uint256).max;
        
        for (uint256 i = 0; i < userRequestIds.length; i++) {
            uint256 number = randomRequests[userRequestIds[i]].randomNumber;
            sum += number;
            
            if (number > highest) {
                highest = number;
            }
            if (number < lowest) {
                lowest = number;
            }
        }
        
        uint256 average = sum / userRequestIds.length;
        
        return (userRequestIds.length, average, highest, lowest);
    }
    
    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() external view returns (
        uint256 totalRandomNumbers,
        uint256 totalUsers,
        uint256 averageRequestsPerUser
    ) {
        // Count unique users (simplified)
        uint256 uniqueUsers = 0;
        for (uint256 i = 1; i < nextRequestId; i++) {
            if (userRequestCount[randomRequests[i].requester] > 0) {
                uniqueUsers++;
            }
        }
        
        uint256 avgRequests = uniqueUsers > 0 ? totalRequests / uniqueUsers : 0;
        
        return (totalRequests, uniqueUsers, avgRequests);
    }
    
    /**
     * @dev Verify a random number was generated correctly
     */
    function verifyRandomNumber(uint256 _requestId) external view returns (bool) {
        require(_requestId > 0 && _requestId < nextRequestId, "Invalid request ID");
        
        RandomRequest memory request = randomRequests[_requestId];
        
        // Recalculate what the random number should be with the stored seed
        uint256 expectedNumber = request.minRange + 
            (uint256(request.seed) % (request.maxRange - request.minRange + 1));
        
        return expectedNumber == request.randomNumber;
    }
    
    /**
     * @dev Get distribution analysis for a range (simplified)
     */
    function getDistributionAnalysis(uint256 _min, uint256 _max) external view returns (
        uint256[] memory numbers,
        uint256[] memory counts
    ) {
        require(_min < _max, "Invalid range");
        require(_max - _min <= 100, "Range too large for analysis");
        
        uint256 rangeSize = _max - _min + 1;
        uint256[] memory numberCounts = new uint256[](rangeSize);
        uint256[] memory rangeNumbers = new uint256[](rangeSize);
        
        // Initialize range numbers
        for (uint256 i = 0; i < rangeSize; i++) {
            rangeNumbers[i] = _min + i;
        }
        
        // Count occurrences
        for (uint256 i = 1; i < nextRequestId; i++) {
            RandomRequest memory request = randomRequests[i];
            if (request.minRange == _min && request.maxRange == _max) {
                uint256 index = request.randomNumber - _min;
                if (index < rangeSize) {
                    numberCounts[index]++;
                }
            }
        }
        
        return (rangeNumbers, numberCounts);
    }
    
    /**
     * @dev Generate a random lottery number (6 numbers between 1-49)
     */
    function generateLotteryNumbers() external returns (uint256[] memory) {
        uint256[] memory lotteryNumbers = new uint256[](6);
        bool[] memory used = new bool[](49);
        
        for (uint256 i = 0; i < 6; i++) {
            uint256 randomNum;
            do {
                randomNum = _generateRandomInRange(1, 49);
            } while (used[randomNum - 1]);
            
            used[randomNum - 1] = true;
            lotteryNumbers[i] = randomNum;
        }
        
        // Sort the numbers (simple bubble sort for small array)
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = i + 1; j < 6; j++) {
                if (lotteryNumbers[i] > lotteryNumbers[j]) {
                    uint256 temp = lotteryNumbers[i];
                    lotteryNumbers[i] = lotteryNumbers[j];
                    lotteryNumbers[j] = temp;
                }
            }
        }
        
        return lotteryNumbers;
    }
    
    /**
     * @dev Get the current nonce (for transparency)
     */
    function getCurrentNonce() external view returns (uint256) {
        return nonce;
    }
    
    /**
     * @dev Get total number of requests
     */
    function getTotalRequests() external view returns (uint256) {
        return totalRequests;
    }
}
