// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../test/mocks/nfts/DumpsterRatz.sol";
import "../test/mocks/nfts/Goofies.sol";
import "../test/mocks/nfts/HeadFirst.sol";
import "../test/mocks/nfts/BlockTurtles.sol";

contract Deploy is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        
        // Start broadcasting our transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy all test contracts
        DumpsterRatz ratz = new DumpsterRatz();
        ratz.setPaused();
        console.log("Ratz deployed to:", address(ratz));

        Goofies goofies = new Goofies();
        goofies.setPaused(false);
        console.log("Goofies deployed to:", address(goofies));

        HeadFirst head = new HeadFirst("");
        head.setPause(false);
        console.log("HeadFirst deployed to:", address(head));

        BlockTurtles turtles = new BlockTurtles("");
        turtles.setPaused(false);
        console.log("BlockTurtles deployed to:", address(turtles));

        vm.stopBroadcast();
    }

}