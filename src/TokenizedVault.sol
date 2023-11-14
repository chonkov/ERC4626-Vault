// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC4626, ERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {YieldToken} from "./mock/YieldToken.sol";

contract TokenizedVault is ERC4626 {
    YieldToken private _yield;

    constructor(string memory name_, string memory symbol_, IERC20 asset_) ERC20(name_, symbol_) ERC4626(asset_) {}

    function yieldToken() public view returns (address) {
        return address(_yield);
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 18;
    }
}
