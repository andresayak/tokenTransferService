// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(
        uint256 initialSupply
    ) ERC20() public {
        _mint(msg.sender, initialSupply);
    }
}
