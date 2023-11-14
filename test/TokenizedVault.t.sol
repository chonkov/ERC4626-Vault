// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {TokenizedVault} from "../src/TokenizedVault.sol";
import {AssetToken} from "../src/mock/AssetToken.sol";
import {YieldToken} from "../src/mock/YieldToken.sol";

contract TokenizedVaultTest is Test {
    string public constant VAULT_NAME = "Tokenized Vault Token";
    string public constant TOKEN_NAME = "USD Coin";
    string public constant VAULT_SYMBOL = "TVT";
    string public constant TOKEN_SYMBOL = "USDC";
    AssetToken public asset;
    YieldToken public yield;
    TokenizedVault public vault;

    function setUp() public {
        asset = new AssetToken(TOKEN_NAME, TOKEN_SYMBOL);
        vault = new TokenizedVault(VAULT_NAME, VAULT_SYMBOL, IERC20(asset));
    }

    function test_SetUp() public {
        assertEq(vault.name(), VAULT_NAME);
        assertEq(vault.symbol(), VAULT_SYMBOL);
        assertEq(vault.decimals(), 36);
    }
}
