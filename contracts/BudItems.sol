// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract BudItems is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    struct TokenBalance {
        uint256 tokenId;
        uint256 balance;
    }

    /**
     * @dev Array of stakers addresses.
     */
    uint256[] public tokenIdArray;

    /**
     * @dev Mapping of tokenId to their array index.
     */
    mapping(uint256 => uint256) public tokenIdMap;

    constructor(string memory uri_) ERC1155(uri_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    function setURI(string memory newuri) public onlyAdmin {
        _setURI(newuri);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burnBatch(from, ids, amounts);
    }

    function ownedTokenBalances(address account) public view returns (TokenBalance[] memory) {
        TokenBalance[] memory tokenBalances = new TokenBalance[](tokenIdArray.length);

        for (uint256 i = 0; i < tokenIdArray.length; ++i) {
            uint256 tokenId = tokenIdArray[i];
            tokenBalances[i].tokenId = tokenId;
            tokenBalances[i].balance = balanceOf(account, tokenId);
        }

        return tokenBalances;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // Mint token
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 tokenId = ids[i];

                if (tokenIdMap[tokenId] == 0) {
                    tokenIdArray.push(tokenId);
                    tokenIdMap[tokenId] = tokenIdArray.length;
                }
            }
        }
    }
}
