// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "./Shared.sol";

contract Benchmarks is Test, Shared {


    function setUp() external {
        _devDeploy();
    }



}