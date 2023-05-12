// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Challenge solver: <iamdoraemon.eth>
 * The Streamer contract allows users to fund, challenge, and close payment channels, as well as withdraw
 * earnings using a voucher with a verified signature.
 */
contract Streamer is Ownable {
    /* 
    `struct Voucher` is defining a data structure that contains two fields: 
        `updatedBalance` of type `uint256` and 
        `sig` of type `Signature`.
    This data structure is likely used to represent a voucher that can be used to withdraw earnings
    from a payment channel in the `withdrawEarnings` function. The `updatedBalance` field represents
    the updated balance of the voucher, while the `sig` field represents the signature of the voucher.
    */
    struct Voucher {
        uint256 updatedBalance;
        Signature sig;
    }

    /* The `struct Signature` is defining a data structure that contains three fields: 
        `r` of type `bytes32`, 
        `s` of type `bytes32`,
        and `v` of type `uint8`. 
    This data structure is likely used to represent a signature that can be used to verify the authenticity of a voucher
    in the `withdrawEarnings` function.
    The `r` and `s` fields represent the two components of the signature, while the `v` field represents the recovery identifier.
    */
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /* 
    These are two mappings in the Streamer contract. 
    balances => To trach user's funds in the smart contract.
    canCloseAt => To get the channel closing timestamp.
    */
    mapping(address => uint256) balances;
    mapping(address => uint256) canCloseAt;

    /* 
    These are event declarations in the Streamer contract.Events are a way for contracts to communicate with
    the outside world and notify external applications when certain actions occur on the blockchain.
    */
    event Opened(address rube, uint256 amount);
    event Challenged(address rube);
    event Withdrawn(address rube, uint256 amount);
    event Closed(address rube);

    /**
     * @notice The function allows a user to fund a payment channel with a minimum of 0.5 ether and opens the
     * channel if the user does not already have a running channel.
     */
    function fundChannel() public payable {
        require(msg.value >= 0.5 ether, "Insufficient funds");
        require(balances[msg.sender] == 0, "Already has a running channel");
        balances[msg.sender] = msg.value;
        emit Opened(msg.sender, msg.value);
    }

    /**
     * @notice This function returns the time left until a channel can be closed in a smart contract.
     * @param channel: The channel address.
     * @dev The function `timeLeft` returns the time left until the channel can be closed, which is calculated by
     * subtracting the current block timestamp from the `canCloseAt` timestamp stored for the given `channel` address.
     * If the `canCloseAt` timestamp is not set (i.e. equal to 0), the function returns 0.
     */
    function timeLeft(address channel) public view returns (uint256) {
        if (canCloseAt[channel] > 0) {
            return canCloseAt[channel] - block.timestamp;
        }
        return 0;
    }

    /**
     * @notice The function allows the owner to withdraw earnings from a voucher by verifying the signature and transferring
     * the payout to the signer's address.
     * @param voucher - A calldata struct that contains the necessary information to withdraw earnings,
     * including the updated balance of the voucher, and the signature (v, r, s) of the voucher.
     */
    function withdrawEarnings(Voucher calldata voucher) public onlyOwner {
        // like the off-chain code, signatures are applied to the hash of the data
        // instead of the raw data itself
        bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));

        // The prefix string here is part of a convention used in ethereum for signing
        // and verification of off-chain messages. The trailing 32 refers to the 32 byte
        // length of the attached hash message.
        //
        // There are seemingly extra steps here compared to what was done in the off-chain
        // `reimburseService` and `processVoucher`. Note that those ethers signing and verification
        // functions do the same under the hood.
        //
        // again, see https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
        bytes memory prefixed = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hashed
        );
        bytes32 prefixedHashed = keccak256(prefixed);

        address signer = ecrecover(
            prefixedHashed,
            voucher.sig.v,
            voucher.sig.r,
            voucher.sig.s
        );
        require(
            balances[signer] > voucher.updatedBalance,
            "insufficient balance"
        );
        uint256 payout = balances[signer] - voucher.updatedBalance;

        balances[signer] -= payout;

        (bool success, ) = owner().call{value: payout}("");
        require(success, "Eth transfer failed");

        emit Withdrawn(msg.sender, payout);
    }

    /**
     * @dev This function allows a user to challenge a running channel by setting a time limit for it to be closed.
     */
    function challengeChannel() public {
        require(balances[msg.sender] != 0, "No running channel");
        canCloseAt[msg.sender] = block.timestamp + 30 minutes;
        emit Challenged(msg.sender);
    }

    /**
     * @dev The function allows a user to close and withdraw funds from a channel if the closing time has passed.
     */
    function defundChannel() public {
        require(canCloseAt[msg.sender] > 0, "Closed channel");
        require(
            block.timestamp > canCloseAt[msg.sender],
            "Current time is < closing time"
        );
        (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(success, "defundChannel: ETH transfer failed");
        balances[msg.sender] = 0;
        emit Closed(msg.sender);
    }
}
