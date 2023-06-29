// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MyToken
/// @notice ERC-20 implementation of MyToken token
contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") {
        // Mint MTK tokens to msg.sender
        super._mint(msg.sender, 1000000000 ether); // 1 Billion
    }
}
