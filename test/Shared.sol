// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/Worker.sol";

// composable shared test setup
contract Shared is Test {

    address zenith_deployer = vm.addr(3902934);

    Beacon beacon;

    BeaconImplementation beacon_implementation;

    Controller controller;

    Worker worker_implementation;

    // deploys dev contracts and configures production env.
    function _devDeploy() internal {
        vm.startPrank(zenith_deployer);
        beacon = new Beacon();
        beacon_implementation = new BeaconImplementation();
        controller = new Controller();
        _setBeaconImplementation(address(beacon));
        vm.stopPrank();
    }

    function _setBeaconImplementation(address _impl) internal {
        beacon_implementation.setBeacon(_impl);
    }

}