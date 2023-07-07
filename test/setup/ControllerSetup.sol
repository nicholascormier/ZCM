// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";

import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../src/Controller.sol";
import "../../src/Worker.sol";

contract ControllerSetup is Test{

    // Exportable reference variables
    ProxyAdmin proxy_admin;
    Controller controller;
    Controller controller_logic;
    address controller_deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    address private test_user = vm.addr(4);
    address[] private authorized_users = [test_user];

    function _deployController() internal {
        // Change testing address
        vm.startPrank(controller_deployer);

         // First, deploy the ProxyAdmin
        proxy_admin = new ProxyAdmin();
        // Then, the controller logic
        controller_logic = new Controller();
        // Finally, the upgradeable proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(controller_logic), address(proxy_admin), "");

        controller = Controller(payable(proxy));
        // Initialize the proxy (Ownable)
        controller.initialize();
        vm.stopPrank();

        // Set up worker
        _setWorkerTemplate();

        // Authorize the test user
        _authorizeTestUser();
    }

    function _setWorkerTemplate() private {
        vm.startPrank(controller_deployer);
        // Create worker contract
        Worker worker = new Worker(address(controller));

        // Set the worker
        controller.setWorkerTemplate(address(worker));
        vm.stopPrank();
    }

    function _authorizeTestUser() private {
        vm.prank(controller_deployer);
        // Set the authorized user
        controller.authorizeCallers(authorized_users);
    }

}