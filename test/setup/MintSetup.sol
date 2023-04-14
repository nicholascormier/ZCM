// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Test.sol";

import "../../src/Controller.sol";

import "../mocks/nfts/Mock721.sol";
import "../mocks/nfts/Mock1155.sol";

contract MintSetup is Test {
    
    Mock721 nft = new Mock721();
    Mock1155 nft2 = new Mock1155();

    address private controller_deployer = vm.addr(2);

    function _deployWorkers(Controller controller) internal {
        vm.prank(controller_deployer);
        controller.createWorkers(250);
    }   

}