// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Beacon is Ownable{

    address private implementationAddress;
    address private controllerAddress;

    function updateImplementation(address _implementation) external onlyOwner {
        implementationAddress = _implementation;
    }

    function updateController(address _controllerAddress) external onlyOwner {
        controllerAddress = _controllerAddress;
    }

    function getControllerAddress() external view returns(address) {
        return controllerAddress;
    }

    function getImplementation() external view returns(address) {
        return implementationAddress;
    }

}

