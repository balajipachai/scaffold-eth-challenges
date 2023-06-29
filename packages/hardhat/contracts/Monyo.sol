// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Monyo is ERC20 {
    address public multisig;

    constructor(address _multisig, uint256 supply) ERC20("Monyo", "MNY") {
        require(_multisig != address(0), "Can't be address zero");
        require(supply > 0, "Supply can't be zero");
        _mint(_multisig, supply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
