// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Reward
/// @notice ERC-20 implementation of Reward token
contract Reward is ERC20 {
    constructor() ERC20("RewardMyToken", "rMTK") {
        // Mint rMTK tokens to msg.sender
        super._mint(msg.sender, 1000000000 ether); // 1 Billion
    }
}
