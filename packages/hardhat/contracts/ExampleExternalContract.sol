// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }

    function withdrawEth() external {
        require(
            msg.sender == 0xbB56cFDD9d9ffd449f53a96457CbDCBDb003836E,
            "Invalid caller"
        );
        msg.sender.call{value: address(this).balance}("");
    }
}
