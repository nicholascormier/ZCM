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
        Controller controller = Controller(payable(0x6400eA2024f6Dc5c55001b004Bb000C100d900F7));

        callers = [vm.addr(deployerPrivateKey)];
        
        // Start broadcasting our transactions
        vm.startBroadcast(deployerPrivateKey);
        controller.authorizeCallers(callers);

        controller.createWorkers(25);
        controller.createWorkers(50);
        controller.createWorkers(100);

        vm.stopBroadcast();
    }

}