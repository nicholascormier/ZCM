// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/Worker.sol";

// composable shared test setup
abstract contract Shared is Test {

    address zenith_deployer = vm.addr(3902934);
    Worker worker_implementation;

    // configures on-chain dependencies.
    function _devDeployBase() internal {
        vm.startPrank(zenith_deployer);
        worker_implementation = new Worker{salt: ""}();
        vm.stopPrank();
    }

    function convert(uint256 n) private returns (bytes32) {
        return bytes32(n);
    }

}