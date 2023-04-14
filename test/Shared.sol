// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";
import "../src/EthSender.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";
import "../lib/solady/src/utils/ERC1967Factory.sol";

// TODO Rename this to something other than "Shared"
abstract contract Shared is Test {

    address zenith_deployer = vm.addr(3902934);
    Worker worker_implementation;

    address private controller_logic;
    address admin = vm.addr(34234224);
    Controller controller;
    ERC1967Factory factory;
    address test_user = vm.addr(3493847394);

    address[] authorizedCallers = [test_user, vm.addr(398798350)];

    function _authorizeCallers() internal {
        vm.prank(zenith_deployer);
        controller.authorizeCallers(authorizedCallers);
    }

    function _deauthorizeCallers() internal {
        vm.prank(zenith_deployer);
        controller.deauthorizeCallers(authorizedCallers);
    }

    // configures on-chain dependencies.
    function _devDeployBase() internal {
        vm.startPrank(zenith_deployer);

        factory = new ERC1967Factory();
        controller_logic = address(new Controller());
        controller = Controller(payable(factory.deploy(address(controller_logic), admin)));
        // controller = new Controller();
        controller.initialize();

        Worker worker = new Worker(address(controller));
        controller.setWorkerTemplate(address(worker));

        controller.authorizeCallers(authorizedCallers);
        vm.stopPrank();
    }

    function convert(uint256 n) private returns (bytes32) {
        return bytes32(n);
    }

}