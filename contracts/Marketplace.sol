// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
//import "hardhat/console.sol";

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
contract Marketplace is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev The ERC20 Reward Token that will be distributed to stakers.
     */
    IERC20 public immutable seedsToken;

    uint256 private TOKEN_DECIMALS = 10 ** 18;

    uint256 constant MAX_REWARDS = 10000000 * 10 ** 18;

    enum OrderType {
        BUY,
        SELL
    }

    struct Order {
        /**
         * @dev 
         */
        bytes32 id;
        /**
         * @dev 
         */
        address owner;
        /**
         * @dev 
         */
        uint256 price;
        /**
         * @dev 
         */
        uint256 quantity;
        /**
         * @dev 
         */
        OrderType orderType;
        /**
         * @dev 
         */
        uint256 createdAt;
        /**
         * @dev 
         */
        uint256 expiration;
    }

    /**
     * @dev Struct that 
     */
    struct User {
        /**
         * @dev 
         */
        bytes32[] orders;
    }

    /**
     * @dev Mapping of stakers to their staking info.
     */
    mapping(address => User) users;
    /**
     * @dev 
     */
    Order[] public orderArray;
    /**
     * @dev 
     */
    mapping(bytes32 => uint256) public orderIdToArrayIndex;
    
    /**
     * @notice Constructor function that initializes the ERC20 and ERC721 interfaces.
     * @param _seedsToken - The address of the ERC20 Reward Token.
     */
    constructor(IERC20 _seedsToken) {
        seedsToken = _seedsToken;
        _setOperator(msg.sender);
    }

    function _setOperator(address operator) private {
        seedsToken.approve(operator, MAX_REWARDS);
    }

    function getOrderArray() public view returns (Order[] memory) {
        return orderArray;
    }

    function nextOrderId(OrderType orderType) public view returns (bytes32) {
        return keccak256(abi.encode(orderArray.length + 1, orderType));
    }

    function addOrder(uint256 quantity, uint256 price, uint256 expiration, OrderType orderType) private {
        bytes32 orderId = nextOrderId(orderType);
        orderArray.push(Order({
            id: orderId,
            owner: msg.sender,
            quantity: quantity, 
            price: price,
            orderType: orderType,
            createdAt: block.timestamp,
            expiration: expiration
        }));

        User storage user = users[msg.sender];
        user.orders.push(orderId);

        orderIdToArrayIndex[orderId] = orderArray.length - 1;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function addBuyOrder(uint256 quantity, uint256 price, uint256 expiration) payable external whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        uint256 totalPrice = (quantity * price) / TOKEN_DECIMALS;
        require(msg.value == totalPrice, "Insufficient cost");

        addOrder(quantity, price, expiration, OrderType.BUY);
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function addSellOrder(uint256 quantity, uint256 price, uint256 expiration) external whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        require(seedsToken.balanceOf(msg.sender) >= quantity, "Insufficient token");
        seedsToken.transferFrom(msg.sender, address(this), quantity);

        addOrder(quantity, price, expiration, OrderType.SELL);
    }

    function buyTokenByOrderId(bytes32 orderId, uint256 quantity) payable external whenNotPaused {
        Order storage order = getOrder(orderId);
        require(order.orderType == OrderType.SELL, "Invalid order type");
        require(order.quantity >= quantity, "Insufficient quantity");

        uint256 totalPrice = (quantity * order.price) / TOKEN_DECIMALS;
        require(totalPrice == msg.value, "Insufficient cost");

        require(seedsToken.balanceOf(address(this)) >= quantity, "Insufficient token");

        // Send ETH from buyer to seller
        payable(order.owner).transfer(msg.value);

        // Send SEEDS token to buyer
        seedsToken.transfer(msg.sender, quantity);

        order.quantity -= quantity;
    }

    function sellTokenByOrderId(bytes32 orderId, uint256 quantity) external whenNotPaused {
        Order storage order = getOrder(orderId);
        require(order.orderType == OrderType.BUY, "Invalid order type");
        require(order.quantity >= quantity, "Insufficient quantity");

        uint256 totalPrice = (quantity * order.price) / TOKEN_DECIMALS;
        require(address(this).balance >= totalPrice, "Insufficient cost");

        require(seedsToken.balanceOf(msg.sender) >= quantity, "Insufficient token");

        // Send ETH from contract to seller.
        payable(msg.sender).transfer(totalPrice);

        // Send SEEDS token to buyer (order owner) from seller (msg.sender).
        seedsToken.transferFrom(msg.sender, order.owner, quantity);

        order.quantity -= quantity;
    }

    function getOrders(address owner) public view returns (Order[] memory) {
        User storage user = users[owner];

        Order[] memory orders = new Order[](user.orders.length);
        for (uint256 i; i < user.orders.length; ++i) {
            uint256 index = orderIdToArrayIndex[user.orders[i]];
            orders[i] = orderArray[index];
        }
        return orders;
    }

    function getOrder(bytes32 orderId) internal view returns (Order storage) {
        uint256 index = orderIdToArrayIndex[orderId];
        require(index >= 0, "Invalid Order ID");
        return orderArray[index];
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
