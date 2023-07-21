// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
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
contract BudMarket is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when order is created.
     */
    event AddOffer(Order order);
    /**
     * @dev Emitted when order is removed.
     */
    event RemoveOffer(Order order);
    /**
     * @dev mitted when `from` address sell tokens from the `order`
     */
    event SellToken(address indexed from, Order order, uint256 quantity);
    /**
     * @dev Emitted when `from` address buy tokens from the `order`
     */
    event BuyToken(address indexed from, Order order, uint256 quantity);

    /**
     * @dev The ERC20 Reward Token that will be distributed to stakers.
     */
    IERC1155 public immutable nftCollection;

    uint256 private TOKEN_DECIMALS = 10 ** 18;

    uint256 constant MAX_ALLOWANCE = 10000000 * 10 ** 18;

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
        uint256 tokenId;
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
     * @dev
     */
    uint256 uniqueOrderIndex = 0;

    /**
     * @notice Constructor function that initializes the Marketplace.
     * @param _nftCollection - The address of the ERC1155.
     */
    constructor(IERC1155 _nftCollection) {
        nftCollection = _nftCollection;
    }

    function getOrderArray() public view returns (Order[] memory) {
        return orderArray;
    }

    function nextOrderId(
        address owner,
        OrderType orderType,
        uint256 uniqueIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(owner, orderType, uniqueIndex));
    }

    function migrate(address payable _to) external payable onlyOwner {
        require(address(this).balance > 0, "No balance");

        // Send ETH from contract to new contract.
        bool sent = _to.send(address(this).balance);

        require(sent, "Failed to send Ether");
    }

    function addOrders(Order[] calldata _orders) external payable onlyOwner {
        for (uint256 i; i < _orders.length; i++) {
            Order memory order = _orders[i];

            _addOrder(
                order.owner,
                order.tokenId,
                order.quantity,
                order.price,
                order.expiration,
                order.orderType
            );
        }
    }

    function _addOrder(
        address owner,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 expiration,
        OrderType orderType
    ) private {
        uniqueOrderIndex++;
        bytes32 orderId = nextOrderId(owner, orderType, uniqueOrderIndex);

        Order memory order = Order({
            id: orderId,
            owner: owner,
            tokenId: tokenId,
            quantity: quantity,
            price: price,
            orderType: orderType,
            createdAt: block.timestamp,
            expiration: expiration
        });
        orderArray.push(order);

        User storage user = users[owner];
        user.orders.push(orderId);

        orderIdToArrayIndex[orderId] = orderArray.length - 1;

        emit AddOffer(order);
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function addBuyOrder(
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 expiration
    ) external payable whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        uint256 totalPrice = Math.mulDiv(quantity, price, TOKEN_DECIMALS);
        require(msg.value == totalPrice, "Insufficient cost");

        _addOrder(
            msg.sender,
            tokenId,
            quantity,
            price,
            expiration,
            OrderType.BUY
        );
    }

    /**
     * @notice Function used to add sell order.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function addSellOrder(
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 expiration
    ) external whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        require(
            nftCollection.balanceOf(msg.sender, tokenId) >= quantity,
            "Insufficient token"
        );

        // Send token to buyer
        nftCollection.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            quantity,
            "0x00"
        );

        _addOrder(
            msg.sender,
            tokenId,
            quantity,
            price,
            expiration,
            OrderType.SELL
        );
    }

    function updateBuyOrder(
        bytes32 orderId,
        uint256 quantity,
        uint256 price,
        uint256 expiration
    ) external payable whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        Order storage order = getOrder(orderId);
        require(order.owner == msg.sender, "Not owner");
        require(order.orderType == OrderType.BUY, "Invalid order type");

        uint256 oldPrice = Math.mulDiv(
            order.quantity,
            order.price,
            TOKEN_DECIMALS
        );
        uint256 newPrice = Math.mulDiv(quantity, price, TOKEN_DECIMALS);

        if (newPrice > oldPrice) {
            uint256 amount = newPrice - oldPrice;
            require(msg.value == amount, "Invalid cost");
        } else if (oldPrice > newPrice) {
            uint256 amount = oldPrice - newPrice;
            require(address(this).balance >= amount, "Insufficient balance");

            // Send ETH from contract to sender.
            payable(msg.sender).transfer(amount);
        }

        order.quantity = quantity;
        order.price = price;
        order.expiration = expiration;
    }

    function updateSellOrder(
        bytes32 orderId,
        uint256 quantity,
        uint256 price,
        uint256 expiration
    ) external whenNotPaused {
        require(quantity > 0, "Invalid quantity");
        require(price > 0, "Invalid unit price");

        Order storage order = getOrder(orderId);
        require(order.owner == msg.sender, "Not owner");
        require(order.orderType == OrderType.SELL, "Invalid order type");

        if (order.quantity > quantity) {
            uint256 amount = order.quantity - quantity;
            require(
                nftCollection.balanceOf(address(this), order.tokenId) >= amount,
                "Insufficient token"
            );

            // Send token to sender
            nftCollection.safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId,
                amount,
                "Withdraw from sell order"
            );
        } else if (quantity > order.quantity) {
            uint256 amount = quantity - order.quantity;
            require(
                nftCollection.balanceOf(msg.sender, order.tokenId) >= amount,
                "Insufficient token"
            );

            // Receive token from sender
            nftCollection.safeTransferFrom(
                msg.sender,
                address(this),
                order.tokenId,
                amount,
                "Deposit to sell order"
            );
        }

        order.quantity = quantity;
        order.price = price;
        order.expiration = expiration;
    }

    function removeOrder(bytes32 orderId) external payable whenNotPaused {
        Order storage order = getOrder(orderId);
        require(order.owner == msg.sender, "Not owner");
        require(order.quantity >= 0, "Empty offer");

        if (order.orderType == OrderType.BUY) {
            uint256 totalPrice = Math.mulDiv(
                order.quantity,
                order.price,
                TOKEN_DECIMALS
            );
            require(
                address(this).balance >= totalPrice,
                "Insufficient balance"
            );

            // Send ETH from contract to owner.
            payable(msg.sender).transfer(totalPrice);
        } else {
            require(
                nftCollection.balanceOf(address(this), order.tokenId) >=
                    order.quantity,
                "Insufficient token"
            );

            // Send NFT.
            nftCollection.safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId,
                order.quantity,
                "Remove order"
            );
        }

        uint256 index = orderIdToArrayIndex[orderId];
        uint256 lastOrderIndex = orderArray.length - 1;
        if (index != lastOrderIndex) {
            orderArray[index] = orderArray[lastOrderIndex];
            orderIdToArrayIndex[orderArray[index].id] = index;
        }
        orderArray.pop();

        // Remove order from users order list.
        User storage user = users[msg.sender];
        for (uint256 i; i < user.orders.length; ++i) {
            if (user.orders[i] == orderId) {
                uint256 lastIndex = user.orders.length - 1;
                if (i != lastIndex) {
                    user.orders[i] = user.orders[lastIndex];
                }
                user.orders.pop();
                break;
            }
        }

        emit RemoveOffer(order);
    }

    function buyTokenByOrderId(
        bytes32 orderId,
        uint256 quantity
    ) external payable whenNotPaused {
        Order storage order = getOrder(orderId);
        require(order.orderType == OrderType.SELL, "Invalid order type");
        require(order.quantity >= quantity, "Insufficient quantity");

        uint256 totalPrice = Math.mulDiv(quantity, order.price, TOKEN_DECIMALS);
        require(totalPrice == msg.value, "Insufficient cost");

        require(
            nftCollection.balanceOf(address(this), order.tokenId) >= quantity,
            "Insufficient token"
        );

        // Send ETH from buyer to seller
        payable(order.owner).transfer(msg.value);

        // Send NFT to buyer
        nftCollection.safeTransferFrom(
            address(this),
            msg.sender,
            order.tokenId,
            quantity,
            "Buy NFT"
        );

        order.quantity -= quantity;

        emit BuyToken(msg.sender, order, quantity);
    }

    function sellTokenByOrderId(
        bytes32 orderId,
        uint256 quantity
    ) external whenNotPaused {
        Order storage order = getOrder(orderId);
        require(order.orderType == OrderType.BUY, "Invalid order type");
        require(order.quantity >= quantity, "Insufficient quantity");

        uint256 totalPrice = Math.mulDiv(quantity, order.price, TOKEN_DECIMALS);
        require(address(this).balance >= totalPrice, "Insufficient balance");

        require(
            nftCollection.balanceOf(msg.sender, order.tokenId) >= quantity,
            "Insufficient token"
        );

        // Send ETH from contract to seller.
        payable(msg.sender).transfer(totalPrice);

        // Send NFT to buyer (order owner) from seller (msg.sender).
        nftCollection.safeTransferFrom(
            msg.sender,
            order.owner,
            order.tokenId,
            quantity,
            "Sell NFT"
        );

        order.quantity -= quantity;

        emit SellToken(msg.sender, order, quantity);
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
