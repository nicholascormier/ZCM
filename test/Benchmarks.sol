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

    function setUp() external {
        // shared
        _devDeployBase();
        _authorizeCallers();
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(250);
    }

    function testGasCosts() external {
        uint256 startGas = gasleft();

        Controller(proxy_address).callWorkers();

        uint256 usedGas = startGas - gasleft();
        console.log(usedGas);
    }

}