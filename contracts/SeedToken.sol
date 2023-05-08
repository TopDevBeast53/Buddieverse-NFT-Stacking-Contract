// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple ERC20 Smart Contract made for Rewards.

contract SeedToken is Ownable, AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private DECIMALS = 10 ** 18;

    uint256 private MAXIMUM_SUPPLY = 10000000 * DECIMALS;

    uint256 public _unitPrice = 1000 * DECIMALS;

    event Withdraw(address to, uint256 amount);

    event BuyToken(address from, address to, uint256 amount);

    constructor(address minter, address burner, uint256 unitPrice) ERC20("$SEEDS", "$SEEDS") {
        _setupRole(MINTER_ROLE, minter);
        _setupRole(BURNER_ROLE, burner);
        _unitPrice = unitPrice;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(
            totalSupply() + amount <= MAXIMUM_SUPPLY,
            "Total supply risks overflowing"
        );
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        uint256 balance = getBalance();
        require(balance >= amount, "Insufficient balance");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send Ether");

        emit Withdraw(to, amount);
    }

    function setUnitPrice(uint256 unitPrice) external onlyOwner {
        require(unitPrice > 0, "Incorrect price");
        _unitPrice = unitPrice;
    }

    function buy(address to, uint256 amount) public payable {
        require(
            totalSupply() + amount <= MAXIMUM_SUPPLY,
            "Total supply risks overflowing"
        );
        require(msg.value > 0, "Invalid cost");
        require((amount * _unitPrice) / DECIMALS <= msg.value, "Cost is insufficient");
        
        _mint(to, amount);
        emit BuyToken(msg.sender, to, amount);
    }
}
