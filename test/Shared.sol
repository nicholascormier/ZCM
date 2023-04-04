// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

// composable shared test setup
abstract contract Shared is Test {

    address zenith_deployer = vm.addr(3902934);
    Worker worker_implementation;
    ProxyTester proxy = new ProxyTester();

    address payable proxy_address;
    address controller_logic;
    address admin;
    address test_user = vm.addr(3493847394);

    address[] authorizedCallers = [test_user, vm.addr(398798350)];

    function _authorizeCallers() internal {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCallers(authorizedCallers);
    }

    function _deauthorizeCallers() internal {
        vm.prank(zenith_deployer);
        Controller(proxy_address).deauthorizeCallers(authorizedCallers);
    }

    // configures on-chain dependencies.
    function _devDeployBase() internal {
        vm.startPrank(zenith_deployer);

        // Create the controller
        Controller controller = new Controller();
        controller_logic = address(controller);

        // Set up ProxyAdmin and DelegateProxy
        admin = address(new ProxyAdmin());
        proxy_address = payable(address(new TransparentUpgradeableProxy(address(controller), admin, "")));

        // Make sure the proxy is pointing to the controller
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

        // Initialize the controller
        Controller(proxy_address).initialize();

        // Set up worker and controller
        worker_implementation = new Worker{salt: ""}(proxy_address);
        Controller(proxy_address).setWorkerTemplate(address(worker_implementation));
        vm.stopPrank();
    }

    function convert(uint256 n) private returns (bytes32) {
        return bytes32(n);
    }

}