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

    Controller controller_logic = new Controller();

    ProxyController controller_proxy;
    ProxyAdmin controller_admin;

    address test_user = vm.addr(3493847394);

    ProxyTester proxy = new ProxyTester();
    address proxy_address;
    address admin;

    function setUp() external {
        _devDeployBase();
        _deployProxySetup();
    }

    function _deployProxySetup() internal {
        vm.startPrank(zenith_deployer);
        admin = vm.addr(69);

        proxy.setType("uups");
        proxy_address = proxy.deploy(address(controller_logic), admin);

        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxy_address, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(controller_logic), addr);
        (bool success, bytes memory data) = address(proxy_address).call(abi.encodeWithSignature("initialize()"));
        vm.stopPrank();
    }

    function testUpgradeProxy() public {
        vm.prank(zenith_deployer);
        Controller newImpl = new Controller();
        proxy.upgrade(address(newImpl), admin, address(0));
        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxy_address, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(newImpl), addr);
    }

    function testAuthorizeUser() external {
        vm.startPrank(zenith_deployer);
        (bool success, bytes memory data) = address(proxy_address).call(abi.encodeWithSignature("authorizeCaller(address)", test_user));
        assertTrue(success);
        vm.stopPrank();
    }

    function testFailAuthorizeUser() external {
        vm.startPrank(vm.addr(382938473));
        (bool success, bytes memory data) = address(proxy_address).call(abi.encodeWithSignature("authorizeCaller(address)", test_user));
        assertTrue(success);
        vm.stopPrank();
    }

}