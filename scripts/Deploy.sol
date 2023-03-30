// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";


contract Deploy is Script {

    function run() public {
        // uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        
        address zenith_deployer = 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF;

        ProxyTester proxy = new ProxyTester();
        proxy.setType("uups");

        vm.startBroadcast();

        Controller controller_logic = new Controller();
        Worker worker_logic = new Worker();

        address payable controller_proxy_address = payable(proxy.deploy(address(controller_logic), zenith_deployer));
        address controller_logic_address = address(controller_logic);
        address worker_logic_address = address(worker_logic);

        Controller(controller_proxy_address).initialize();
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