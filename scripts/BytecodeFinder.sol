// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/Controller.sol";
import "../src/Worker.sol";

interface Create2Factory {
    function deploy(bytes memory _initCode, bytes32 _salt)
        external
    returns (address payable createdContract);
}

contract BytecodeFinder is Script {

    function run() public {
        // Change just these
        // Calculated controller address
        address controllerAddress = 0x61cF6C9268B300B40044D5001d00F0497E327400;
        // Calculated proxy admin address
        address proxyAdmin = 0x1000B90000B500F1aBF088afA9f4b30080aFa589;
        // Calculated proxy address
        address proxyAddress = 0x6400eA2024f6Dc5c55001b004Bb000C100d900F7;
        

        bytes memory proxyArgs = abi.encode(address(controllerAddress), address(proxyAdmin), "");
        bytes memory proxyBytecode = abi.encodePacked(vm.getCode("TransparentUpgradeableProxy.sol"), proxyArgs);

        console.logBytes(proxyBytecode);

        bytes memory workerArgs = abi.encode(address(proxyAddress));
        bytes memory workerBytecode = abi.encodePacked(vm.getCode("Worker.sol"), workerArgs);
        console.log("SEPERATION");
        console.logBytes(workerBytecode);
    }

}