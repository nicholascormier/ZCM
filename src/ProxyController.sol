//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ProxyController is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin) TransparentUpgradeableProxy(_logic, _admin, "") {}
}