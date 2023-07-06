// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Script.sol";
import "../../lib/forge-std/src/console.sol";

import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../src/Controller.sol";
import "../../src/Worker.sol";

contract Deployment is Script {

    address[] callers;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Controller instance deployed
        Controller controller = Controller(payable(0x4A3e0026cFA294AAfC0000004cAC99330083aB8d));

        callers = [vm.addr(vm.envUint("PRIVATE_KEY"))];
        
        // Start broadcasting our transactions
        vm.startBroadcast(deployerPrivateKey);

        controller.createWorkers(50);

        vm.stopBroadcast();
    }

}