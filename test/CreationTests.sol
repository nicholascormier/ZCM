// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";
import "./setup/AuthorizationSetup.sol";

import "../src/Worker.sol";

contract CreationTests is Test, Setup, ControllerSetup, AuthorizationSetup{

    address[] callers;

    function setUp() external{
        _deployController();

        // Authorize the test user
        vm.prank(controller_deployer);
        controller.authorizeCallers(authorized_user_array);

        // Create a worker (needed for every test)
        vm.prank(authorized_user);
    }

    // Should revert because caller is not controller
    function test_testCreations() public{
        vm.startPrank(controller_deployer);
        callers = [controller_deployer];
        controller.authorizeCallers(callers);

        controller.createWorkers(25);
        console.log("1 Worker Count", controller.getWorkers(controller_deployer).length);
        assertTrue(controller.getWorkers(controller_deployer).length == 25);

        controller.createWorkers(50);
        console.log("2 Worker Count", controller.getWorkers(controller_deployer).length);
        assertTrue(controller.getWorkers(controller_deployer).length == 75);

        controller.createWorkers(100);
        console.log("3 Worker Count", controller.getWorkers(controller_deployer).length);
        assertTrue(controller.getWorkers(controller_deployer).length == 175);
        
        controller.createWorkers(200);
        console.log("4 Worker Count", controller.getWorkers(controller_deployer).length);
        assertTrue(controller.getWorkers(controller_deployer).length == 375);
    }
}