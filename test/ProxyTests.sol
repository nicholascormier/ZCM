// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";

import "../src/Worker.sol";
import "./mocks/MockWorker.sol";

contract ProxyTests is Test, Setup, ControllerSetup{

    function setUp() external{
        _deployController();
    }

    // First, upgrade controller via factory. Then make sure stored implementation in proxy contract matches new deployment
    function test_upgradeController() public {
        
    }

    function test_upgradeWorker() public {

    }

}