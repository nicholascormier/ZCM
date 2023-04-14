// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";

import "../src/Worker.sol";
import "./mocks/MockWorker.sol";

contract ProxyTests is Test, Setup, ControllerSetup{

    function setUp() external{
        _deployController();
    }

    // First, upgrade controller via factory. Then make sure stored implementation in proxy contract matches new deployment
    function test_upgradeController() public {
        // Create new controller
        Controller new_controller = new Controller();

        // Perform the upgrade
        vm.prank(proxy_admin);
        factory.upgrade(address(controller), address(new_controller));
        
        // Make sure implementation slot updated
        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(address(controller), implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }

        // Equality assertion
        assertEq(address(new_controller), addr);
    }

    // Upgrade the worker using setWorkerTemplate. Then, create a worker and ensure new workers reflect the change
    function test_upgradeWorker() public {
        // Create new worker
        address new_worker = address(new MockWorker());

        // Upgrade worker template
        vm.prank(controller_deployer);
        controller.setWorkerTemplate(new_worker);

        // Create the new worker
        vm.startPrank(test_user);
        controller.createWorkers(1);

        // Verify the functionality of the new worker
        assertTrue(MockWorker(controller.getWorkers(test_user)[0]).impl() == 2);
    }

}