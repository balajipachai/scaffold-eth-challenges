pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

// @Exercise solver: <iamdoraemon.eth> || <iambatman.blockchain>
contract Vendor is Ownable {
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfETH
    );

    YourToken public yourToken;

    /* The `constructor` function is initializing the `yourToken` variable with the address of an
    existing ERC20 token contract. It creates an instance of the `YourToken` contract using the
    provided `tokenAddress` and assigns it to the `yourToken` variable. This allows the `Vendor`
    contract to interact with the existing ERC20 token contract and perform token transfers. */
    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    /**
     * This function allows users to buy tokens by transferring ether to the contract and receiving
     * tokens in return.
     */
    function buyTokens() public payable {
        uint256 numOfTokens = msg.value * 100;
        yourToken.transfer(msg.sender, numOfTokens);
        emit BuyTokens(msg.sender, msg.value, numOfTokens);
    }

    /**
     * This function allows the contract owner to withdraw the balance of the contract in ETH.
     */
    function withdraw() public onlyOwner {
        // solhint-disable-next-line unused variable
        (bool success, bytes memory _data) = msg.sender.call{
            value: address(this).balance
        }("");
        require(success, "Withdraw: ETH transfer failed");
    }

    /**
     * This function allows users to sell tokens for ether at a rate of 1 ether per 100 tokens, with
     * appropriate checks and event emissions.
     * @param amount - it is used to represent the amount of tokens being sold.
     */
    function sellTokens(uint256 amount) public {
        require(
            yourToken.allowance(msg.sender, address(this)) >= amount,
            "Cannot sell, insufficient allowance"
        );
        require(
            yourToken.transferFrom(msg.sender, address(this), amount),
            "Transfer from failed"
        );
        uint256 ethForTokens = amount / 100;
        (bool success, bytes memory data) = msg.sender.call{
            value: ethForTokens
        }("");
        require(success, "Transfer eth failed");
        emit SellTokens(msg.sender, amount, ethForTokens);
    }
}
