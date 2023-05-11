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

    uint256 constant MAX_REWARDS = 3000000 * 10 ** 18;

    struct Order {
        /**
         * @dev 
         */
        uint256 orderId;
        /**
         * @dev 
         */
        uint256 productId;
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
        uint256 timestamp;
    }

    struct Product {
        /**
         * @dev 
         */
        uint256 productId;
        /**
         * @dev 
         */
        address owner;
        /**
         * @dev 
         */
        uint256 amount;
        /**
         * @dev 
         */
        uint256 price;
        /**
         * @dev 
         */
        uint256 timestamp;
        /**
         * @dev 
         */
        uint256[] orders;
    }

    /**
     * @dev Struct that 
     */
    struct User {
        /**
         * @dev 
         */
        uint256[] products;
        /**
         * @dev 
         */
        uint256[] orders;
    }

    /**
     * @dev Mapping of stakers to their staking info.
     */
    mapping(address => User) users;
    /**
     * @dev 
     */
    Product[] public productArray;
    /**
     * @dev 
     */
    mapping(uint256 => uint256) public productIdToArrayIndex;
    /**
     * @dev 
     */
    Order[] public orderArray;
    /**
     * @dev 
     */
    mapping(uint256 => uint256) public orderIdToArrayIndex;
    
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

    function nextProductId() public view returns (uint256) {
        return productArray.length + 1;
    }

    function nextOrderId() public view returns (uint256) {
        return orderArray.length + 1;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function addProduct(uint256 amount, uint256 price) external whenNotPaused {
        require(amount > 0, "Invalid amount");
        require(price > 0, "Invalid price");

        require(seedsToken.balanceOf(msg.sender) >= amount, "Can't register tokens you don't own!");
        seedsToken.transferFrom(msg.sender, address(this), amount);

        uint256 productId = nextProductId();
        productArray.push(Product({
            productId: productId,
            owner: msg.sender,
            amount: amount, 
            price: price, 
            timestamp: block.timestamp,
            orders: new uint256[](0)
        }));

        User storage seller = users[msg.sender];
        seller.products.push(productId);
    }

    function makeOrder(uint256 productId, uint256 price) external whenNotPaused {
        require(price > 0, "Invalid price");

        Product storage product = _getProduct(productId);
        require(price >= product.price, "Order price must more than product");

        uint256 orderId = nextOrderId();
        orderArray.push(Order({
            orderId: orderId,
            productId: productId,
            owner: msg.sender,
            price: price,
            timestamp: block.timestamp
        }));

        product.orders.push(orderId);

        User storage buyer = users[msg.sender];
        buyer.orders.push(orderId);
    }

    function sellProduct(uint256 productId, uint256 orderId) payable external whenNotPaused {
        Product memory product = getProduct(productId);
        Order memory order = getOrder(orderId);

        uint256 amount = product.amount;
        require(seedsToken.balanceOf(address(this)) >= amount, "Can't add product you don't own!");
        
        // Send SEEDS token to buyer
        seedsToken.transfer(msg.sender, amount);

        // Send ether to seller from buyer
        payable(product.owner).transfer(msg.value);

        // Remove the product and orders from array
        for (uint256 i; i < product.orders.length; ++i) {
            removeOrder(product.orders[i]);
        }
        removeProduct(productId);

        // Update products in the seller.
        User storage seller = users[product.owner];
        for (uint256 i; i < seller.products.length; ++i) {
            if (seller.products[i] == productId) {
                uint256 lastIndex = seller.products.length - 1;
                if (i != lastIndex) {
                    seller.products[i] = seller.products[lastIndex];
                }
                seller.products.pop();
                break;
            }
        }

        User storage buyer = users[order.owner];
        for (uint256 i; i < buyer.orders.length; ++i) {
            Order memory item = getOrder(buyer.orders[i]);
            if (item.productId == productId || buyer.orders[i] == orderId) {
                uint256 lastIndex = buyer.orders.length - 1;
                if (i != lastIndex) {
                    buyer.orders[i] = buyer.orders[lastIndex];
                }
                buyer.orders.pop();
            }
        }
    }

    function getProducts() public view returns (Product[] memory) {
        User storage user = users[msg.sender];

        Product[] memory products = new Product[](user.products.length);
        for (uint256 i; i < user.products.length; ++i) {
            uint256 index = productIdToArrayIndex[user.products[i]];
            products[i] = productArray[index];
        }
        return products;
    }

    function getOrders() public view returns (Order[] memory) {
        User storage user = users[msg.sender];

        Order[] memory orders = new Order[](user.orders.length);
        for (uint256 i; i < user.orders.length; ++i) {
            uint256 index = orderIdToArrayIndex[user.orders[i]];
            orders[i] = orderArray[index];
        }
        return orders;
    }

    function _getProduct(uint256 productId) internal view returns (Product storage) {
        uint256 index = productIdToArrayIndex[productId];
        require(index >= 0, "Invalid Product ID");
        return productArray[index];
    }

    function getProduct(uint256 productId) public view returns (Product memory) {
        uint256 index = productIdToArrayIndex[productId];
        require(index >= 0, "Invalid Product ID");
        return productArray[index];
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        uint256 index = orderIdToArrayIndex[orderId];
        require(index >= 0, "Invalid Order ID");
        return orderArray[index];
    }

    function removeProduct(uint256 productId) private {
        uint256 index = productIdToArrayIndex[productId];
        uint256 lastProductIndex = productArray.length - 1;
        if (index != lastProductIndex) {
            productArray[index] = productArray[lastProductIndex];
            productIdToArrayIndex[productArray[index].productId] = index;
        }
        productArray.pop();
        delete productIdToArrayIndex[productId];
    }

    function removeOrder(uint256 orderId) private {
        uint256 index = orderIdToArrayIndex[orderId];
        uint256 lastOrderIndex = orderArray.length - 1;
        if (index != lastOrderIndex) {
            orderArray[index] = orderArray[lastOrderIndex];
            orderIdToArrayIndex[orderArray[index].orderId] = index;
        }
        orderArray.pop();
        delete orderIdToArrayIndex[orderId];
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
