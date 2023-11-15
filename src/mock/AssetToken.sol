// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AssetToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(_msgSender(), 10_000 ether);
    }
}
