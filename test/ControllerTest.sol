// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/Worker.sol";
import "../src/EthSender.sol";

import "./samples/Mock721.sol";
import "./samples/Mock1155.sol";
import "./samples/MockImplementationOne.sol";
import "./samples/MockImplementationTwo.sol";
import "./samples/Mock721Revert.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "./Shared.sol";

contract ControllerTest is Test, Setup {

    Mock721 NFT = new Mock721();
    Mock1155 NFT2 = new Mock1155();

    bytes[] data;
    bytes[][] recursiveData;
    uint256[] values;
    uint256[][] recursiveValues;
    uint256[] recursiveTotalValues;
    uint256[] workerIndexes;

    function setUp() external {
        // shared
        _devDeployBase();
        _authorizeCallers();
    }

    // this is not really testing anything :)
    function testUpgradeProxy() public {
        // Create new controller
        Controller newImpl = new Controller();

        // Perform the upgrade
        vm.prank(admin);
        factory.upgrade(address(controller), newImpl);
        
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
        assertEq(address(newImpl), addr);
    }

    function testDeauthorizeUser() external {
        vm.prank(test_user);
        // Create a worker
        controller.createWorkers(1);
        // Deauthorize test user
        _deauthorizeCallers();

        // Expect Controller to revert
        vm.expectRevert();
        vm.prank(test_user);
        controller.createWorkers(1);
    }

    function testUnauthorizedCaller() external {
        // Expect Controller to revert (because never was authorized)
        vm.expectRevert();
        controller.createWorkers(1);
    }

    function testWorkerCreation() external {
        // Expect controller to create a worker
        vm.prank(test_user);
        controller.createWorkers(1);

        // Expect workers to be 1
        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(workers.length == 1);
    }

    // TODO Delete this
    function testWorkerForwarding() external {
        // Create a worker
        vm.prank(test_user);
        controller.createWorkers(1);
        address[] memory workers = controller.getWorkers(test_user);

        // Expect the worker address deployed to have a response
        address response = Worker(payable(workers[1])).getBasicResponse();
        assertTrue(response == workers[1]);
    }

    // TODO Delete this
    function testWorkerDirectAccess() external {
        vm.prank(test_user);
        address[] memory workers = controller.getWorkers(test_user);
        vm.expectRevert();
        Worker(payable(workers[1])).getBasicResponseProtected();
    }

    // TODO Rewrite this
    uint256[] ww = [1];
    function testWorkerAccessRevoked() external {
        _workerAccess();
    }

    // TODO Rewrite this
    function testWorkerAccessReinstated() external {
        _workerAccess();
        _deauthorizeCallers();

        vm.expectRevert();
        vm.prank(test_user);
        controller.withdrawFromWorkers(ww, payable(test_user));
    }

    // Delete this (refactor into the tests)
    function _workerAccess() internal {
        vm.startPrank(test_user);
        controller.createWorkers(1);
        controller.withdrawFromWorkers(ww, payable(test_user));
        vm.stopPrank();
    }

    // Refactor this into Shared
    function _mintTestSetup(uint256 workerCount) internal {
        vm.pauseGasMetering();
        NFT = new Mock721();
        NFT2 = new Mock1155();

        vm.startPrank(test_user);
        controller.createWorkers(workerCount);
        vm.stopPrank();
        vm.resumeGasMetering();
    }

    

    function testWithdrawFromWorker() external {
        _mintTestSetup(1);
        vm.startPrank(test_user);

        address[] memory workers = controller.getWorkers(test_user);

        vm.deal(test_user, 1 ether);
        workers[1].call{value: 1 ether}("");

        assertTrue(workers[1].balance == 1 ether);
        
        workerIndexes = [1];

        controller.withdrawFromWorkers(workerIndexes, payable(test_user));
        // tx.origin is not a known address - figure out vm cheat code
        // address does not have any excess eth for some reason
        assertTrue(test_user.balance == 1 ether);
        vm.stopPrank();
    }

    function testFallback() external {
        _mintTestSetup(1);
        // Controller controller = controller;
        // uint160 addy = uint160(bytes20(0x0D24e6e50EeC8A1f1DeDa82d94590098A7E664B4));
        // controller.callWorkersFallback()
        vm.deal(test_user, 100 ether);
        vm.prank(test_user);
        // original call
        // controller.callWorkersFallback(address(NFT), abi.encodePacked(bytes4(keccak256("mint()")), address(0x0D24e6e50EeC8A1f1DeDa82d94590098A7E664B4)), 0, 1, 0, false);
        //controller.callWorkersFallback(workerdata, 1, 0, false);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, 0, true);

        vm.stopPrank();
    } 

}