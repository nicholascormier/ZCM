// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";
import "./setup/AuthorizationSetup.sol";

import "../src/Worker.sol";
import "./mocks/MockWorker.sol";

contract WorkerTests is Test, Setup, ControllerSetup, AuthorizationSetup{

    function setUp() external{
        _deployController();

        // Authorize the test user
        vm.prank(controller_deployer);
        controller.authorizeCallers(authorized_user_array);

        // Create a worker (needed for every test)
        vm.prank(authorized_user);
        controller.createWorkers(1);
    }

    // Should revert because caller is not controller
    function test_directWorkerAccess() public{
        address worker = controller.getWorkers(authorized_user)[0];

        // Call worker directly and expect it to fail
        vm.prank(authorized_user);
        (bool success, ) = worker.call(abi.encodeWithSignature("mint(uint256)", 1));

        assertTrue(success == false);
    }

    // Should revert because user is no longer authorized
    function test_workerAuthorizationRevoked() public {
        address worker = controller.getWorkers(authorized_user)[0];

        // Create the array to pass in
        uint256[] memory workers = new uint256[](1);
        workers[0] = 0;

        // Make sure callWorkers doesnt revert
        vm.prank(authorized_user);
        controller.callWorkers(address(this), "", 0, 1, 0, true);

        // Now revoke user access
        vm.prank(controller_deployer);
        controller.deauthorizeCallers(authorized_user_array);

        // Run callWorkers again (this time should revert)
        vm.prank(authorized_user);
        vm.expectRevert();
        controller.callWorkers(address(this), "", 0, 1, 0, true);
    }

    // Should reactivate previously deactivated workers (checks to make sure when someone is unauthorized their old workers aren't deleted)
    function test_workerAuthorizationReinstated() public {
        address worker = controller.getWorkers(authorized_user)[0];

        // Create the array to pass in
        uint256[] memory workers = new uint256[](1);
        workers[0] = 0;

        // Reuse the old test
        test_workerAuthorizationRevoked();

        // Now, reinstate access
        vm.prank(controller_deployer);
        controller.authorizeCallers(authorized_user_array);

        // Run callWorkers again (shouldn't revert because authorized and workers still exist)
        vm.prank(authorized_user);
        controller.callWorkers(address(this), "", 0, 1, 0, true);
    }

}