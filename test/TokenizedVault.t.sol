// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenizedVault} from "../src/TokenizedVault.sol";
import {AssetToken} from "../src/mock/AssetToken.sol";
import {YieldToken} from "../src/mock/YieldToken.sol";

contract TokenizedVaultTest is Test {
    string public constant VAULT_NAME = "Tokenized Vault Token"; // Share's token `name`
    string public constant ASSET_NAME = "Mock Token"; // Asset's token `name`
    string public constant YIELD_NAME = "Dai";
    string public constant VAULT_SYMBOL = "TVT"; // Share's token `sumbol`
    string public constant ASSET_SYMBOL = "MTKN"; // Asset's token `sumbol`
    string public constant YIELD_SYMBOL = "DAI";
    AssetToken public asset;
    YieldToken public yield;
    TokenizedVault public vault;
    address owner = address(111);
    address user1 = address(222);
    address user2 = address(333);

    function setUp() public {
        vm.startPrank(owner);
        asset = new AssetToken(ASSET_NAME, ASSET_SYMBOL);
        yield = new YieldToken(YIELD_NAME, YIELD_SYMBOL);
        vault = new TokenizedVault(VAULT_NAME, VAULT_SYMBOL, IERC20(asset), address(yield));
        asset.transfer(user1, 1_000 ether);
        asset.transfer(user2, 1_000 ether);
        yield.transfer(address(vault), 5_000 ether);
        vm.stopPrank();
    }

    function test_SetUp() public {
        assertEq(vault.name(), VAULT_NAME);
        assertEq(vault.symbol(), VAULT_SYMBOL);
        assertEq(vault.decimals(), 18);
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
        uint256 assetsAmount = asset.balanceOf(user1);
        uint256 minShares = assetsAmount;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), assetsAmount);
        uint256 shares = vault.safeDeposit(assetsAmount, minShares, user1);
        vm.stopPrank();

        assertEq(vault.totalSupply(), assetsAmount);
        assertEq(vault.deposits(user1), timestamp);
        assertEq(vault.balanceOf(user1), shares);
        assertEq(asset.balanceOf(user1), 0);
        assertEq(asset.balanceOf(address(vault)), assetsAmount);
    }

    function test_SafeDeposit_Fail() public {
        uint256 assetsAmount = asset.balanceOf(user1);
        uint256 minShares = assetsAmount;

        vm.startPrank(user1);
        asset.approve(address(vault), assetsAmount);
        vm.expectRevert(
            abi.encodeWithSelector(TokenizedVault.TokenizedVault_Deposit_Slippage.selector, minShares, minShares - 1)
        );
        vault.safeDeposit(assetsAmount - 1, minShares, user1);
        vm.stopPrank();
    }

    function test_SafeMint() public {
        uint256 maxAssetsAmount = asset.balanceOf(user1) / 2;
        uint256 shares = maxAssetsAmount;
        uint256 timestamp = block.timestamp;

        vm.startPrank(user1);
        asset.approve(address(vault), shares * 2);
        uint256 assets = vault.safeMint(shares, maxAssetsAmount, user1);
        vm.stopPrank();

        assertEq(vault.totalSupply(), assets);
        assertEq(vault.deposits(user1), timestamp);
        assertEq(vault.balanceOf(user1), shares);
        assertEq(asset.balanceOf(user1), 500 ether);
    }

    function test_SafeMint_Fail() public {
        uint256 maxAssetsAmount = asset.balanceOf(user1) / 2;
        uint256 shares = maxAssetsAmount;

        vm.startPrank(user1);
        asset.approve(address(vault), shares * 2);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenizedVault.TokenizedVault_Mint_Slippage.selector, maxAssetsAmount + 1, maxAssetsAmount
            )
        );
        vault.safeMint(shares, maxAssetsAmount + 1, user1);
        vm.stopPrank();
    }
}
