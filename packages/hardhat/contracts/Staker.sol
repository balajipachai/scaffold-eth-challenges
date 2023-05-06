// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;

    uint256 public deadline = block.timestamp + 3 days;
    bool public openForWithdraw;

    event Stake(address indexed sender, uint256 amount);

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "External contract is completed, cannot execute/withdraw"
        );
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    receive() external payable {
        stake();
    }

    function stake() public payable {
        require(block.timestamp <= deadline, "Cannot stake: deadline passed");
        require(msg.value > 0, "Value must be > 0");
        balances[msg.sender] += msg.value;
        if (address(this).balance < threshold) {
            openForWithdraw = true;
        } else {
            openForWithdraw = false;
            // exampleExternalContract.complete{value: address(this).balance}();
        }
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted {
        require(block.timestamp > deadline, "Cannot execute within deadline");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    function withdraw() public notCompleted {
        require(balances[msg.sender] > 0, "No stakes, cannot withdraw");
        require(openForWithdraw, "Cannot withdraw now.");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.call{value: balance}("");
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp < deadline) {
            return deadline - block.timestamp;
        } else {
            return 0;
        }
    }
}
