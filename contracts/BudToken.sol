// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
contract BudToken is ERC20 {
	address[] _minters ;
	address[] _burners;

	constructor(address[] memory minters, address[] memory burners)
		ERC20('BudToken', 'Bud')
	{
		for (uint256 i = 0; i < minters.length; ++i) {
			_minters.push(minters[i]);
		}

		for (uint256 i = 0; i < burners.length; ++i) {
			_burners.push(burners[i]);
		}
	}

	function mint(address to, uint256 amount) public {
		// Only minters can mint
		// require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
		for (uint256 i = 0; i < _minters.length; ++i) {
			if (_minters[i] == msg.sender) {
				_mint(to, amount);
			}
		}
	}

	function burn(address from, uint256 amount) public {
		// Only burners can burn
		// require(_burners.in(msg.sender), "DOES_NOT_HAVE_BURNER_ROLE");
		for (uint256 i = 0; i < _burners.length; ++i) {
			if (_burners[i] == msg.sender) {
				_burn(from, amount);
			}
		}
	}
}
