// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenizedVaultUpgradeable} from "../../src/TokenizedVaultUpgradeable.sol";
import {AssetToken} from "../../src/mock/AssetToken.sol";
import {YieldToken} from "../../src/mock/YieldToken.sol";

contract TokenizedVaultUpgradeableTest is Test {
    string public constant VAULT_NAME = "Georgi Vault Dai"; // Share's token `name`
    string public constant ASSET_NAME = "Dai"; // Asset's token `name`
    string public constant YIELD_NAME = "Georgi Token";
    string public constant VAULT_SYMBOL = "gvDAI"; // Share's token `symbol`
    string public constant ASSET_SYMBOL = "DAI"; // Asset's token `symbol`
    string public constant YIELD_SYMBOL = "GT";
    AssetToken public asset;
    YieldToken public yield;
    TokenizedVaultUpgradeable public vault;
    address owner = address(111);
    address user1 = address(222);
    address user2 = address(333);

    function setUp() public {
        vm.startPrank(owner);
        asset = new AssetToken(ASSET_NAME, ASSET_SYMBOL);
        yield = new YieldToken(YIELD_NAME, YIELD_SYMBOL);
        vault = new TokenizedVaultUpgradeable();
        vault.initialize(VAULT_NAME, VAULT_SYMBOL, IERC20(asset), address(yield));
        asset.transfer(user1, 1_000 ether);
        asset.transfer(user2, 1_000 ether);
        yield.transfer(address(vault), 5_000 ether);
        vm.stopPrank();
    }

    function test_SetUp() public {
        assertEq(vault.name(), VAULT_NAME);
        assertEq(vault.symbol(), VAULT_SYMBOL);
        assertEq(vault.decimals(), 21);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.asset(), address(asset));
        assertEq(vault.yield(), address(yield));
        assertEq(asset.totalSupply(), 10_000 ether);
        assertEq(asset.balanceOf(owner), 8_000 ether);
        assertEq(yield.totalSupply(), 10_000 ether);
        assertEq(yield.balanceOf(owner), 5_000 ether);
    }

    function test_SafeDeposit() public {
        uint256 assets = asset.balanceOf(user1);
        uint256 minShares = assets * 1_000; // * by 1000 because of `_decimalsOffset()`
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), assets);
        uint256 shares = vault.safeDeposit(assets, minShares, user1);
        vm.stopPrank();

        assertEq(vault.totalSupply(), assets * 1_000);
        assertEq(vault.deposits(user1), timestamp);
        assertEq(vault.balanceOf(user1), shares);
        assertEq(asset.balanceOf(user1), 0);
        assertEq(asset.balanceOf(address(vault)), assets);
    }

    function test_SafeDeposit_Fail() public {
        uint256 assets = asset.balanceOf(user1);
        uint256 minShares = assets * 1_000;

        vm.startPrank(user1);
        asset.approve(address(vault), assets);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVaultUpgradeable.TokenizedVaultUpgradeable_Deposit_Exceeded.selector,
                minShares,
                minShares - 1_000
            )
        );
        vault.safeDeposit(assets - 1, minShares, user1);
        vm.stopPrank();
    }

    function test_SafeMint() public {
        uint256 maxAssets = asset.balanceOf(user1);
        uint256 shares = maxAssets * 1_000;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), maxAssets);
        uint256 assets = vault.safeMint(shares, maxAssets, user1);
        vm.stopPrank();

        assertEq(vault.totalSupply(), assets * 1_000);
        assertEq(vault.deposits(user1), timestamp);
        assertEq(vault.balanceOf(user1), shares);
        assertEq(asset.balanceOf(user1), 0);
    }

    function test_SafeMint_Fail() public {
        uint256 maxAssets = asset.balanceOf(user1); // 1_000
        uint256 shares = maxAssets * 1_000; // 1_000_000

        vm.startPrank(user1);
        asset.approve(address(vault), maxAssets);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVaultUpgradeable.TokenizedVaultUpgradeable_Mint_Exceeded.selector, maxAssets - 1, maxAssets
            )
        );
        vault.safeMint(shares, maxAssets - 1, user1);
        vm.stopPrank();
    }

    function test_SafeWithdraw() public {
        uint256 assets = asset.balanceOf(user1);
        uint256 minShares = assets * 1_000;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), assets);
        uint256 shares = vault.safeDeposit(assets, minShares, user1);

        vm.warp(timestamp + 1 days);

        uint256 maxShares = minShares;
        uint256 yieldAmount;
        (shares, yieldAmount) = vault.safeWithdraw(assets, maxShares, user1, user1);
        vm.stopPrank();

        assertEq(yield.balanceOf(user1), yieldAmount);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.deposits(user1), timestamp + 1 days);
        assertEq(vault.balanceOf(user1), 0);
        assertEq(asset.balanceOf(user1), assets);
        assertEq(asset.balanceOf(address(vault)), 0);
    }

    function test_SafeWithdraw_Fail() public {
        uint256 assets = asset.balanceOf(user1);
        uint256 minShares = assets * 1_000;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), assets);
        uint256 shares = vault.safeDeposit(assets, minShares, user1);

        vm.warp(timestamp + 1 days);

        uint256 maxShares = shares - 1; // 999_999
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVaultUpgradeable.TokenizedVaultUpgradeable_Withdraw_Exceeded.selector, maxShares, shares
            )
        );
        vault.safeWithdraw(assets, maxShares, user1, user1);
        vm.stopPrank();
    }

    function test_SafeRedeem() public {
        uint256 maxAssets = asset.balanceOf(user1);
        uint256 shares = maxAssets * 1_000;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), maxAssets);
        uint256 assets = vault.safeMint(shares, maxAssets, user1);

        vm.warp(timestamp + 1 days);

        uint256 minAssets = assets;
        uint256 yieldAmount;
        (shares, yieldAmount) = vault.safeRedeem(shares, minAssets, user1, user1);
        vm.stopPrank();

        assertEq(yield.balanceOf(user1), yieldAmount);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.deposits(user1), timestamp + 1 days);
        assertEq(vault.balanceOf(user1), 0);
        assertEq(asset.balanceOf(user1), assets);
        assertEq(asset.balanceOf(address(vault)), 0);
    }

    function test_SafeRedeem_Fail() public {
        uint256 maxAssets = asset.balanceOf(user1);
        uint256 shares = maxAssets * 1_000;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), maxAssets);
        uint256 assets = vault.safeMint(shares, maxAssets, user1);

        assertEq(assets, maxAssets);

        vm.warp(timestamp + 1 days);

        uint256 minAssets = assets + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVaultUpgradeable.TokenizedVaultUpgradeable_Redeem_Exceeded.selector, minAssets, assets
            )
        );
        vault.safeRedeem(shares, minAssets, user1, user1);
        vm.stopPrank();
    }

    function test_ClaimYield() public {
        uint256 assets = asset.balanceOf(user1);
        uint256 minShares = assets;

        vm.startPrank(user1);
        asset.approve(address(vault), assets);
        vault.safeDeposit(assets, minShares, user1);

        vm.warp(1 days);

        assert(vault.claimYield(user1) == 0);
        vm.stopPrank();

        vm.warp(2 days);

        vm.prank(user2);
        vm.expectRevert(TokenizedVaultUpgradeable.TokenizedVaultUpgradeable_Unauthorized.selector);
        vault.claimYield(user1);

        vm.prank(user1);
        vault.approve(user2, 1);

        vm.prank(user2);
        uint256 yieldRewards = vault.claimYield(user1);

        assertEq(yieldRewards, 100e18);
        assertEq(vault.deposits(user1), 2 days);
    }
}
