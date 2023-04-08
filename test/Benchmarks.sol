// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";

import "./samples/Mock721.sol";
import "./samples/Mock1155.sol";
import "./samples/MockImplementationOne.sol";
import "./samples/MockImplementationTwo.sol";
import "./samples/Mock721Revert.sol";
import "./samples/Multitest.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "./Shared.sol";

contract Benchmarks is Test, Shared {

    address multi;
    Controller controller;

    address[] callers;

    function setUp() external {
        // shared
        //_devDeployBase();
        //_authorizeCallers();
        vm.startPrank(test_user);
        controller = new Controller();
        controller.initialize();

        Worker worker = new Worker(address(controller));
        controller.setWorkerTemplate(address(worker));

        controller.authorizeCallers(authorizedCallers);

        controller.createWorkers(250);
        vm.stopPrank();
        multi = address(new Multitest());


    }

    function testGasCosts() external {
        vm.prank(test_user);
        controller.callWorkers(address(multi), abi.encodeWithSignature("mint(uint256)", 1), 0, 50, 0, true);
    }

}