// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20Extended as IERC20} from "./IERC20Extended.sol";

/// @title EarnTV
/// @notice ERC-20 implementation of EarnTV token
contract EarnTV is ERC20, Ownable, Pausable {
    using SafeMath for uint256;
    mapping(address => bool) public isAdmin;
    address public pendingOwner;
    uint256 public maxAccTransferLimit = 7500 * 1 ether; // 7500 ETV Tokens
    uint256 public timeBetweenSubmission = 6 hours;
    uint256 internal lastSubmissionTimestamp;

    address public issuerContract;

    event LogBulkTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 activity
    );
    event LogAddAdmin(address admin, uint256 addedAt);
    event LogRemoveAdmin(address admin, uint256 removedAt);
    event MaxTransferLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event TimeBetweenSubmissionUpdated(uint256 oldTime, uint256 newTime);
    event OwnershipTransferCancelled(address newOwner);
    event OwnershipTransferClaimed(address newOwner);

    /**
     * @dev Modifier to make a function invocable by only the admin or owner account
     */
    modifier onlyAdminOrOwner() {
        //solhint-disable-next-line reason-string
        require(
            (isAdmin[msg.sender]) || (msg.sender == owner()),
            "Caller is neither admin nor owner"
        );
        _;
    }

    /**
     * @dev Modifier to make a function invocable by only the owenr or issuer contract
     */
    modifier onlyIssuerContractOrOwner() {
        //solhint-disable-next-line reason-string
        require(
            (msg.sender == issuerContract) || (msg.sender == owner()),
            "Caller is neither issuer contract nor owner"
        );
        _;
    }

    /**
     * @dev Sets the values for {name = ETVCoin}, {totalSupply = 5000000}, {decimals = 18} and {symbol = ETV}.
     *
     * All of these values except admin are immutable: they can only be set once during
     * construction.
     */
    constructor(
        uint256 fixedSupply,
        address contractOwner,
        address[] memory _admins
    ) ERC20("EarnTV", "ETV") {
        //solhint-disable-next-line reason-string
        require(
            contractOwner != address(0),
            "Contract owner can't be address zero"
        );
        uint256 adminLength = _admins.length;
        for (uint256 i = 0; i < adminLength; i++) {
            require(_admins[i] != address(0), "Admin can't be address zero");
            isAdmin[_admins[i]] = true;
            //solhint-disable-next-line not-rely-on-time
            emit LogAddAdmin(_admins[i], block.timestamp);
        }
        // Mint ETV tokens to contractOwner address
        super._mint(contractOwner, fixedSupply); // Since Total supply 500 Million ETV
        // Transfers contract ownership to contractOwner
        super.transferOwnership(contractOwner);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev To add admins address in the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function addAdmins(
        address[] memory _admins
    ) external onlyOwner whenNotPaused {
        address admin;
        for (uint256 i = 0; i < _admins.length; i++) {
            admin = _admins[i];
            require(admin != address(0), "Admin can't be address zero");
            require(!isAdmin[admin], "Already an admin");
            isAdmin[admin] = true;
            //solhint-disable-next-line not-rely-on-time
            emit LogAddAdmin(admin, block.timestamp);
        }
    }

    /**
     * @dev To remove admins address from the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function removeAdmins(
        address[] memory _admins
    ) external onlyOwner whenNotPaused {
        address admin;
        for (uint256 i = 0; i < _admins.length; i++) {
            admin = _admins[i];
            require(admin != address(0), "Admin can't be address zero");
            require(isAdmin[admin], "Not an admin");
            isAdmin[admin] = false;
            //solhint-disable-next-line not-rely-on-time
            emit LogRemoveAdmin(admin, block.timestamp);
        }
    }

    /**
     * @dev Destroys `amount` tokens from `msg.sender`, reducing the total supply.
     */
    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Sets the issuer contract address
     */
    function setIssuerContract(
        address _issuerContract
    ) external onlyOwner whenNotPaused {
        require(_issuerContract != address(0), "Address zero");
        issuerContract = _issuerContract;
    }

    /**
     * @dev Updates max account transfer limit
     */
    function updateMaxTransferLimit(
        uint256 _newLimit
    ) external onlyOwner whenNotPaused {
        uint256 oldLimit = maxAccTransferLimit;
        maxAccTransferLimit = _newLimit;
        emit MaxTransferLimitUpdated(oldLimit, _newLimit);
    }

    /**
     * @dev Updates time between submissions
     */
    function updateTimeBetweenSubmissions(
        uint256 _newTime
    ) external onlyOwner whenNotPaused {
        uint256 oldTime = timeBetweenSubmission;
        timeBetweenSubmission = _newTime * 1 hours;
        emit TimeBetweenSubmissionUpdated(oldTime, timeBetweenSubmission);
    }

    /**
     * @dev Moves tokens `amount` from `tokenOwner` to `recipients`.
     */
    function bulkTransfer(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[] memory activities
    ) external onlyIssuerContractOrOwner whenNotPaused {
        require(
            (recipients.length == amounts.length) &&
                (recipients.length == activities.length),
            "bulkTransfer: Unequal params"
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            (block.timestamp.sub(lastSubmissionTimestamp)) >=
                timeBetweenSubmission,
            "Wait for next submission time"
        );
        lastSubmissionTimestamp = block.timestamp; // solhint-disable-line not-rely-on-time
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                amounts[i] <= maxAccTransferLimit,
                "Transfer limit crossed"
            );
            if (msg.sender == owner()) {
                super.transfer(recipients[i], amounts[i]);
            } else {
                super.transferFrom(owner(), recipients[i], amounts[i]);
            }

            emit LogBulkTransfer(
                msg.sender,
                recipients[i],
                amounts[i],
                activities[i]
            );
        }
    }

    /**
     * @dev To transfer all BNBs/ETHs stored in the contract to the caller
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawAll() external onlyOwner {
        //solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{
            gas: 2300,
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev To transfer stuck ERC20 tokens from within the contract
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function withdrawStuckTokens(
        IERC20 token,
        address receiver
    ) external onlyOwner {
        require(address(token) != address(0), "Token cannot be address zero");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - invocation can be done, only by the contract owner & when the contract is not paused
     */
    function pause() external onlyAdminOrOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - invocation can be done, only by the contract owner & when the contract is paused
     */
    function unpause() external onlyAdminOrOwner whenPaused {
        _unpause();
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        //solhint-disable-next-line reason-string
        require(
            newOwner != address(this),
            "Ownable: new owner cannot be current contract"
        );
        require(pendingOwner == address(0), "Pending owner exists");
        pendingOwner = newOwner;
    }

    /**
     * @dev To cancel ownership transfer
     *
     * Requirements:
     * - can only be invoked by the contract owner
     * - the pendingOwner must be non-zero
     */
    function cancelTransferOwnership() external onlyOwner {
        require(pendingOwner != address(0), "No pending owner");
        delete pendingOwner;
        emit OwnershipTransferCancelled(pendingOwner);
    }

    /**
     * @dev New owner accepts the contract ownershi
     *
     * Requirements:
     * - The pending owner must be set prior to claiming ownership
     */
    function claimOwnership() external {
        require(msg.sender == pendingOwner, "Caller is not pending owner");
        emit OwnershipTransferred(owner(), pendingOwner);
        _owner = pendingOwner;
        delete pendingOwner;
    }

    /**
     * @dev To view can submit transaction status
     */
    function canSubmitTransaction() external view returns (bool isSubmit) {
        return (block.timestamp.sub(lastSubmissionTimestamp) >=
            timeBetweenSubmission);
    }
}
