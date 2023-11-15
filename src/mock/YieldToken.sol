// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract YieldToken is Ownable, ERC20 {
    constructor(string memory name_, string memory symbol_) Ownable(_msgSender()) ERC20(name_, symbol_) {
        _mint(_msgSender(), 10_000 ether);
    }
}
