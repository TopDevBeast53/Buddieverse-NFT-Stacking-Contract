// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
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
contract BudStaking1 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev The ERC20 Reward Token that will be distributed to stakers.
     */
    IERC20 public immutable _rewardsToken;

    /**
     * @dev The ERC721 Collection that will be staked.
     */
    IERC721 public immutable _nftCollection;

    uint256 constant SECONDS_IN_HOUR = 3600;

    uint256 constant SECONDS_IN_DAY = 1;//86400;

    uint256 constant MAX_STAKING_REWARDS = 3000000;

    struct StakedToken {
        uint256 tokenId;

        address staker;

        uint256 stakedTime;
    }

    struct RewardToken {
        uint256 tokenId;

        uint256 stakedDays;
    }

    mapping(uint256 => StakedToken) public _stakedTokensMap;

    mapping(uint256 => uint256) public _stakedTokenIndex;

    StakedToken[] public _stakedTokensArray;

    uint256 private _startTime;

    uint256 private _dailyRewards = 100;

    /**
     * @notice Constructor function that initializes the ERC20 and ERC721 interfaces.
     * @param nftCollection_ - The address of the ERC721 Collection.
     * @param rewardsToken_ - The address of the ERC20 Reward Token.
     */
    constructor(IERC721 nftCollection_, IERC20 rewardsToken_) {
        _nftCollection = nftCollection_;
        _rewardsToken = rewardsToken_;
        _startTime = block.timestamp;
    }

    function stakedTokenAmount() public view returns (uint256) {
        return _stakedTokensArray.length;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to stake.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function stake(uint256[] calldata _tokenIds) external whenNotPaused {
        // require(getTotalStakedRewards() < MAX_STAKING_REWARDS, "Maximum staked rewards overflow");

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            uint256 tokenId = _tokenIds[i];
            require(_nftCollection.ownerOf(tokenId) == msg.sender, "Can't stake tokens you don't own!");

            _nftCollection.transferFrom(msg.sender, address(this), tokenId);

            StakedToken storage token = _stakedTokensMap[tokenId];
            token.tokenId = tokenId;
            token.staker = msg.sender;
            token.stakedTime = block.timestamp;

            console.log("StakedToken", tokenId, block.timestamp);
            _stakedTokensArray.push(token);

            _stakedTokenIndex[tokenId] = _stakedTokensArray.length - 1;
        }
    }

    function getDailyRewardsOf(uint256 period) public view returns (uint256) {
        if (period == 1) {
            return 5555;
        } else if (period == 2) {
            return 4444;
        } else {
            return 3333;
        }
    }

    function getStakedTokenDurations(uint256 startTime, uint256 endTime) internal view returns (uint256[] memory) {
        uint256 elapsed = (endTime - startTime) / SECONDS_IN_DAY;
        uint256 timestamp = startTime + elapsed * SECONDS_IN_DAY;

        uint256 len = _stakedTokensArray.length;
        uint256[] memory durations = new uint256[](len);
        for (uint256 i = 0; i < len; ++i) {
            StakedToken storage token = _stakedTokensArray[i];
            durations[i] = (timestamp - token.stakedTime) / SECONDS_IN_DAY;
        }
        return durations;
    }

    function getPeriodStakedRewards(uint256 period) public view returns (uint256) {
        uint256 periodSeconds = 180 * SECONDS_IN_DAY;
        uint256 startTime = _startTime + (period - 1) * periodSeconds;
        uint256 endTime = startTime + periodSeconds;
        if (endTime > block.timestamp) {
            endTime = block.timestamp;
        }
        
        uint256[] memory durations = getStakedTokenDurations(startTime, endTime);

        uint256 maximum = 0;
        for (uint256 i = 0; i < durations.length; i++) {
            if (durations[i] > maximum) {
                maximum = durations[i];
            }
        }

        uint256 dailyRewards = getDailyRewardsOf(period);
        return maximum * dailyRewards;
    }

    function getTotalStakedRewards() public view returns (uint256) {
        require(_stakedTokensArray.length > 0, "No staked tokens");

        uint256 rewards = 0;
        for (uint256 period = 1; period <= 4; ++period) {
            uint256 periodSeconds = 180 * SECONDS_IN_DAY;
            uint256 startTime = _startTime + (period - 1) * periodSeconds;

            if (block.timestamp > startTime) {
                rewards += getPeriodStakedRewards(period);
            }
        }
        return rewards;
    }

    function getRewardsOf(uint256 tokenId) public view returns (uint256) {
        require(_stakedTokensArray.length > 0, "No staked tokens");
        // require() --//TODO check mapping of tokenId
        uint256 index = _stakedTokenIndex[tokenId];

        uint256 rewards = 0;
        for (uint256 period = 1; period <= 4; ++period) {
            uint256 periodSeconds = 180 * SECONDS_IN_DAY;
            uint256 startTime = _startTime + (period - 1) * periodSeconds;
            uint256 endTime = startTime + periodSeconds;

            if (block.timestamp > startTime) {
                uint256[] memory durations = getStakedTokenDurations(startTime, endTime);

                uint256 duration = durations[index];
                for (uint256 n = duration; n > 0; --n) {
                    uint256 numOfTokens = 0;
                    for (uint256 i = 0; i < durations.length; ++i) {
                        if (durations[i] >= n) {
                            numOfTokens += 1;
                        }
                    }
                    if (numOfTokens > 0) {
                        uint256 dividedRewards = _dailyRewards / numOfTokens;
                        rewards += dividedRewards;
                    }
                }
            }
        }
        return rewards;
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
