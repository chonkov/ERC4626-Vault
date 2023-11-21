// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ProxyAdmin} from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {TokenizedVaultUpgradeable} from "../src/TokenizedVaultUpgradeable.sol";
import {YieldToken} from "../src/mock/YieldToken.sol";
import {AssetToken} from "../src/mock/AssetToken.sol";

contract TokenizedVaultScript is Script {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    string public constant VAULT_NAME = "Georgi Vault Dai"; // Share's token `name`
    string public constant ASSET_NAME = "Dai"; // Asset's token `name`
    string public constant YIELD_NAME = "Georgi Token";
    string public constant VAULT_SYMBOL = "gvDAI"; // Share's token `symbol`
    string public constant ASSET_SYMBOL = "DAI"; // Asset's token `symbol`
    string public constant YIELD_SYMBOL = "GT";

    ProxyAdmin admin;
    TransparentUpgradeableProxy proxy;
    TokenizedVaultUpgradeable implementation;
    AssetToken asset;
    YieldToken yield;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        asset = new AssetToken(ASSET_NAME, ASSET_SYMBOL);
        yield = new YieldToken(YIELD_NAME, YIELD_SYMBOL);

        admin = new ProxyAdmin(msg.sender);
        implementation = new TokenizedVaultUpgradeable();
        bytes memory data = abi.encodeWithSelector(
            TokenizedVaultUpgradeable.initialize.selector, VAULT_NAME, VAULT_SYMBOL, IERC20(asset), address(yield)
        );
        proxy = new TransparentUpgradeableProxy(address(implementation), address(admin), data);

        vm.stopBroadcast();
    }
}
