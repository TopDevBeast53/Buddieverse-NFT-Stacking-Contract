// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";

/**
 * @title Buddieverse Staking Smart Contract
 *
 *
 * @notice This contract uses a simple principle to alow users to stake ERC721 Tokens 
 * and earn ERC20 Reward Tokens distributed by the owner of the contract.
 * Each time a user stakes or withdraws a new Token Id, the contract will store the time of the transaction 
 * and the amount of ERC20 Reward Tokens that the user has earned up to that point (based on the amount of time 
 * that has passed since the last transaction, the amount of Tokens staked and the amount of ERC20 Reward Tokens 
 * distributed per hour so that the amount of ERC20 Reward Tokens earned by the user is always distributed accounting 
 * for how many ERC721 Tokens he has staked at that particular moment.
 * The user can claim the ERC20 Reward Tokens at any time by calling the claimRewards function.
 *
 * @dev The contract is built to be compatible with most ERC721 and ERC20 tokens.
 */
contract BudStaking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev The ERC20 Reward Token that will be distributed to stakers.
     */
    IERC20 public immutable rewardsToken;

    /**
     * @dev The ERC721 Collection that will be staked.
     */
    IERC721 public immutable nftCollection;

    uint256 constant SECONDS_IN_HOUR = 3600;

    uint256 constant SECONDS_IN_DAY = 86400;

    uint256 constant SECONDS_IN_PERIOD = 180 * SECONDS_IN_DAY;

    struct StakedToken {
        uint256 tokenId;

        uint256 timestamp;
    }

    /**
     * @dev Struct that holds the staking details for each user.
     */
    struct Staker {
        /**
         * @dev The array of Token Ids staked by the user.
         */
        StakedToken[] stakedTokens;
        /**
         * @dev The amount of ERC20 Reward Tokens that have not been claimed by the user.
         */
        uint256 unclaimedRewards;
    }

    /**
     * @dev The amount of ERC20 Reward Tokens accrued per hour.
     */
    uint256 private rewardsPerHour = 100000;

    /**
     * @dev Mapping of stakers to their staking info.
     */
    mapping(address => Staker) public stakers;

    /**
     * @dev Mapping of Token Id to staker address.
     */
    mapping(uint256 => address) public stakerAddress;

    /**
     * @dev Array of stakers addresses.
     */
    address[] public stakersArray;

    /**
     * @dev Mapping of stakers addresses to their index in the stakersArray.
     */
    mapping(address => uint256) public stakerToArrayIndex;

    /**
     * @notice Mapping of Token Id to it's index in the staker's stakedTokens array.
     */
    mapping(uint256 => uint256) public tokenIdToArrayIndex;

    uint256 private _startTime;

    /**
     * @notice Constructor function that initializes the ERC20 and ERC721 interfaces.
     * @param _nftCollection - The address of the ERC721 Collection.
     * @param _rewardsToken - The address of the ERC20 Reward Token.
     */
    constructor(IERC721 _nftCollection, IERC20 _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        _startTime = block.timestamp;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to stake.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function stake(uint256[] calldata _tokenIds) external whenNotPaused {
        updateRewards();
        
        Staker storage staker = stakers[msg.sender];
        if (staker.stakedTokens.length == 0) {
            stakersArray.push(msg.sender);
            stakerToArrayIndex[msg.sender] = stakersArray.length - 1;
        }

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            uint256 tokenId = _tokenIds[i];
            require(nftCollection.ownerOf(tokenId) == msg.sender, "Can't stake tokens you don't own!");

            nftCollection.transferFrom(msg.sender, address(this), tokenId);

            staker.stakedTokens.push(StakedToken(tokenId, block.timestamp));
            tokenIdToArrayIndex[tokenId] = staker.stakedTokens.length - 1;
            stakerAddress[tokenId] = msg.sender;
        }
    }

    /**
     * @notice Function used to withdraw ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokens.length > 0, "You have no tokens staked");
        updateRewards();

        uint256 lenToWithdraw = _tokenIds.length;
        for (uint256 i; i < lenToWithdraw; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);

            uint256 index = tokenIdToArrayIndex[_tokenIds[i]];
            uint256 lastTokenIndex = staker.stakedTokens.length - 1;
            if (index != lastTokenIndex) {
                staker.stakedTokens[index] = staker.stakedTokens[lastTokenIndex];
                tokenIdToArrayIndex[staker.stakedTokens[index].tokenId] = index;
            }
            staker.stakedTokens.pop();

            delete stakerAddress[_tokenIds[i]];

            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        if (staker.stakedTokens.length == 0) {
            uint256 index = stakerToArrayIndex[msg.sender];
            uint256 lastStakerIndex = stakersArray.length - 1;
            if (index != lastStakerIndex) {
                stakersArray[index] = stakersArray[lastStakerIndex];
                stakerToArrayIndex[stakersArray[index]] = index;
            }
            stakersArray.pop();
        }
    }

    /**
     * @notice Function used to claim the accrued ERC20 Reward Tokens.
     */
    function claimRewards() external {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokens.length > 0, "You have no tokens staked");

        updateRewards();
        require(staker.unclaimedRewards > 0, "You have no rewards to claim");
        
        rewardsToken.safeTransfer(msg.sender, staker.unclaimedRewards);

        staker.unclaimedRewards = 0;
    }

    function stakedTokenAmount() public view returns (uint256 amount) {
        amount = 0;
        for (uint256 i; i < stakersArray.length; ++i) {
            address user = stakersArray[i];
            amount += stakers[user].stakedTokens.length;
        }
    }

    /**
     * @notice Function used to update the rewards for a user.
     */
    function updateRewards() internal {
        uint256 tokenAmount = stakedTokenAmount();
        if (tokenAmount <= 0) return;

        for (uint256 period = 1; period <= 4; ++period) {
            uint256 startTime = _startTime + (period - 1) * SECONDS_IN_PERIOD;
            console.log("startTime", block.timestamp, startTime);
            if (block.timestamp <= startTime) {
                break;
            }

            uint256 endTime = Math.min(block.timestamp, startTime + SECONDS_IN_PERIOD);
            console.log("endTime", endTime);

            uint256 dailyRewards = (periodRewards(period) / 180) / tokenAmount;
            console.log("dailyRewards", dailyRewards);

            console.log("stakersArray.length", stakersArray.length);
            updateRewardsWithTimestamp(endTime, dailyRewards);
        }
    }

    function updateRewardsWithTimestamp(uint256 _timestamp, uint256 _dailyRewards) internal {
        for (uint256 n; n < stakersArray.length; ++n) {
            address user = stakersArray[n];
            Staker storage staker = stakers[user];
        
            for (uint256 i; i < staker.stakedTokens.length; ++i) {
                uint256 elapsed = (_timestamp - staker.stakedTokens[i].timestamp) / SECONDS_IN_DAY;
                
                staker.unclaimedRewards += elapsed * _dailyRewards;
                staker.stakedTokens[i].timestamp = _timestamp;
            }
        }
    }

    function periodRewards(uint256 period) private pure returns (uint256) {
        if (period == 1) {
            return 1000000;
        } else if (period == 2) {
            return 800000;
        } else {
            return 600000;
        }
    }

    /**
     * @dev Pause staking.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
