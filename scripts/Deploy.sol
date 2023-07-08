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

contract Deploy is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // All of our salts to deploy with
        bytes32 controllerSalt = 0xdb4995dc3464bd5da086c78f961b6fb249a94b5d02cc0f729b0d8c022e7aafa9;
        bytes32 proxyAdminSalt = 0xf60e64efa01da575c43a85888f23b0b87c205ada4b1af880397d2d5088e2e914;
        bytes32 proxySalt = 0x542e74bd75b1428fe7af568d4aea3d01cfb647c3d2a026407c4ed95c20ebec0f;
        bytes32 workerSalt = 0x48f25acdc931fb1236a06d6127b124175bfda977d852f013433ae3d8f6841016;
        
        // Canonical address for the CREATE2 factory
        address create2_factory = 0xce0042B868300000d44A59004Da54A005ffdcf9f;
        
        // Start broadcasting our transactions
        vm.startBroadcast(deployerPrivateKey);

        // Create a reference to our Create2Factory
        Create2Factory factory = Create2Factory(create2_factory);

        // Deploy our controller with specificed salt
        Controller controller = Controller(
            factory.deploy(vm.getCode("Controller.sol"), controllerSalt)
        );
        console.log("Controller Logic deployed to:", address(controller));
        // Deploy our ProxyAdmin
        ProxyAdmin admin = ProxyAdmin(
            factory.deploy(vm.getCode("ProxyAdmin.sol"), proxyAdminSalt)
        );
        console.log("ProxyAdmin deployed to:", address(admin));
        // Calculate our Proxy bytecode
        bytes memory proxyArgs = abi.encode(address(controller), address(admin), "");
        bytes memory proxyBytecode = abi.encodePacked(vm.getCode("TransparentUpgradeableProxy.sol"), proxyArgs);

        Controller proxy = Controller(
            factory.deploy(proxyBytecode, proxySalt)
        );
        console.log("Controller Proxy deployed to:", address(proxy));

        // Initialize our proxy
        proxy.initialize();
        console.log("Controller Proxy initialized");

        // Now calculate Worker bytecode
        bytes memory workerArgs = abi.encode(address(proxy));
        bytes memory workerBytecode = abi.encodePacked(vm.getCode("Worker.sol"), workerArgs);

        Worker worker = Worker(
            factory.deploy(workerBytecode, workerSalt)
        );
        console.log("Worker deployed to:", address(worker));

        proxy.setWorkerTemplate(address(worker));
        console.log("Worker template set");
        vm.stopBroadcast();
    }

}

contract DeployNoSalt is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // First, deploy the ProxyAdmin
        ProxyAdmin proxy_admin = new ProxyAdmin();
        // Then, the controller logic
        Controller controller_logic = new Controller();
        // Finally, the upgradeable proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(controller_logic), address(proxy_admin), "");

        // Define the Controller
        Controller controller = Controller(payable(proxy));
        controller.initialize();

        // Create the worker logic
        Worker worker_logic = new Worker(payable(controller));
        controller.setWorkerTemplate(address(worker_logic));

        console.log("Proxy admin:", address(proxy_admin));
        console.log("Proxy address:", address(proxy));
        console.log("Controller logic address:", address(controller_logic));
        console.log("Worker address:", address(worker_logic));

        vm.stopBroadcast();
    }
}