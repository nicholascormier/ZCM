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
        // 0x59f6e7143d3ebe466b75d2031935a06ea11c529ebc567abfa84bb69b550b668d
        address controllerAddress = 0x4CeF00C5831a4FaC00404A00F1006bBb791E9600;
        // 0x87b0b9528f6e2b05ba55c74a37a00ba1e92a3afd7390b1ea6efceaad98dc40fe
        address proxyAdmin = 0x533A00007dAacFe2008e00fD008049cf3c00c8aD;
        // 0xb4c2d827a7c7083862966848759b871a249a1a96db56c64557bb9bda1ed1d29c
        address proxyAddress = 0x4A3e0026cFA294AAfC0000004cAC99330083aB8d;
        // 0xceac70283a7f23c6f6913b313ba96d9660a6dbfa4f103a5597b33c68a101ac13
        address worker = 0xa3f4001F00841d596Be5A4ce9e52860030000065;
        

        bytes memory proxyArgs = abi.encode(address(controllerAddress), address(proxyAdmin), "");
        bytes memory proxyBytecode = abi.encodePacked(vm.getCode("TransparentUpgradeableProxy.sol"), proxyArgs);

        console.logBytes(proxyBytecode);

        bytes memory workerArgs = abi.encode(address(proxyAddress));
        bytes memory workerBytecode = abi.encodePacked(vm.getCode("Worker.sol"), workerArgs);
        console.log("SEPERATION");
        console.logBytes(workerBytecode);

        /*vm.startBroadcast(deployerPrivateKey);

        // First, deploy the ProxyAdmin
        ProxyAdmin proxy_admin = new ProxyAdmin();
        // Then, the controller logic
        Controller controller_logic = new Controller();
        // Finally, the upgradeable proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(controller_logic), address(proxy_admin), "");

        address payable controller_proxy_address = payable(address(proxy));
        address controller_logic_address = address(controller_logic);

        Controller(controller_proxy_address).initialize();
        Worker worker_logic = new Worker(controller_proxy_address);
        address worker_logic_address = address(worker_logic);
        Controller(controller_proxy_address).setWorkerTemplate(worker_logic_address);

        console.log("Proxy admin:", address(proxy_admin));
        console.log("Proxy address:", address(proxy));
        console.log("Controller logic address:", address(controller_logic));
        console.log("Worker address:", address(worker_logic));

        vm.stopBroadcast();*/
    }

}