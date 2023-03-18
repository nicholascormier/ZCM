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
        beacon = new Beacon();
        beacon_implementation = new BeaconImplementation();
        beacon_implementation.setBeacon(address(beacon));
        worker_implementation = new Worker();
        beacon.updateImplementation(address(worker_implementation));
        vm.stopPrank();
    }

}