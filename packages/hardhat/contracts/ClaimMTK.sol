// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20Extended as IERC20} from "./IERC20Extended.sol";

contract ClaimMTK {

    IERC20 MyToken;
    constructor(IERC20 myToken) {
        MyToken = myToken;
    }

    function claimFreeTokens() external {
        MyToken.transferFrom(MyToken.owner(), msg.sender, 100 ether);
    }
}
 