// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TipJar
 * @dev A simple, elegant contract that allows anyone to send a tip (in CELO)
 * to the owner, along with a public message. It demonstrates handling payments,
 * storing data, and secure ownership patterns.
 *
 * Features:
 * - Anyone can send a tip with a message.
 * - All tips are stored on-chain for a transparent history.
 * - The contract owner can withdraw the entire balance.
 * - Events are emitted for new tips and withdrawals.
 */
contract TipJar is Ownable {
    /**
     * @dev A struct to hold all information about a single tip.
     */
    struct Tip {
        address sender; // The address of the person who sent the tip
        uint256 amount; // The amount of CELO sent
        string message; // The message they included
        uint256 timestamp; // The block timestamp when the tip was sent
    }

    // An array to store all tips received by the contract
    Tip[] private s_tips;

    // The total amount of CELO ever tipped to this contract
    uint256 public totalTipped;

    /**
     * @dev Emitted when a new tip is successfully sent to the contract.
     * @param sender The address of the tipper.
     * @param amount The amount of CELO tipped.
     * @param message The message included with the tip.
     */
    event TipReceived(address indexed sender, uint256 amount, string message);

    /**
     * @dev Emitted when the owner successfully withdraws funds.
     * @param amount The total amount of CELO withdrawn.
     * @param recipient The address the funds were sent to (the owner).
     */
    event Withdrawn(uint256 amount, address indexed recipient);

    /**
     * @dev Sets the initial owner of the contract.
     * The deployer of the contract will be the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Sends a tip to the contract owner.
     * @dev This function is payable, meaning it can receive CELO.
     * The sender must send a value greater than 0.
     * @param _message A public message to accompany the tip.
     */
    function sendTip(string memory _message) external payable {
        require(msg.value > 0, "TipJar: Tip amount must be greater than zero.");

        s_tips.push(Tip({
            sender: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        }));

        totalTipped += msg.value;

        emit TipReceived(msg.sender, msg.value, _message);
    }

    /**
     * @notice Withdraws the entire balance of the contract to the owner.
     * @dev Can only be called by the contract owner.
     * This is a protective measure to ensure funds are secure.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "TipJar: No funds to withdraw.");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "TipJar: Withdrawal failed.");

        emit Withdrawn(balance, owner());
    }

    /**
     * @notice Gets the total number of tips received.
     * @return The total count of tips.
     */
    function getTipCount() external view returns (uint256) {
        return s_tips.length;
    }

    /**
     * @notice Retrieves the most recent tips.
     * @param _count The number of recent tips to fetch.
     * @return An array of Tip structs.
     */
    function getLatestTips(uint256 _count) external view returns (Tip[] memory) {
        uint256 totalTips = s_tips.length;
        uint256 count = _count > totalTips ? totalTips : _count;
        
        Tip[] memory latestTips = new Tip[](count);
        
        for (uint256 i = 0; i < count; i++) {
            latestTips[i] = s_tips[totalTips - 1 - i];
        }
        
        return latestTips;
    }

    /**
     * @notice Gets the entire contract's current CELO balance.
     * @return The balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
