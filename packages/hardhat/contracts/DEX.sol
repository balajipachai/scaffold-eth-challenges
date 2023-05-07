// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 * Exercise solver: <iamdoraemon.eth>
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(
        address swapper,
        string txDetails,
        uint256 ethInput,
        uint256 tokenOutput
    );

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(
        address swapper,
        string txDetails,
        uint256 tokensInput,
        uint256 ethOutput
    );

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(
        address liquidityProvider,
        uint256 tokensInput,
        uint256 ethInput,
        uint256 liquidityMinted
    );

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address liquidityRemover,
        uint256 tokensOutput,
        uint256 ethOutput,
        uint256 liquidityWithdrawn
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * The "init" function initializes a decentralized exchange by transferring tokens from the sender
     * to the contract and setting the total liquidity to the contract's balance.
     * @param tokens is of type uint256, which means it can hold an unsigned integer value.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already initiated");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(
            token.transferFrom(msg.sender, address(this), tokens),
            "init: transferfrom failed"
        );
        return totalLiquidity;
    }

    /**
     * @notice the function amount of token Y that can be obtained by swapping a given amount of token X, based
     * on the current reserves of both tokens in a Uniswap-like automated market maker.
     * This function calculates the output price given input amount and reserves of two tokens with a
     * 0.3% fee.
     * @param xInput - The amount of X tokens
     * @param xReserves - The amount of tokens in reserve for the token X in the liquidity pool.
     * @param yReserves - yReserves is the amount of tokens in the reserve of the second token.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput.mul(997);
        uint256 numerator = xInputWithFee.mul(yReserves);
        uint256 denominator = (xReserves.mul(1000)).add(xInputWithFee);
        return (numerator / denominator);
    }

    /**
     * @notice The function `getLiquidity` is returning the liquidity amount of a given LP (liquidity
     * provider) address.
     * The function "getLiquidity" returns the liquidity of a given address.
     * @param lp The address for whom liquidity has to be returned.
     *
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     * This function allows users to swap ETH for a token called "Balloons" at a calculated price.
     * x - Eth
     * y - Token (Balloons)
     * xReserve - DEX's Eth balance
     * yReserve - Dex's Token balance
     * It returns tokenOutput - The amount of tokens that the user will receive in exchange for the ETH.
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Cannot swap 0 ETH");
        uint256 xInput = msg.value;
        uint256 xReserve = address(this).balance.sub(xInput);
        uint256 yReserve = token.balanceOf(address(this));
        tokenOutput = price(xInput, xReserve, yReserve);
        require(
            token.transfer(msg.sender, tokenOutput),
            "Eth to Token transfer failed"
        );
        emit EthToTokenSwap(
            msg.sender,
            "Eth to Balloons",
            msg.value,
            tokenOutput
        );
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     * This function allows users to swap a specified amount of tokens for ETH at a calculated price.
     * x - Token (Balloons)
     * y - Eth
     * xReserve - DEX's Token balance
     * yReserve - Dex's Eth balance
     * It returns ethOutput - The amount of ETH that will be received by the caller after swapping their
     * tokens.
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 xInput = tokenInput;
        uint256 xReserve = token.balanceOf(address(this)).sub(xInput);
        uint256 yReserve = address(this).balance;
        ethOutput = price(xInput, xReserve, yReserve);
        (bool success, ) = msg.sender.call{value: ethOutput}("");
        require(success, "Token to ETH transfer failed");
        require(
            token.transferFrom(msg.sender, address(this), xInput),
            "Token to Eth transfer from failed"
        );
        emit TokenToEthSwap(
            msg.sender,
            "Balloons to ETH",
            ethOutput,
            tokenInput
        );
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     * The deposit function allows users to deposit tokens and receive liquidity tokens in return,
     * which are used to track their share of the liquidity pool.
     * x - Eth
     * y - Token (Balloons)
     * xReserve - DEX's Eth balance
     * yReserve - Dex's Token balance
     * It returns tokensDeposited - The amount of tokens deposited by the user, calculated based on the
     * amount of ETH they sent and the current reserve ratio of the contract.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send value when depositing");
        uint256 xInput = msg.value;
        uint256 xReserve = address(this).balance.sub(xInput);
        uint256 yReserve = token.balanceOf(address(this));

        tokensDeposited = (xInput.mul(yReserve).div(xReserve)).add(1);

        uint256 mintedLiquidity = xInput.mul(totalLiquidity) / xReserve;
        liquidity[msg.sender] += mintedLiquidity;
        totalLiquidity += mintedLiquidity;
        require(
            token.transferFrom(msg.sender, address(this), tokensDeposited),
            "Depost transfer from failed"
        );
        emit LiquidityProvided(
            msg.sender,
            mintedLiquidity,
            msg.value,
            tokensDeposited
        );
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     * The "withdraw" function allows a user to withdraw their liquidity from a smart contract by
     * transferring ETH and tokens back to them based on their share of the total liquidity.
     * x - Token (Balloons)
     * y - Eth
     * xReserve - DEX's Token balance
     * yReserve - Dex's  Eth balance
     * It returns eth_amount & token_amount- The amount of ETH & tokens that the user receives after withdrawing their liquidity.
     */
    function withdraw(
        uint256 amount
    ) public returns (uint256 eth_amount, uint256 token_amount) {
        require(
            liquidity[msg.sender] >= amount,
            "withdraw: sender does not have enough liquidity to withdraw."
        );
        uint256 xReserve = token.balanceOf(address(this));
        uint256 yReserve = address(this).balance;
        uint256 yInput = amount.mul(yReserve).div(totalLiquidity);
        uint256 xInput = amount.mul(xReserve).div(totalLiquidity);

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        (bool success, ) = msg.sender.call{value: yInput}("");
        require(success, "withdraw: eth transfer failed");

        require(
            token.transfer(msg.sender, xInput),
            "withdraw: token transfer failed"
        );

        emit LiquidityRemoved(msg.sender, amount, yInput, xInput);

        eth_amount = yInput;
        token_amount = xInput;
    }
}
