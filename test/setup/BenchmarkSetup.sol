// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";

import "../../src/Controller.sol";
import "../../src/Worker.sol";
import "../../lib/solady/src/utils/ERC1967Factory.sol";

contract BenchmarkSetup is Test{

    function _forkMainnet() internal {
        // Add our Etherscan API key to env
        vm.setEnv("ETHERSCAN_API_KEY", "2WCM87KHSJXKWN6YN74UFUFU9CFHKN7CHH");

        // Create the fork
        uint256 forkId = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/0OIPHqbatN-7jVKMVSJ5wv7NJKSX4Mlw");
        // Now, update vm to be using it
        vm.selectFork(forkId);
    }

}