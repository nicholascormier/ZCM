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

contract ControllerTest is Test, Shared {

    function setUp() external {
        _devDeploy();
    }

    function testFailUnauthorizedController() external {
        controller.createWorkers(1);
    }    

    function testAuthorizeUser() external {
        vm.prank(zenith_deployer);
        controller.createWorkers(1);
    }   
}