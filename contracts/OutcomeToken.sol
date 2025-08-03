// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OutcomeToken
 * @dev A simple ERC-20 token contract to represent a share in a specific
 * outcome of a prediction market. This contract is intended to be deployed
 * by the main PredictionMarket contract (the factory).
 * The PredictionMarket contract will be the owner and the only entity
 * with the authority to mint or burn tokens.
 */
contract OutcomeToken is ERC20, Ownable {
    /**
     * @dev Sets the token name and symbol, and transfers ownership to the factory.
     * @param name_ The name of the token (e.g., "Market #123 - YES").
     * @param symbol_ The symbol of the token (e.g., "M123YES").
     * @param factoryOwner The address of the PredictionMarket contract that deployed this token.
     */
    constructor(string memory name_, string memory symbol_, address factoryOwner)
        ERC20(name_, symbol_)
        Ownable(factoryOwner)
    {}

    /**
     * @notice Mints new tokens and assigns them to a specified account.
     * @dev Can only be called by the owner (the PredictionMarket contract).
     * @param to The account that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns a specified amount of tokens from a specified account.
     * @dev Can only be called by the owner (the PredictionMarket contract).
     * @param from The account whose tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
