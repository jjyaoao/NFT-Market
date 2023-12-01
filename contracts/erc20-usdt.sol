// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract cUSDT is ERC20, Ownable {
    constructor()
        ERC20("cUSDT", "cUSDT")
        Ownable(msg.sender)
    {
        mint(msg.sender, type(uint256).max);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}