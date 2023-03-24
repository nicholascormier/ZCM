// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";

import "./samples/Mock721.sol";
import "./samples/Mock1155.sol";
import "./samples/MockImplementationOne.sol";
import "./samples/MockImplementationTwo.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "./Shared.sol";

contract ControllerTest is Test, Shared {

    function setUp() external {
        _devDeploy();
    }

    function testAuthorizeUser() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);
    }

    function testDeauthorizeUser() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);

        vm.prank(zenith_deployer);
        controller.deauthorizeCaller(test_user);

        vm.expectRevert();
        vm.prank(test_user);
        controller.createWorkers(1);
    }

    function testUnauthorizedCaller() external {
        vm.expectRevert();
        controller.createWorkers(1);
    }

    function testAuthorizedCaller() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);
    }

    function testWorkerCreation() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);
        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(workers.length == 2);
        assertTrue(workers[0] == test_user);
    }

    function testWorkerForwarding() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);
        address[] memory workers = controller.getWorkers(test_user);

        address response = Worker(workers[1]).getBasicResponse();
        assertTrue(response == workers[1]);
    }

    function testWorkerDirectAccess() external {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.createWorkers(1);
        address[] memory workers = controller.getWorkers(test_user);
        vm.expectRevert();
        Worker(workers[1]).getBasicResponseProtected();
    }

    uint256[] ww = [1];
    function testWorkerAccessRevoked() external {
        _workerAccess();
    }

    function testWorkerAccessReinstated() external {
        _workerAccess();
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        controller.withdrawFromWorkers(ww);
    }

    // saves some lines.
    function _workerAccess() internal {
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.startPrank(test_user);
        controller.createWorkers(1);
        controller.withdrawFromWorkers(ww);
        vm.stopPrank();

        vm.prank(zenith_deployer);
        controller.deauthorizeCaller(test_user);

        vm.expectRevert();

        vm.prank(test_user);
        controller.withdrawFromWorkers(ww);
    }

    function test721Mint() external {
        Mock721 NFT = new Mock721();
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.startPrank(test_user);
        controller.createWorkers(1);

        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, ww, false, 0);
        vm.stopPrank();
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

    function test1155Mint() external {
        Mock1155 NFT = new Mock1155();
        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.startPrank(test_user);
        controller.createWorkers(1);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, ww, false, 0);
        vm.stopPrank();
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1], 0) == 1);
    }

}