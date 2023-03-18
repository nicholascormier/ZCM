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

    Controller controller_logic;

    ProxyController controller_proxy;
    ProxyAdmin controller_admin;

    address test_user = vm.addr(3493847394);

    function setUp() external {
        _devDeployBase();
        // setup proxy contracts
        _configureControllerProxy();

        _authorizeUser(test_user);
    }

    function testFailUnauthorizedController() external {
        (bool success, ) = address(controller_proxy).call(abi.encodeWithSignature("createWorkers(uint256)", 1));
    }

    function _authorizeUser(address _user) internal {
        vm.startPrank(zenith_deployer);
        (bool success, bytes memory data) = address(controller_proxy).call(abi.encodeWithSignature("authorizeCaller(address)", _user));
        assertTrue(success);
        vm.stopPrank();
    }

    function _configureControllerProxy() internal {
        vm.startPrank(zenith_deployer);
        controller_logic = new Controller();

        assertTrue(controller_logic.owner() != zenith_deployer);

        ProxyAdmin admin = new ProxyAdmin();
        ProxyController proxy = new ProxyController(address(controller_logic), address(admin));

        controller_proxy = proxy;
        controller_admin = admin;

        vm.stopPrank();
    }

    function _implementationTest(address _impl) internal {
        vm.startPrank(zenith_deployer);
        (bool success, bytes memory data) = address(controller_proxy).call(abi.encodeWithSignature("implementation()"));
        assertTrue(success);
        (address _implementation) = abi.decode(data, (address));
        assertTrue(_impl == _implementation);
        vm.stopPrank();
    }

    function testInitialImplementation() external {
        _implementationTest(address(controller_logic));
    }

    function testUpdateImplementation() external {
        vm.startPrank(zenith_deployer);
        (bool success, bytes memory data) = address(controller_proxy).call(abi.encodeWithSignature("upgradeTo(address)"));
        assertTrue(success);
        vm.stopPrank();
        _implementationTest(address(controller_logic));
    }

}