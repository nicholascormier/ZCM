// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
import "../src/Controller.sol";
import "../src/Worker.sol";

// composable shared test setup
abstract contract Shared is Test {

    address zenith_deployer = vm.addr(420);
    address proxy_admin = vm.addr(69);
    address test_user = vm.addr(3493847394);

    // i do not like naming scheme. ProxyTester also handles beacon_proxy deployments if thats an option.
    Beacon beacon_proxy;
    BeaconImplementation beacon_forwarder;
    Worker worker_logic;
    Controller controller;

    ProxyTester proxy = new ProxyTester();

    function _devDeploy() internal {
        vm.startPrank(zenith_deployer);

        // main deployments
        beacon_proxy = new Beacon();
        beacon_forwarder = new BeaconImplementation();
        worker_logic = new Worker();
        Controller controller_logic = new Controller();

        // upgradeable proxy deployment
        proxy.setType("uups");
        address proxy_address = proxy.deploy(address(controller_logic), proxy_admin);
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

        controller = Controller(proxy_address);

        // configure controller inside beacon
        beacon_proxy.updateImplementation(address(worker_logic));
        beacon_forwarder.setBeacon(address(beacon_proxy));
        beacon_proxy.updateController(proxy_address);

        // configure proxy deployment
        controller.initialize();
        controller.setBeacon(address(beacon_proxy));
        controller.setWorkerTemplate(address(beacon_forwarder));

        vm.stopPrank();
    }

}