// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title MessageBoard
 * @dev A simple contract for posting and reading public messages
 * Features: Post messages, like messages, get message history, and user stats
 */
contract MessageBoard {
    
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        bool active;
    }
    
    // State variables
    uint256 private nextMessageId = 1;
    uint256 public totalMessages;
    uint256 public totalLikes;
    
    // Mappings
    mapping(uint256 => Message) public messages;
    mapping(address => uint256[]) public userMessages;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(address => uint256) public userMessageCount;
    mapping(address => uint256) public userTotalLikes;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, string content);
    event MessageLiked(uint256 indexed messageId, address indexed liker);
    event MessageDeleted(uint256 indexed messageId, address indexed author);
    
    /**
     * @dev Post a new message
     */
    function postMessage(string memory _content) external {
        require(bytes(_content).length > 0, "Message cannot be empty");
        require(bytes(_content).length <= 280, "Message too long (max 280 characters)");
        
        uint256 messageId = nextMessageId++;
        
        messages[messageId] = Message({
            id: messageId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            active: true
        });
        
        userMessages[msg.sender].push(messageId);
        userMessageCount[msg.sender]++;
        totalMessages++;
        
        emit MessagePosted(messageId, msg.sender, _content);
    }
    
    /**
     * @dev Like a message
     */
    function likeMessage(uint256 _messageId) external {
        require(_messageId > 0 && _messageId < nextMessageId, "Invalid message ID");
        require(messages[_messageId].active, "Message not active");
        require(!hasLiked[_messageId][msg.sender], "Already liked this message");
        require(messages[_messageId].author != msg.sender, "Cannot like your own message");
        
        messages[_messageId].likes++;
        hasLiked[_messageId][msg.sender] = true;
        userTotalLikes[messages[_messageId].author]++;
        totalLikes++;
        
        emit MessageLiked(_messageId, msg.sender);
    }
    
    /**
     * @dev Delete your own message
     */
    function deleteMessage(uint256 _messageId) external {
        require(_messageId > 0 && _messageId < nextMessageId, "Invalid message ID");
        require(messages[_messageId].author == msg.sender, "Not your message");
        require(messages[_messageId].active, "Message already deleted");
        
        messages[_messageId].active = false;
        totalMessages--;
        userMessageCount[msg.sender]--;
        
        emit MessageDeleted(_messageId, msg.sender);
    }
    
    /**
     * @dev Get a specific message
     */
    function getMessage(uint256 _messageId) external view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp,
        uint256 likes,
        bool active
    ) {
        require(_messageId > 0 && _messageId < nextMessageId, "Invalid message ID");
        Message memory message = messages[_messageId];
        return (message.id, message.author, message.content, message.timestamp, message.likes, message.active);
    }
    
    /**
     * @dev Get recent messages (last 10 active messages)
     */
    function getRecentMessages() external view returns (uint256[] memory) {
        uint256[] memory recentMessages = new uint256[](10);
        uint256 count = 0;
        
        // Start from the most recent message and work backwards
        for (uint256 i = nextMessageId - 1; i > 0 && count < 10; i--) {
            if (messages[i].active) {
                recentMessages[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = recentMessages[j];
        }
        
        return result;
    }
    
    /**
     * @dev Get user's messages
     */
    function getUserMessages(address _user) external view returns (uint256[] memory) {
        return userMessages[_user];
    }
    
    /**
     * @dev Get user stats
     */
    function getUserStats(address _user) external view returns (
        uint256 messageCount,
        uint256 totalLikesReceived
    ) {
        return (userMessageCount[_user], userTotalLikes[_user]);
    }
    
    /**
     * @dev Get platform stats
     */
    function getPlatformStats() external view returns (
        uint256 totalActiveMessages,
        uint256 totalLikesGiven,
        uint256 totalUsers
    ) {
        // Count unique users (simplified - in practice you'd track this more efficiently)
        uint256 uniqueUsers = 0;
        for (uint256 i = 1; i < nextMessageId; i++) {
            if (messages[i].active && userMessageCount[messages[i].author] > 0) {
                uniqueUsers++;
            }
        }
        
        return (totalMessages, totalLikes, uniqueUsers);
    }
    
    /**
     * @dev Check if user has liked a message
     */
    function hasUserLiked(uint256 _messageId, address _user) external view returns (bool) {
        return hasLiked[_messageId][_user];
    }
    
    /**
     * @dev Get top liked messages (simplified version)
     */
    function getTopMessages() external view returns (uint256[] memory) {
        uint256[] memory topMessages = new uint256[](5);
        uint256 count = 0;
        uint256 minLikes = 0;
        
        // Simple algorithm to find top 5 messages by likes
        for (uint256 i = 1; i < nextMessageId && count < 5; i++) {
            if (messages[i].active && messages[i].likes > minLikes) {
                // Insert in sorted order (simplified)
                topMessages[count] = i;
                count++;
                if (count == 5) {
                    minLikes = messages[topMessages[4]].likes;
                }
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = topMessages[j];
        }
        
        return result;
    }
}
