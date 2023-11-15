// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {YieldToken} from "./mock/YieldToken.sol";

contract TokenizedVault is ERC4626 {
    YieldToken private _yield;
    mapping(address depositer => uint256 timestamp) _deposits;

    error TokenizedVault_Deposit_Slippage(uint256 minExpected, uint256 actual);
    error TokenizedVault_Mint_Slippage(uint256 maxExpected, uint256 actual);
    error TokenizedVault_Withdraw_Slippage(uint256 maxExpected, uint256 actual);
    error TokenizedVault_Redeem_Slippage(uint256 minExpected, uint256 actual);

    constructor(string memory name_, string memory symbol_, IERC20 asset_, address yield_)
        ERC20(name_, symbol_)
        ERC4626(asset_)
    {
        _yield = YieldToken(yield_);
    }

    function safeDeposit(uint256 assets, uint256 minShares, address receiver) public returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        if (minShares > shares) revert TokenizedVault_Deposit_Slippage(minShares, shares);

        _deposits[receiver] = block.timestamp;

        return shares;
    }

    function safeMint(uint256 shares, uint256 maxAssets, address receiver) public returns (uint256) {
        uint256 assets = super.mint(shares, receiver);

        if (maxAssets > assets) revert TokenizedVault_Mint_Slippage(maxAssets, shares);

        _deposits[receiver] = block.timestamp;

        return assets;
    }

    function safeWithdraw(uint256 assets, uint256 maxShares, address receiver, address owner)
        public
        returns (uint256, uint256)
    {
        uint256 accumulatedTime = block.timestamp - _deposits[owner];
        uint256 yieldAmount = claimYield(owner, accumulatedTime);
        delete _deposits[owner];

        uint256 shares = super.withdraw(assets, receiver, owner);

        if (shares > maxShares) revert TokenizedVault_Withdraw_Slippage(maxShares, shares);

        return (shares, yieldAmount);
    }

    function safeRedeem(uint256 shares, uint256 minAssets, address receiver, address owner)
        public
        returns (uint256, uint256)
    {
        uint256 accumulatedTime = block.timestamp - _deposits[owner];
        uint256 yieldAmount = claimYield(owner, accumulatedTime);
        delete _deposits[owner];

        uint256 assets = super.redeem(shares, receiver, owner);

        if (assets < minAssets) revert TokenizedVault_Redeem_Slippage(minAssets, shares);

        return (assets, yieldAmount);
    }

    function claimYield(address owner, uint256 accumulatedTime) public returns (uint256) {
        uint256 yieldAmount = _calculateYield(owner, accumulatedTime);
        if (owner != _msgSender() && allowance(owner, _msgSender()) < yieldAmount) revert();

        SafeERC20.safeTransfer(_yield, owner, yieldAmount);

        _deposits[owner] = block.timestamp;
        return yieldAmount;
    }

    function _calculateYield(address owner, uint256 accumulatedTime) internal view returns (uint256) {
        uint256 daysPassed = (accumulatedTime / 1 days);
        return daysPassed * balanceOf(owner) * 100 * 1e18 / totalSupply();
    }

    function deposits(address depositer) public view returns (uint256) {
        return _deposits[depositer];
    }

    function yield() public view returns (address) {
        return address(_yield);
    }
}
