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
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY_2");
        
        // Controller instance deployed
        Controller controller = Controller(payable(0x7e757c5A2715E00b7C14b8Ddf6945346C8D6884B));

        callers = [vm.addr(userPrivateKey)];
        
        // Start broadcasting our transactions
        vm.broadcast(deployerPrivateKey);
        controller.authorizeCallers(callers);

        vm.startBroadcast(userPrivateKey);
        controller.createWorkers(25);
        controller.createWorkers(50);
        controller.createWorkers(100);

        vm.stopBroadcast();
    }

}