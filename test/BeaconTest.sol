// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/Worker.sol";

import "./samples/Mock721.sol";
import "./samples/Mock1155.sol";
import "./samples/MockImplementationOne.sol";
import "./samples/MockImplementationTwo.sol";

import "./Shared.sol";

contract BeaconTest is Test, Shared {

    function setUp() external {
        _devDeploy();
    }

    function testBeaconUpdate() external {
        vm.startPrank(zenith_deployer);
        ImplOne testImplOne = new ImplOne();
        ImplTwo testImplTwo = new ImplTwo();

        // test implOne
        beacon.updateImplementation(address(testImplOne));
        assertTrue(beacon.getImplementation() == address(testImplOne));
        (bool successOne, bytes memory dataOne) = address(beacon_implementation).call(abi.encodeWithSignature("impl()"));
        assertTrue(successOne);
        (uint256 testOne) = abi.decode(dataOne, (uint256));
        assertTrue(testOne == 1);

        // test implTwo
        beacon.updateImplementation(address(testImplTwo));
        assertTrue(beacon.getImplementation() == address(testImplTwo));
        (bool successTwo, bytes memory dataTwo) = address(beacon_implementation).call(abi.encodeWithSignature("impl()"));
        assertTrue(successTwo);
        (uint256 testTwo) = abi.decode(dataTwo, (uint256));
        assertTrue(testTwo == 2);

        vm.stopPrank();
    }

    function testControllerUpgrade() external {
        ImplOne cOne = new ImplOne();
        ImplTwo cTwo = new ImplTwo();

        vm.prank(zenith_deployer);
        beacon.updateController(address(cOne));
        assertTrue(beacon.getControllerAddress() == address(cOne));

        cOne.workerTest(address(beacon_implementation));

        vm.prank(zenith_deployer);
        beacon.updateController(address(cTwo));
        assertTrue(beacon.getControllerAddress() == address(cTwo));

        cTwo.workerTest(address(beacon_implementation));

        vm.expectRevert();
        cOne.workerTest(address(beacon_implementation));
    }

}

