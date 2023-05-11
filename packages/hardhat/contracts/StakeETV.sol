// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title StakeETV
/// @notice The stake ETV contract for staking and unstaking ETV
contract StakeETV is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Reward token contract address
    // solhint-disable-next-line var-name-mixedcase
    IERC20 public rewardToken;
    IERC20 public ETVContract =
        IERC20(0xbB56cFDD9d9ffd449f53a96457CbDCBDb003836E); // TODO CHANGE TOKEN ADDRESS WHILE DEPLOYMENT

    // List of Stakers, helpful when fetching stakers report
    address[] public stakers;

    // APY
    uint8 public APY = 15;

    // Staking pool threshold = 1 Million ETV
    uint256 public threshold = 1000000 ether;

    // Staking would be accepted for 3 Months
    uint256 public deadline = block.timestamp + 6 weeks;

    // Cut short reward percentage, if within deadline
    uint8 public cutShortRewardPercent = 50;

    /**
     * @dev Struct representing Staker details
     * @param isPresent Boolean indicating whether a staker exists or not
     * @param stakedAtTimestamp Timestamp of when the user staked tokens
     * @param unstakedAtTimestamp Timestamp of when the user started unstaking the tokens
     * @param rewardRedeemedAt Timestamp of when the user last claimed the rewards
     * @param reward Total rewards earned by staking
     * @param claimedRewards Total rewards claimed by the user
     * @param unstakeAmount Amount which is under unstaking
     * @param amount Total stake amount of the user
     */
    struct Staker {
        bool isPresent;
        uint256 stakedAtTimestamp;
        uint256 unstakedAtTimestamp;
        uint256 rewardRedeemedAt;
        uint256 reward;
        uint256 claimedRewards;
        uint256 unstakeAmount;
        uint256 amount;
    }

    uint256 public totalETVStaked;
    mapping(address => Staker) public stakerInfo;

    event Stake(
        address indexed staker,
        uint256 amount,
        uint256 stakedAtTimestamp
    );
    event Unstake(
        address indexed staker,
        uint256 amount,
        uint256 unstakedAtTimestamp
    );
    event Withdraw(address indexed staker, uint256 amount, uint256 withdrawnAt);
    event ClaimRewards(
        address indexed staker,
        uint256 amount,
        uint256 redeemedAt
    );
    event APYUpdated(uint8 oldAPY, uint8 newAPY);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event DeadlineUpdated(uint256 oldDeadline, uint256 newDeadline);
    event CutShortRewardPercentUpdated(
        uint8 oldCutShortRewardPercent,
        uint8 newCutShortRewardPercent
    );
    event RewardTokenUpdated(IERC20 oldRewardToken, IERC20 newRewardToken);

    /* Constructor that takes an input parameter `_rewardToken` of type `IERC20`
     (an interface for ERC20 tokens) and assigns it to a state variable `rewardToken`.
     The `require` statement checks that the input parameter is not the null address. 
    */
    constructor(IERC20 _rewardToken, IERC20 _etvContract) {
        require(
            address(_rewardToken) != address(0),
            "Reward token is address zero"
        );
        require(
            address(_etvContract) != address(0),
            "ETV token is address zero"
        );
        rewardToken = _rewardToken;
        ETVContract = _etvContract;
    }

    /**
     * @dev Contract might receive/hold MATIC as part of the maintenance process.
     * The receive function is executed on a call to the contract with empty calldata.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @dev The fallback function is executed on a call to the contract if
     * none of the other functions match the given function signature.
     */
    fallback() external payable {}

    /**
     * @dev To update APY
     *
     * Requirements:
     * - newAPY must be greater than 0
     * - only contract owner can call this function
     */
    function updateAPY(uint8 newAPY) external onlyOwner {
        require(newAPY > 0, "APY must be > 0");
        uint8 oldAPY = APY;
        APY = newAPY;
        emit APYUpdated(oldAPY, newAPY);
    }

    /**
     * @dev To update threshold
     *
     * Requirements:
     * - newThreshold must be greater than 0
     * - only contract owner can call this function
     */
    function updateThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be > 0");
        uint256 oldThreshold = threshold;
        threshold = newThreshold;
        emit ThresholdUpdated(oldThreshold, newThreshold);
    }

    /**
     * @dev To update deadline
     *
     * Requirements:
     * - newDeadline must be greater than 0
     * - only contract owner can call this function
     */
    function updateDeadline(uint256 newDeadline) external onlyOwner {
        require(newDeadline > 0, "Deadline must be > 0");
        uint256 oldDeadline = deadline;
        deadline = newDeadline;
        emit DeadlineUpdated(oldDeadline, newDeadline);
    }

    /**
     * @dev To update cut short reward percent
     *
     * Requirements:
     * - newCutShortRewardPercent must be greater than 0
     * - only contract owner can call this function
     */
    function updateCutShortRewardPercent(
        uint8 newCutShortRewardPercent
    ) external onlyOwner {
        require(newCutShortRewardPercent > 0, "Cut short reward % must be > 0");
        uint8 oldCutShortRewardPercent = cutShortRewardPercent;
        cutShortRewardPercent = newCutShortRewardPercent;
        emit CutShortRewardPercentUpdated(
            oldCutShortRewardPercent,
            newCutShortRewardPercent
        );
    }

    /**
     * @dev To update reward token
     *
     * Requirements:
     * - newRewardToken cannot be address(0)
     * - only contract owner can call this function
     */
    function updateRewardToken(IERC20 newRewardToken) external onlyOwner {
        require(
            address(newRewardToken) != address(0),
            "New reward token is address(0)"
        );
        require(
            address(newRewardToken) != address(this),
            "New reward token is current contract"
        );
        IERC20 oldRewardToken = rewardToken;
        rewardToken = newRewardToken;
        emit RewardTokenUpdated(oldRewardToken, newRewardToken);
    }

    /**
     * @dev To claim the earned rewards
     *
     * Requirements:
     * - amount must be greater than 0
     * - EarnTV balance of Staker must be greater than or equal to amount
     */
    function claimRewards() external {
        Staker memory _staker = stakerInfo[msg.sender];
        require(_staker.isPresent, "No rewards: not a staker");

        uint256 rewardsEarned = getRewards(_staker);

        // If claiming rewards within the deadline then, rewards will be cut short by cutShortRewardPercent%
        if (block.timestamp < deadline) {
            rewardsEarned = (rewardsEarned.mul(cutShortRewardPercent)).div(100);
        }

        _staker.rewardRedeemedAt = block.timestamp;

        // When entire stake has been withdrawn
        if (!(_staker.amount > 0)) {
            _staker.stakedAtTimestamp = 0;
            _staker.unstakedAtTimestamp = 0;
            _staker.rewardRedeemedAt = 0;
        }

        require(
            rewardToken.balanceOf(address(this)) >= rewardsEarned,
            "claimRewards: Insufficient balance"
        );

        _staker.reward = 0;
        _staker.claimedRewards = _staker.claimedRewards.add(rewardsEarned);
        stakerInfo[msg.sender] = _staker; // Write Staker info to contract storage

        rewardToken.safeTransfer(msg.sender, rewardsEarned); // External Call

        emit ClaimRewards(msg.sender, rewardsEarned, block.timestamp); //solhint-disable-line not-rely-on-time
    }

    /**
     * @dev To stake EarnTV in the contract
     *
     * Requirements:
     * - amount must be greater than 0
     * - EarnTV balance of Staker must be greater than or equal to amount
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Stake amount must be > 0");

        // Check Staker has enough ETV balance
        require(
            (ETVContract.balanceOf(msg.sender)) >= amount,
            "stake: Insufficient user balance"
        );

        Staker memory _staker = stakerInfo[msg.sender];

        /*
         * Each user can stake a maximum of 1% of the threshold
         */
        uint256 onePercentOfThreshold = threshold.div(100);
        require(
            _staker.amount.add(amount) <= onePercentOfThreshold,
            "Cannot stake > 1% of threshold"
        );

        if (!_staker.isPresent) {
            _staker.isPresent = true;
            stakers.push(msg.sender);
            //solhint-disable-next-line not-rely-on-time
            _staker.stakedAtTimestamp = block.timestamp;
        }
        /*
         * It implies a staker is staking again
         * Update total principal & keep aside the reward for the user for the first staked amount
         */
        if (_staker.amount > 0) {
            // Reward for oldStake amount
            _staker.reward = _staker.reward.add(getRewards(_staker));
            //solhint-disable-next-line not-rely-on-time
            _staker.stakedAtTimestamp = block.timestamp;
        }

        ETVContract.safeTransferFrom(msg.sender, address(this), amount);

        totalETVStaked = totalETVStaked.add(amount);

        // Updates Total Stake amount
        _staker.amount = _staker.amount.add(amount);
        stakerInfo[msg.sender] = _staker; // Write Staker info to contract storage

        emit Stake(msg.sender, amount, _staker.stakedAtTimestamp);
    }

    /**
     * @dev To Unstake EarnTV from the contract
     *
     * Requirements:
     * - Caller's staked EarnTV must be greater than 0
     * - Unstake amount must be less than or equal to the staked EarnTV
     * - Contract's EarnTV balance must be greater than staked EarnTV
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "Unstake amount must be > 0");

        Staker memory _staker = stakerInfo[msg.sender];
        require(_staker.amount > 0, "No Stakes");
        require(amount <= _staker.amount, "Unstake amt > staked amt");

        uint256 rewards = getRewards(_staker);

        // If unstaking within the deadline then, reward will be cut short by 50%
        if (block.timestamp < deadline) {
            _staker.reward = _staker.reward.add(
                (rewards.mul(cutShortRewardPercent)).div(100)
            );
        } else {
            _staker.reward = _staker.reward.add(rewards);
        }

        _staker.unstakedAtTimestamp = block.timestamp; //solhint-disable-line not-rely-on-time

        _staker.unstakeAmount = _staker.unstakeAmount.add(amount);
        _staker.amount = _staker.amount.sub(amount);

        totalETVStaked = totalETVStaked.sub(amount);

        stakerInfo[msg.sender] = _staker; // Write Staker info to contract storage

        emit Unstake(msg.sender, amount, block.timestamp); //solhint-disable-line not-rely-on-time
    }

    /**
     * @dev To claim/withdraw the unstake amount
     *
     * Requirements:
     * - amount must be greater than 0
     * - EarnTV balance of Staker must be greater than or equal to amount
     */
    function withdraw() external {
        Staker memory _staker = stakerInfo[msg.sender];
        uint256 unstakeAmount = _staker.unstakeAmount;
        require(unstakeAmount > 0, "Unstake amount is 0");

        //solhint-disable-next-line not-rely-on-time
        uint256 secondsUnstakedFor = block.timestamp.sub(
            _staker.unstakedAtTimestamp
        );
        // Since 24 Hours = 1 Day, therefore 30 Days = 720 Hours = 2592000 Seconds
        require(
            secondsUnstakedFor >= 2592000,
            "Cannot withdraw in cooldown period"
        );

        require(
            ETVContract.balanceOf(address(this)) >= unstakeAmount,
            "withdraw: Insufficient contract balance"
        );

        _staker.unstakeAmount = 0;
        stakerInfo[msg.sender] = _staker; // Write Staker info to contract storage

        ETVContract.safeTransfer(msg.sender, unstakeAmount); // External Call

        emit Withdraw(msg.sender, unstakeAmount, block.timestamp); //solhint-disable-line not-rely-on-time
    }

    /**
     * @dev Returns the caller's staking details
     */
    function myStakes(
        address _staker
    )
        external
        view
        returns (
            uint256 stakedETV,
            uint256 secondsStakedFor,
            uint256 unstakedAtTimestamp,
            uint256 reward,
            uint256 unstakeAmount,
            uint256 claimedRewards
        )
    {
        Staker memory staker = stakerInfo[_staker];
        stakedETV = staker.amount;
        secondsStakedFor = block.timestamp.sub(staker.stakedAtTimestamp);
        unstakedAtTimestamp = staker.unstakedAtTimestamp;
        reward = getRewards(staker);
        unstakeAmount = staker.unstakeAmount;
        claimedRewards = staker.claimedRewards;
    }

    /**
     * @dev Returns the total number of stakers
     */
    function totalStakers() external view returns (uint256) {
        return stakers.length;
    }

    /**
     * The function `timeLeft()` returns the amount of time left until the deadline, which
     * is calculated as the difference between the deadline and the current block timestamp.
     * If the current block timestamp is greater than or equal to the deadline, the function returns 0.
     * The return value is of type `uint256`.
     */
    function timeLeft() public view returns (uint256) {
        if (block.timestamp < deadline) {
            return deadline - block.timestamp;
        } else {
            return 0;
        }
    }

    /**
     * @dev Returns rewards earned
     */
    function earnedRewards(address staker) public view returns (uint256) {
        Staker memory _staker = stakerInfo[staker];
        return getRewards(_staker);
    }

    /**
     * @dev Returns the calculated rewards
     */
    function calculateRewards(
        uint256 timestamp,
        uint256 amount
    ) internal view returns (uint256 reward) {
        //solhint-disable-next-line not-rely-on-time
        uint256 secondsStakeFor = block.timestamp.sub(timestamp);
        // 3153600000 = 100 (Percentage) * 365 (Days in a Year) * 24 (Hours In a Day) * 3600 (Seconds In an Hour)
        uint256 tokenPerSecond = (amount.mul(APY)).div(3153600000);
        return tokenPerSecond.mul(secondsStakeFor);
    }

    /**
     *
     * @param _staker Staker struct
     * @dev Returns the rewards for the staked ETV
     *
     */
    function getRewards(
        Staker memory _staker
    ) internal view returns (uint256 reward) {
        uint256 giveRewardsFrom = _staker.stakedAtTimestamp;
        if (
            (_staker.unstakedAtTimestamp > 0) || (_staker.rewardRedeemedAt > 0)
        ) {
            giveRewardsFrom = _staker.unstakedAtTimestamp >
                _staker.rewardRedeemedAt
                ? _staker.unstakedAtTimestamp
                : _staker.rewardRedeemedAt;
        }
        reward = _staker.reward.add(
            calculateRewards(giveRewardsFrom, _staker.amount)
        );
    }
}
