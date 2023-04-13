// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
// import "hardhat/console.sol";

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

    uint256 constant SECONDS_IN_DAY = 86400;

    uint256 constant SECONDS_IN_PERIOD = SECONDS_IN_DAY * 180;

    /**
     * @dev Struct that holds the staking details for each user.
     */
    struct Staker {
        /**
         * @dev The array of Token Ids staked by the user.
         */
        uint256[] stakedTokenIds;
        /**
         * @dev The amount of ERC20 Reward Tokens that have not been claimed by the user.
         */
        uint256 unclaimedRewards;
    }

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
     * @notice Mapping of Token Id to it's index in the staker's stakedTokenIds array.
     */
    mapping(uint256 => uint256) public tokenIdToArrayIndex;

    uint256 private _startTime;

    uint256 private _lastUpdatedTime;

    /**
     * @notice Constructor function that initializes the ERC20 and ERC721 interfaces.
     * @param _nftCollection - The address of the ERC721 Collection.
     * @param _rewardsToken - The address of the ERC20 Reward Token.
     */
    constructor(IERC721 _nftCollection, IERC20 _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        _startTime = block.timestamp;
        _lastUpdatedTime = block.timestamp;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to stake.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function stake(uint256[] calldata _tokenIds) external whenNotPaused {
        updateRewards();
        
        Staker storage staker = stakers[msg.sender];
        if (staker.stakedTokenIds.length == 0) {
            stakersArray.push(msg.sender);
            stakerToArrayIndex[msg.sender] = stakersArray.length - 1;
        }

        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");

            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

            staker.stakedTokenIds.push(_tokenIds[i]);
            tokenIdToArrayIndex[_tokenIds[i]] = staker.stakedTokenIds.length - 1;
            stakerAddress[_tokenIds[i]] = msg.sender;
        }
    }

    /**
     * @notice Function used to withdraw ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokenIds.length > 0, "You have no tokens staked");

        updateRewards();

        uint256 lenToWithdraw = _tokenIds.length;
        for (uint256 i; i < lenToWithdraw; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);

            uint256 index = tokenIdToArrayIndex[_tokenIds[i]];
            uint256 lastTokenIndex = staker.stakedTokenIds.length - 1;
            if (index != lastTokenIndex) {
                staker.stakedTokenIds[index] = staker.stakedTokenIds[lastTokenIndex];
                tokenIdToArrayIndex[staker.stakedTokenIds[index]] = index;
            }
            staker.stakedTokenIds.pop();

            delete stakerAddress[_tokenIds[i]];

            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        if (staker.stakedTokenIds.length == 0) {
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
        require(staker.stakedTokenIds.length > 0, "You have no tokens staked");

        updateRewards();
        require(staker.unclaimedRewards > 0, "You have no rewards to claim");
        
        rewardsToken.safeTransfer(msg.sender, staker.unclaimedRewards);

        staker.unclaimedRewards = 0;
    }

    /**
     * @notice Function used to get the info for a user: the Token Ids staked and the available rewards.
     * @param _user - The address of the user.
     * @return _stakedTokenIds - The array of Token Ids staked by the user.
     * @return _availableRewards - The available rewards for the user.
     */
    function userStakeInfo(address _user)
        public
        view
        returns (uint256[] memory _stakedTokenIds, uint256 _availableRewards)
    {
        return (stakers[_user].stakedTokenIds, availableRewards(_user));
    }

    /**
     * @notice Function used to get the available rewards for a user.
     * @param _user - The address of the user.
     * @return _rewards - The available rewards for the user.
     * @dev This includes both the rewards stored but not claimed and the rewards accumulated since the last update.
     */
    function availableRewards(address _user) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_user];
        if (staker.stakedTokenIds.length == 0) {
            return staker.unclaimedRewards;
        }

        (uint256[] memory rewardArray, ) = getRewards();
        for (uint256 i; i < rewardArray.length; ++i) {
            if (_user == stakersArray[i]) {
                _rewards += rewardArray[i];
            }
        }
    }

    function stakedTokenAmount() public view returns (uint256 amount) {
        amount = 0;
        for (uint256 i; i < stakersArray.length; ++i) {
            amount += stakers[stakersArray[i]].stakedTokenIds.length;
        }
    }

    /**
     * @notice Function used to update the rewards for a user.
     */
    function updateRewards() private {
        uint256 tokenAmount = stakedTokenAmount();
        if (tokenAmount <= 0) return;

        (uint256[] memory rewardArray, uint256 updatedTime) = getRewards();
        for (uint256 i; i < rewardArray.length; i++) {
            Staker storage staker = stakers[stakersArray[i]];
            staker.unclaimedRewards = rewardArray[i];
        }
        _lastUpdatedTime = updatedTime;

        /*console.log("Staking Status:");
        for (uint256 i; i < rewardArray.length; ++i) {
            console.log("\tUser", stakersArray[i]);
            console.log("\t\tReward", stakers[stakersArray[i]].unclaimedRewards);
            console.log("\t\tTokens", stakers[stakersArray[i]].stakedTokenIds.length);
        }*/
    }

    function getRewards() private view returns (uint256[] memory _rewards, uint256 _updatedTime) {
        uint256 len = stakersArray.length;
        require(len > 0, "There is no staked tokens");

        _rewards = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            _rewards[i] = stakers[stakersArray[i]].unclaimedRewards;
        }

        uint256 tokenAmount = stakedTokenAmount();
        if (tokenAmount <= 0) return (_rewards, _lastUpdatedTime);

        _updatedTime = _lastUpdatedTime;
        for (uint256 period = 1; period <= 4; ++period) {
            uint256 startTime = _startTime + (period - 1) * SECONDS_IN_PERIOD;
            if (block.timestamp <= startTime) {
                break;
            }

            uint256 endTime = Math.min(block.timestamp, startTime + SECONDS_IN_PERIOD);
            uint256 dailyRewards = (periodRewards(period) / 180) / tokenAmount;

            for (uint256 i; i < len; ++i) {
                Staker memory staker = stakers[stakersArray[i]];
                
                for (uint256 n; n < staker.stakedTokenIds.length; ++n) {
                    if (endTime > _updatedTime) {
                        uint256 elapsed = (endTime - _updatedTime) / SECONDS_IN_DAY;
                        _rewards[i] += elapsed * dailyRewards;
                    }
                }
                
                _updatedTime = endTime;
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
