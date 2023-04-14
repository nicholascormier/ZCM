// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";
import "./setup/AuthorizationSetup.sol";

contract AuthorizationTests is Test, Setup, ControllerSetup, AuthorizationSetup {

    // Test setup function
    function setUp() external{
        _deployController();
    }

    // Start test as unauthorized user and expect createWorkers to revert
    function test_unauthorizedCall() public{
        vm.prank(authorized_user);
        vm.expectRevert();
        controller.createWorkers(1);
    }

    // Start test as authorized user and expect createWorkers to create a worker
    function test_authorizedCall() public{
        // First, authorize the user
        vm.prank(controller_deployer);
        controller.authorizeCallers(authorized_user_array);

        // Now, try to use createWorkers
        vm.prank(authorized_user);
        controller.createWorkers(1);

        // Validate createWorkers ran
        assertTrue(controller.getWorkers(authorized_user).length == 1);
    }

    // Start test as authorized user and expect createWorkers to run, become deauthorized, then expect createWorkers to revert
    function test_unauthorizeUser() public{
        // We can recycle our test from earlier
        test_authorizedCall();

        // Now we deauthorize the user
        vm.prank(controller_deployer);
        controller.deauthorizeCallers(authorized_user_array);

        // We recycle our unauthorized test now
        test_unauthorizedCall();
    }
}