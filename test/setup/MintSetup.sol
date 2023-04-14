// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";

import "../../src/Controller.sol";

import "../mocks/nfts/Mock721.sol";
import "../mocks/nfts/Mock1155.sol";

contract MintSetup is Test {
    
    Mock721 nft = new Mock721();
    Mock1155 nft2 = new Mock1155();

    address private test_user = vm.addr(4);

    function _deployWorkers(Controller controller) internal {
        vm.prank(test_user);
        controller.createWorkers(250);
    }   

}