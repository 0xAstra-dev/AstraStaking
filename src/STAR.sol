// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STARToken is ERC20, Ownable {

    uint256 private constant _initialSupply = 100000000 * 10 ** 18;

    constructor() ERC20("STAR Token", "STAR") {
        _mint(msg.sender, _initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
