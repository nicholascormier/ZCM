// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/Worker.sol";

import "../src/Mock721.sol";

contract TestSuite is Test {

    // BEACON
    Beacon beacon;
    BeaconImplementation beacon_implementation;
    Controller controller;
    Worker worker_implementation;

    function setUp() external {
        _deployBeacon();
        _deployBeaconImplementation();
        _deployController();
    }

    function _deployController() internal {
        controller = new Controller();
    }

    function testWorkerImplementationUpdate() external {
        Worker first_implementation = new Worker();
        beacon.updateImplementation(address(first_implementation));
        address first_address = beacon.getImplementation();
        Worker second_implementation = new Worker();
        beacon.updateImplementation(address(second_implementation));
        address second_address = beacon.getImplementation();

        assertTrue(address(first_address) != address(second_implementation));
        
        worker_implementation = second_implementation;
    }

    function testControllerUpgrade() external {
        beacon.updateImplementation(address(worker_implementation));
        beacon_implementation.setBeacon(address(beacon));

        // idfk what the sample test factory is for
        // vm.prank(address(beacon));
        // controller.testCaller();
        beacon.updateController(address(controller));
        assertTrue(beacon.getControllerAddress() == address(controller));

        Controller new_controller = new Controller();
        beacon.updateController(address(new_controller));
        // vm.prank(address(new_controller));
        // controller.testCaller();
        assertTrue(beacon.getControllerAddress() == address(new_controller));
    }

    function _deployBeacon() internal {
        beacon = new Beacon();
    }

    function _deployBeaconImplementation() internal {
        beacon_implementation = new BeaconImplementation();
        beacon_implementation.setBeacon(address(beacon_implementation));
    }

}

