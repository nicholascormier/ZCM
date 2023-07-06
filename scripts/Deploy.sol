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
        //uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        
        // Public address of deployer
        address zenith_deployer = 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF;
        // Canonical address for the CREATE2 factory
        address create2_factory = 0x0000000000FFe8B47B3e2130213B802212439497;
        
        // Start broadcasting our transactions
        vm.startBroadcast(deployerPrivateKey);

        // Create a reference to our Create2Factory
        Create2Factory factory = Create2Factory(0xce0042B868300000d44A59004Da54A005ffdcf9f);

        // Deploy our controller with specificed salt
        Controller controller = Controller(
            factory.deploy(vm.getCode("Controller.sol"), 0x59f6e7143d3ebe466b75d2031935a06ea11c529ebc567abfa84bb69b550b668d)
        );
        console.log("Controller Logic deployed to:", address(controller));
        // Deploy our ProxyAdmin
        ProxyAdmin admin = ProxyAdmin(
            factory.deploy(vm.getCode("ProxyAdmin.sol"), 0x87b0b9528f6e2b05ba55c74a37a00ba1e92a3afd7390b1ea6efceaad98dc40fe)
        );
        console.log("ProxyAdmin deployed to:", address(admin));
        // Calculate our Proxy bytecode
        bytes memory proxyArgs = abi.encode(address(controller), address(admin), "");
        bytes memory proxyBytecode = abi.encodePacked(vm.getCode("TransparentUpgradeableProxy.sol"), proxyArgs);

        Controller proxy = Controller(
            factory.deploy(proxyBytecode, 0xb4c2d827a7c7083862966848759b871a249a1a96db56c64557bb9bda1ed1d29c)
        );
        console.log("Controller Proxy deployed to:", address(proxy));

        // Initialize our proxy
        proxy.initialize();
        console.log("Controller Proxy initialized");

        // Now calculate Worker bytecode
        bytes memory workerArgs = abi.encode(address(proxy));
        bytes memory workerBytecode = abi.encodePacked(vm.getCode("Worker.sol"), workerArgs);

        Worker worker = Worker(
            factory.deploy(workerBytecode, 0xceac70283a7f23c6f6913b313ba96d9660a6dbfa4f103a5597b33c68a101ac13)
        );
        console.log("Worker deployed to:", address(worker));

        proxy.setWorkerTemplate(address(worker));
        console.log("Worker template set");
        vm.stopBroadcast();

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

        vm.stopBroadcast();
    }
}