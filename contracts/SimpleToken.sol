// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 million tokens with 18 decimals
    
    constructor() ERC20("SimpleToken", "STK") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    // Optional: Add mint function for owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    // Optional: Add burn function
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
