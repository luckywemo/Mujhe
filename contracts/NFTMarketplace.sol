// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title NFTMarketplace
 * @dev A comprehensive NFT marketplace with royalties, auctions, and collection management
 * @author CELO Developer
 */
contract NFTMarketplace is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, Pausable {
    // Structs
    struct NFTItem {
        uint256 tokenId;
        address creator;
        address owner;
        uint256 price;
        bool isForSale;
        uint256 royaltyPercentage; // Basis points (e.g., 250 = 2.5%)
        uint256 createdAt;
        string category;
        uint256 collectionId;
    }
    
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 currentBid;
        address currentBidder;
        uint256 endTime;
        bool active;
        bool ended;
    }
    
    struct Collection {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256[] tokenIds;
        uint256 createdAt;
        bool verified;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }
    
    // State variables
    uint256 private _tokenIdCounter;
    uint256 private _collectionIdCounter;
    uint256 public marketplaceFee = 250; // 2.5% in basis points
    uint256 public constant MAX_ROYALTY = 1000; // 10% max royalty
    uint256 public constant BASIS_POINTS = 10000;
    
    // Mappings
    mapping(uint256 => NFTItem) public nftItems;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Collection) public collections;
    mapping(uint256 => Bid[]) public auctionBids;
    mapping(address => uint256[]) public userNFTs;
    mapping(address => uint256[]) public userCollections;
    mapping(string => uint256[]) public categoryNFTs;
    mapping(address => uint256) public pendingWithdrawals;
    
    // Arrays
    uint256[] public allNFTs;
    uint256[] public nftsForSale;
    uint256[] public activeAuctions;
    string[] public categories;
    
    // Events
    event NFTMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string tokenURI,
        uint256 royaltyPercentage,
        string category,
        uint256 collectionId
    );
    
    event NFTListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    
    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );
    
    event AuctionCreated(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 endTime
    );
    
    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 amount
    );
    
    event AuctionEnded(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );
    
    event CollectionCreated(
        uint256 indexed collectionId,
        address indexed creator,
        string name
    );
    
    event RoyaltyPaid(
        uint256 indexed tokenId,
        address indexed creator,
        uint256 amount
    );
    
    // Modifiers
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        _;
    }
    
    modifier tokenExists(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _;
    }
    
    modifier auctionActive(uint256 tokenId) {
        require(auctions[tokenId].active, "Auction not active");
        require(block.timestamp < auctions[tokenId].endTime, "Auction ended");
        _;
    }
    
    // Constructor
    constructor() ERC721("NFTMarketplace", "NFTM") Ownable(msg.sender) {
        _tokenIdCounter = 1;
        _collectionIdCounter = 1;
        
        // Initialize default categories
        categories.push("Art");
        categories.push("Music");
        categories.push("Photography");
        categories.push("Gaming");
        categories.push("Collectibles");
        categories.push("Utility");
    }
    
    // Core NFT Functions
    
    /**
     * @dev Mint a new NFT
     */
    function mintNFT(
        string memory _tokenURI,
        uint256 royaltyPercentage,
        string memory category,
        uint256 collectionId
    ) public whenNotPaused returns (uint256) {
        require(royaltyPercentage <= MAX_ROYALTY, "Royalty too high");
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");
        
        // Validate collection if specified
        if (collectionId > 0) {
            require(collectionId < _collectionIdCounter, "Collection does not exist");
            require(collections[collectionId].creator == msg.sender, "Not collection creator");
        }
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        
        // Create NFT item
        nftItems[tokenId] = NFTItem({
            tokenId: tokenId,
            creator: msg.sender,
            owner: msg.sender,
            price: 0,
            isForSale: false,
            royaltyPercentage: royaltyPercentage,
            createdAt: block.timestamp,
            category: category,
            collectionId: collectionId
        });
        
        // Update mappings
        allNFTs.push(tokenId);
        userNFTs[msg.sender].push(tokenId);
        categoryNFTs[category].push(tokenId);
        
        // Add to collection if specified
        if (collectionId > 0) {
            collections[collectionId].tokenIds.push(tokenId);
        }
        
        emit NFTMinted(tokenId, msg.sender, _tokenURI, royaltyPercentage, category, collectionId);
        
        return tokenId;
    }
    
    /**
     * @dev List NFT for sale
     */
    function listNFT(uint256 tokenId, uint256 price) 
        public 
        onlyTokenOwner(tokenId) 
        tokenExists(tokenId) 
        whenNotPaused 
    {
        require(price > 0, "Price must be greater than 0");
        require(!nftItems[tokenId].isForSale, "NFT already listed");
        require(!auctions[tokenId].active, "NFT is in auction");
        
        nftItems[tokenId].price = price;
        nftItems[tokenId].isForSale = true;
        
        nftsForSale.push(tokenId);
        
        emit NFTListed(tokenId, msg.sender, price);
    }
    
    /**
     * @dev Remove NFT from sale
     */
    function unlistNFT(uint256 tokenId) 
        public 
        onlyTokenOwner(tokenId) 
        tokenExists(tokenId) 
    {
        require(nftItems[tokenId].isForSale, "NFT not for sale");
        
        nftItems[tokenId].isForSale = false;
        nftItems[tokenId].price = 0;
        
        _removeFromForSale(tokenId);
        
        emit NFTListed(tokenId, msg.sender, 0);
    }
    
    /**
     * @dev Buy NFT directly
     */
    function buyNFT(uint256 tokenId) 
        public 
        payable 
        tokenExists(tokenId) 
        nonReentrant 
        whenNotPaused 
    {
        NFTItem storage item = nftItems[tokenId];
        require(item.isForSale, "NFT not for sale");
        require(msg.value >= item.price, "Insufficient payment");
        require(msg.sender != item.owner, "Cannot buy your own NFT");
        
        address seller = item.owner;
        uint256 price = item.price;
        
        // Calculate fees
        uint256 marketplaceFeeAmount = (price * marketplaceFee) / BASIS_POINTS;
        uint256 royaltyAmount = (price * item.royaltyPercentage) / BASIS_POINTS;
        uint256 sellerAmount = price - marketplaceFeeAmount - royaltyAmount;
        
        // Update NFT item
        item.owner = msg.sender;
        item.isForSale = false;
        item.price = 0;
        
        // Transfer NFT
        _transfer(seller, msg.sender, tokenId);
        
        // Update user NFTs
        _removeFromUserNFTs(seller, tokenId);
        userNFTs[msg.sender].push(tokenId);
        
        // Remove from sale list
        _removeFromForSale(tokenId);
        
        // Handle payments
        pendingWithdrawals[seller] += sellerAmount;
        pendingWithdrawals[owner()] += marketplaceFeeAmount;
        
        if (royaltyAmount > 0) {
            pendingWithdrawals[item.creator] += royaltyAmount;
            emit RoyaltyPaid(tokenId, item.creator, royaltyAmount);
        }
        
        // Refund excess payment
        if (msg.value > price) {
            pendingWithdrawals[msg.sender] += (msg.value - price);
        }
        
        emit NFTSold(tokenId, seller, msg.sender, price, royaltyAmount, marketplaceFeeAmount);
    }
    
    // Auction Functions
    
    /**
     * @dev Create an auction for NFT
     */
    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) public onlyTokenOwner(tokenId) tokenExists(tokenId) whenNotPaused {
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(duration >= 1 hours, "Auction duration too short");
        require(duration <= 30 days, "Auction duration too long");
        require(!nftItems[tokenId].isForSale, "NFT is listed for sale");
        require(!auctions[tokenId].active, "Auction already active");
        
        uint256 endTime = block.timestamp + duration;
        
        auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: msg.sender,
            startingPrice: startingPrice,
            currentBid: 0,
            currentBidder: address(0),
            endTime: endTime,
            active: true,
            ended: false
        });
        
        activeAuctions.push(tokenId);
        
        emit AuctionCreated(tokenId, msg.sender, startingPrice, endTime);
    }
    
    /**
     * @dev Place a bid on an auction
     */
    function placeBid(uint256 tokenId) 
        public 
        payable 
        auctionActive(tokenId) 
        nonReentrant 
        whenNotPaused 
    {
        Auction storage auction = auctions[tokenId];
        require(msg.sender != auction.seller, "Cannot bid on your own auction");
        require(msg.value > auction.currentBid, "Bid too low");
        require(msg.value >= auction.startingPrice, "Bid below starting price");
        
        // Refund previous bidder
        if (auction.currentBidder != address(0)) {
            pendingWithdrawals[auction.currentBidder] += auction.currentBid;
        }
        
        // Update auction
        auction.currentBid = msg.value;
        auction.currentBidder = msg.sender;
        
        // Record bid
        auctionBids[tokenId].push(Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }
    
    /**
     * @dev End an auction
     */
    function endAuction(uint256 tokenId) public nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction still ongoing");
        require(!auction.ended, "Auction already ended");
        
        auction.active = false;
        auction.ended = true;
        
        _removeFromActiveAuctions(tokenId);
        
        if (auction.currentBidder != address(0)) {
            // Transfer NFT to winner
            address seller = auction.seller;
            address winner = auction.currentBidder;
            uint256 winningBid = auction.currentBid;
            
            NFTItem storage item = nftItems[tokenId];
            
            // Calculate fees
            uint256 marketplaceFeeAmount = (winningBid * marketplaceFee) / BASIS_POINTS;
            uint256 royaltyAmount = (winningBid * item.royaltyPercentage) / BASIS_POINTS;
            uint256 sellerAmount = winningBid - marketplaceFeeAmount - royaltyAmount;
            
            // Update NFT item
            item.owner = winner;
            
            // Transfer NFT
            _transfer(seller, winner, tokenId);
            
            // Update user NFTs
            _removeFromUserNFTs(seller, tokenId);
            userNFTs[winner].push(tokenId);
            
            // Handle payments
            pendingWithdrawals[seller] += sellerAmount;
            pendingWithdrawals[owner()] += marketplaceFeeAmount;
            
            if (royaltyAmount > 0) {
                pendingWithdrawals[item.creator] += royaltyAmount;
                emit RoyaltyPaid(tokenId, item.creator, royaltyAmount);
            }
            
            emit AuctionEnded(tokenId, winner, winningBid);
        } else {
            emit AuctionEnded(tokenId, address(0), 0);
        }
    }
    
    // Collection Functions
    
    /**
     * @dev Create a new collection
     */
    function createCollection(
        string memory name,
        string memory description
    ) public whenNotPaused returns (uint256) {
        require(bytes(name).length > 0, "Collection name cannot be empty");
        require(bytes(name).length <= 100, "Collection name too long");
        require(bytes(description).length <= 500, "Description too long");
        
        uint256 collectionId = _collectionIdCounter;
        _collectionIdCounter++;
        
        uint256[] memory emptyTokenIds;
        
        collections[collectionId] = Collection({
            id: collectionId,
            name: name,
            description: description,
            creator: msg.sender,
            tokenIds: emptyTokenIds,
            createdAt: block.timestamp,
            verified: false
        });
        
        userCollections[msg.sender].push(collectionId);
        
        emit CollectionCreated(collectionId, msg.sender, name);
        
        return collectionId;
    }
    
    // Withdrawal Functions
    
    /**
     * @dev Withdraw pending payments
     */
    function withdraw() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingWithdrawals[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    // View Functions
    
    /**
     * @dev Get NFT details
     */
    function getNFT(uint256 tokenId) public view tokenExists(tokenId) returns (
        uint256 id,
        address creator,
        address owner,
        uint256 price,
        bool isForSale,
        uint256 royaltyPercentage,
        uint256 createdAt,
        string memory category,
        uint256 collectionId,
        string memory uri
    ) {
        NFTItem storage item = nftItems[tokenId];
        return (
            item.tokenId,
            item.creator,
            item.owner,
            item.price,
            item.isForSale,
            item.royaltyPercentage,
            item.createdAt,
            item.category,
            item.collectionId,
            super.tokenURI(tokenId)
        );
    }
    
    /**
     * @dev Get auction details
     */
    function getAuction(uint256 tokenId) public view returns (
        uint256 id,
        address seller,
        uint256 startingPrice,
        uint256 currentBid,
        address currentBidder,
        uint256 endTime,
        bool active,
        bool ended
    ) {
        Auction memory auction = auctions[tokenId];
        return (
            auction.tokenId,
            auction.seller,
            auction.startingPrice,
            auction.currentBid,
            auction.currentBidder,
            auction.endTime,
            auction.active,
            auction.ended
        );
    }
    
    /**
     * @dev Get collection details
     */
    function getCollection(uint256 collectionId) public view returns (
        uint256 id,
        string memory name,
        string memory description,
        address creator,
        uint256[] memory tokenIds,
        uint256 createdAt,
        bool verified
    ) {
        Collection memory collection = collections[collectionId];
        return (
            collection.id,
            collection.name,
            collection.description,
            collection.creator,
            collection.tokenIds,
            collection.createdAt,
            collection.verified
        );
    }
    
    /**
     * @dev Get NFTs for sale
     */
    function getNFTsForSale() public view returns (uint256[] memory) {
        return nftsForSale;
    }
    
    /**
     * @dev Get active auctions
     */
    function getActiveAuctions() public view returns (uint256[] memory) {
        return activeAuctions;
    }
    
    /**
     * @dev Get user's NFTs
     */
    function getUserNFTs(address user) public view returns (uint256[] memory) {
        return userNFTs[user];
    }
    
    /**
     * @dev Get user's collections
     */
    function getUserCollections(address user) public view returns (uint256[] memory) {
        return userCollections[user];
    }
    
    /**
     * @dev Get NFTs by category
     */
    function getNFTsByCategory(string memory category) public view returns (uint256[] memory) {
        return categoryNFTs[category];
    }
    
    /**
     * @dev Get auction bids
     */
    function getAuctionBids(uint256 tokenId) public view returns (Bid[] memory) {
        return auctionBids[tokenId];
    }
    
    /**
     * @dev Get marketplace statistics
     */
    function getMarketplaceStats() public view returns (
        uint256 totalNFTs,
        uint256 nftsForSaleCount,
        uint256 activeAuctionsCount,
        uint256 totalCollections,
        uint256 marketplaceFeeRate
    ) {
        return (
            allNFTs.length,
            nftsForSale.length,
            activeAuctions.length,
            _collectionIdCounter - 1,
            marketplaceFee
        );
    }
    
    // Admin Functions
    
    /**
     * @dev Set marketplace fee (only owner)
     */
    function setMarketplaceFee(uint256 newFee) public onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        marketplaceFee = newFee;
    }
    
    /**
     * @dev Verify collection (only owner)
     */
    function verifyCollection(uint256 collectionId) public onlyOwner {
        require(collectionId < _collectionIdCounter, "Collection does not exist");
        collections[collectionId].verified = true;
    }
    
    /**
     * @dev Add category (only owner)
     */
    function addCategory(string memory category) public onlyOwner {
        categories.push(category);
    }
    
    /**
     * @dev Pause contract (only owner)
     */
    function pause() public onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract (only owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // Internal Functions
    
    function _removeFromForSale(uint256 tokenId) internal {
        for (uint256 i = 0; i < nftsForSale.length; i++) {
            if (nftsForSale[i] == tokenId) {
                nftsForSale[i] = nftsForSale[nftsForSale.length - 1];
                nftsForSale.pop();
                break;
            }
        }
    }
    
    function _removeFromActiveAuctions(uint256 tokenId) internal {
        for (uint256 i = 0; i < activeAuctions.length; i++) {
            if (activeAuctions[i] == tokenId) {
                activeAuctions[i] = activeAuctions[activeAuctions.length - 1];
                activeAuctions.pop();
                break;
            }
        }
    }
    
    function _removeFromUserNFTs(address user, uint256 tokenId) internal {
        uint256[] storage userTokens = userNFTs[user];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
    }
    
    // Override required functions
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
