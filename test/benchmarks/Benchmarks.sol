// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../setup/Setup.sol";
import "../setup/ControllerSetup.sol";
import "../setup/BenchmarkSetup.sol";

interface NFT {
    function publicMint(uint256) external;
    function ownerOf(uint256) external returns(address);
}

contract Benchmarks is Test, Setup, ControllerSetup, BenchmarkSetup {

    function setUp() external{
        _deployController();
        
        // Deploy controllers
        vm.prank(test_user);
        controller.createWorkers(300);

        _forkMainnet();
    }

    // Comparing to Katana V2 Hayaoki mint (25 units - 1,998,743 gas)
    function test_hayaokiMint() external {
        // Set the stage for our mint
        vm.rollFork(16922864);

        // Set up the mint state
        address nft = 0x3399B6e00b350b226AA18D3D552D750c326Ee475;
        vm.startPrank(0xd22751a2b759d47993A6bDC466ECEfa0BdDCaF0a);
        nft.call(abi.encodeWithSignature("setState(uint8)", 2));
        nft.call(abi.encodeWithSignature("setNoCost(uint256)", 1));
        nft.call(abi.encodeWithSignature("setNoCostLimit(uint256)", 800));
        nft.call(abi.encodeWithSignature("setSalePrice(uint256)", 3000000000000000));
        nft.call(abi.encodeWithSignature("setMaxTx(uint256)", 20));
        vm.stopPrank();

        // Execute our mint
        vm.prank(test_user);
        controller.callWorkers(nft, abi.encodeWithSignature("publicMint(uint256)", 1), 0, 25, 0, true);
    }

}