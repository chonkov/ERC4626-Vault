// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../script/TokenizedVault.s.sol";
import {AssetToken} from "../../src/mock/AssetToken.sol";
import {YieldToken} from "../../src/mock/YieldToken.sol";

contract TokenizedVaultScriptTest is Test {
    TokenizedVaultScript public script;

    function test_Deployment() public {
        script = new TokenizedVaultScript();
        script.setUp();
        script.run();
    }
}
