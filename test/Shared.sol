// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/Worker.sol";

// composable shared test setup
abstract contract Shared is Test {

    address zenith_deployer = vm.addr(3902934);
    Beacon beacon;
    BeaconImplementation beacon_implementation;
    Worker worker_implementation;

    // configures on-chain dependencies.
    function _devDeployBase() internal {
        vm.startPrank(zenith_deployer);
        beacon = new Beacon{salt: convert(0)}();
        beacon_implementation = new BeaconImplementation{salt: convert(1)}();
        console.log(address(beacon), "beacon addy");
        console.log(address(beacon_implementation), "implementation addy");
        worker_implementation = new Worker();
        beacon.updateImplementation(address(worker_implementation));
        vm.stopPrank();
    }

    function convert(uint256 n) private returns (bytes32) {
        return bytes32(n);
    }

}