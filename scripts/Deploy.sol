// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";


contract Deploy is Script {

    function run() public {
        //uint256 deployerPrivateKey = vm.envUint("5ac33826d95194142614df54f1e5c50745d6b0ac169ba8bda73907eceb2120f3");
        //uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        
        address zenith_deployer = 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF;

        vm.startBroadcast();

        // First, deploy the ProxyAdmin
        ProxyAdmin proxy_admin = new ProxyAdmin();
        // Then, the controller logic
        Controller controller_logic = new Controller();
        // Finally, the upgradeable proxy
        bytes memory _data;
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(controller_logic), address(proxy_admin), _data);

        address payable controller_proxy_address = payable(address(proxy));
        address controller_logic_address = address(controller_logic);

        Controller(controller_proxy_address).initialize();
        Worker worker_logic = new Worker(controller_proxy_address);
        address worker_logic_address = address(worker_logic);
        Controller(controller_proxy_address).setWorkerTemplate(worker_logic_address);

        console.log("Controller proxy address:");
        console.log(controller_proxy_address);
        console.log("");

        console.log("Controller logic address:");
        console.log(controller_logic_address);
        console.log("");

        console.log("Worker proxy address:");
        console.log(worker_logic_address);
        console.log("");

        vm.stopBroadcast();
    }

}