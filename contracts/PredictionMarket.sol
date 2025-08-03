// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OutcomeToken.sol";

/**
 * @title PredictionMarket
 * @dev A factory contract for creating and managing decentralized prediction markets.
 * Users can bet on the outcomes of future events by buying and selling outcome tokens.
 */
contract PredictionMarket is Ownable, ReentrancyGuard {

    // --- Structs ---

    struct Market {
        uint256 id;
        string question;
        address resolver;
        uint256 resolutionTimestamp;
        bool isResolved;
        uint8 winningOutcome; // 0 = NO, 1 = YES, 2 = INVALID
        address yesToken;
        address noToken;
        uint256 liquidityPool; // Total CELO in the market
    }

    // --- State Variables ---

    uint256 public marketCounter;
    mapping(uint256 => Market) public markets;

    uint256 public platformFeeBps; // Fee in basis points (e.g., 100 bps = 1%)
    uint256 public accumulatedFees;

    // --- Events ---

    event MarketCreated(uint256 indexed marketId, string question, address indexed resolver, uint256 resolutionTimestamp);
    event SharesBought(uint256 indexed marketId, address indexed user, uint256 amount, uint256 celoAmount);
    event SharesSold(uint256 indexed marketId, address indexed user, uint256 amount, uint256 celoAmount);
    event MarketResolved(uint256 indexed marketId, uint8 winningOutcome);
    event WinningsRedeemed(uint256 indexed marketId, address indexed user, uint256 amount, uint256 payout);

    // --- Constructor ---

    constructor(address initialOwner, uint256 _initialFeeBps) Ownable(initialOwner) {
        require(_initialFeeBps <= 500, "Fee cannot exceed 5%"); // Max fee 5%
        platformFeeBps = _initialFeeBps;
    }

    // --- Market Creation ---

    /**
     * @notice Creates a new prediction market.
     * @param _question The question of the market (e.g., "Will X happen by date Y?").
     * @param _resolver The address authorized to resolve the market.
     * @param _resolutionTimestamp The timestamp after which the market can be resolved.
     */
    function createMarket(string memory _question, address _resolver, uint256 _resolutionTimestamp) external {
        require(_resolutionTimestamp > block.timestamp, "Resolution time must be in the future");
        require(_resolver != address(0), "Resolver cannot be zero address");

        marketCounter++;
        uint256 newMarketId = marketCounter;

        // Create YES and NO outcome tokens
        string memory yesName = string.concat("Market #", _toString(newMarketId), " - YES");
        string memory yesSymbol = string.concat("M", _toString(newMarketId), "Y");
        OutcomeToken yesToken = new OutcomeToken(yesName, yesSymbol, address(this));

        string memory noName = string.concat("Market #", _toString(newMarketId), " - NO");
        string memory noSymbol = string.concat("M", _toString(newMarketId), "N");
        OutcomeToken noToken = new OutcomeToken(noName, noSymbol, address(this));

        markets[newMarketId] = Market({
            id: newMarketId,
            question: _question,
            resolver: _resolver,
            resolutionTimestamp: _resolutionTimestamp,
            isResolved: false,
            winningOutcome: 0,
            yesToken: address(yesToken),
            noToken: address(noToken),
            liquidityPool: 0
        });

        emit MarketCreated(newMarketId, _question, _resolver, _resolutionTimestamp);
    }

    // --- Trading Functions ---

    /**
     * @notice Buy a set of outcome shares (1 YES + 1 NO) for 1 CELO each.
     * @param _marketId The ID of the market to buy shares from.
     */
    function buyShares(uint256 _marketId) external payable nonReentrant {
        Market storage market = markets[_marketId];
        require(market.id != 0, "Market does not exist");
        require(!market.isResolved, "Market is already resolved");
        require(msg.value > 0, "Must send CELO to buy shares");

        uint256 sharesToMint = msg.value; // 1 CELO = 1 share set

        market.liquidityPool += msg.value;
        OutcomeToken(market.yesToken).mint(msg.sender, sharesToMint);
        OutcomeToken(market.noToken).mint(msg.sender, sharesToMint);

        emit SharesBought(_marketId, msg.sender, sharesToMint, msg.value);
    }

    /**
     * @notice Sell a set of outcome shares back to the market.
     * @param _marketId The ID of the market.
     * @param _amount The number of share sets to sell.
     */
    function sellShares(uint256 _marketId, uint256 _amount) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.id != 0, "Market does not exist");
        require(!market.isResolved, "Market is already resolved");
        require(_amount > 0, "Amount must be greater than zero");

        OutcomeToken yesToken = OutcomeToken(market.yesToken);
        OutcomeToken noToken = OutcomeToken(market.noToken);

        require(yesToken.balanceOf(msg.sender) >= _amount, "Insufficient YES tokens");
        require(noToken.balanceOf(msg.sender) >= _amount, "Insufficient NO tokens");

        market.liquidityPool -= _amount;
        yesToken.burn(msg.sender, _amount);
        noToken.burn(msg.sender, _amount);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit SharesSold(_marketId, msg.sender, _amount, _amount);
    }

    // --- Resolution and Redemption ---

    /**
     * @notice Resolves a market with the final outcome.
     * @param _marketId The ID of the market to resolve.
     * @param _winningOutcome The outcome (0 for NO, 1 for YES, 2 for INVALID).
     */
    function resolveMarket(uint256 _marketId, uint8 _winningOutcome) external {
        Market storage market = markets[_marketId];
        require(market.id != 0, "Market does not exist");
        require(msg.sender == market.resolver, "Only resolver can call");
        require(block.timestamp >= market.resolutionTimestamp, "Market not yet ready for resolution");
        require(!market.isResolved, "Market already resolved");
        require(_winningOutcome <= 2, "Invalid outcome");

        market.isResolved = true;
        market.winningOutcome = _winningOutcome;

        emit MarketResolved(_marketId, _winningOutcome);
    }

    /**
     * @notice Redeem winning shares for CELO.
     * @param _marketId The ID of the resolved market.
     */
    function redeemWinnings(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.id != 0, "Market does not exist");
        require(market.isResolved, "Market must be resolved");

        address winningTokenAddress;
        if (market.winningOutcome == 1) {
            winningTokenAddress = market.yesToken;
        } else if (market.winningOutcome == 0) {
            winningTokenAddress = market.noToken;
        } else { // Market is invalid
            // If invalid, everyone can redeem both tokens for their original value
            // This logic is simplified here. A full implementation might handle this differently.
            revert("Market resolved as invalid; use a separate refund function");
        }

        OutcomeToken winningToken = OutcomeToken(winningTokenAddress);
        uint256 userBalance = winningToken.balanceOf(msg.sender);
        require(userBalance > 0, "No winning shares to redeem");

        winningToken.burn(msg.sender, userBalance);

        uint256 feeAmount = (userBalance * platformFeeBps) / 10000;
        uint256 payoutAmount = userBalance - feeAmount;

        accumulatedFees += feeAmount;
        market.liquidityPool -= userBalance;

        (bool success, ) = msg.sender.call{value: payoutAmount}("");
        require(success, "Payout failed");

        emit WinningsRedeemed(_marketId, msg.sender, userBalance, payoutAmount);
    }

    // --- Admin Functions ---

    function setPlatformFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 500, "Fee cannot exceed 5%");
        platformFeeBps = _newFeeBps;
    }

    function withdrawFees() external onlyOwner {
        uint256 feesToWithdraw = accumulatedFees;
        require(feesToWithdraw > 0, "No fees to withdraw");
        accumulatedFees = 0;
        (bool success, ) = owner().call{value: feesToWithdraw}("");
        require(success, "Fee withdrawal failed");
    }

    // --- View Functions ---

    function getMarket(uint256 _marketId) external view returns (Market memory) {
        return markets[_marketId];
    }

    // --- Internal Helper ---

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
