// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";

import "../../src/Controller.sol";
import "../../src/Worker.sol";
import "../../lib/solady/src/utils/ERC1967Factory.sol";

contract ControllerSetup is Test{

    // Exportable reference variables
    ERC1967Factory factory;
    Controller controller;
    address controller_logic;
    address proxy_admin = vm.addr(3);
    address controller_deployer = vm.addr(2);

    address private test_user = vm.addr(0);
    address[] private authorized_users = [test_user];

    function _deployController() internal {
        // Change testing address
        vm.startPrank(controller_deployer);
        // Create factory
        factory = new ERC1967Factory();
        // Deploy controller and set proxy admin
        controller_logic = address(new Controller());
        controller = Controller(payable(factory.deploy(address(controller_logic), proxy_admin)));
        // Initialize the proxy (Ownable)
        controller.initialize();

        // Set up worker
        _setWorkerTemplate();
        vm.stopPrank();

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