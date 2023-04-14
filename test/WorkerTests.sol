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
        address worker = controller.getWorkers(test_user)[0];

        // Call worker directly and expect it to fail
        vm.prank(authorized_user);
        (bool success, ) = worker.call(abi.encodeWithSignature("mint(uint256)", 1));

        assertTrue(success == false);
    }

    // Should revert because user is no longer authorized
    function test_workerAuthorizationRevoked() public {
        // Send some ether to the worker
        address worker = controller.getWorkers(test_user)[0];
        vm.deal(worker, 1 ether);

        // Create the array to pass in
        uint256[] memory workers;
        workers[0] = 0;

        // Now withdraw the eth from the worker
        vm.prank(authorized_user);
        controller.withdrawFromWorkers(workers, payable(authorized_user));

        // Make sure worker balance is zero
        assertTrue(worker.balance == 0);

        // Now revoke user access and deal eth again
        vm.prank(controller_deployer);
        controller.deauthorizeCallers(authorized_user_array);

        // Deal ETH again
        vm.deal(worker, 1 ether);

        // Now no change in ether balance should occur
        vm.prank(authorized_user);
        controller.withdrawFromWorkers(workers, payable(authorized_user));

        assertTrue(worker.balance == 1 ether);
    }

    // Should reactivate previously deactivated workers (checks to make sure when someone is unauthorized their old workers aren't deleted)
    function test_workerAuthorizationReinstated() public {
        address worker = controller.getWorkers(test_user)[0];

        // Create the array to pass in
        uint256[] memory workers;
        workers[0] = 0;

        // Reuse the old test
        test_workerAuthorizationRevoked();

        // Now, reinstate access
        vm.prank(controller_deployer);
        controller.authorizeCallers(authorized_user_array);

        // Withdraw the ether
        vm.prank(authorized_user);
        controller.withdrawFromWorkers(workers, payable(authorized_user));

        // Make sure worker balance is zero
        assertTrue(worker.balance == 0);
    }

}