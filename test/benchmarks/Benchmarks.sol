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
        controller.callWorkers(0x3399B6e00b350b226AA18D3D552D750c326Ee475, abi.encodeWithSignature("publicMint(uint256)", 1), 0, 25, 0, true);
    }

    // Comparing to Katana V2 Hayaoki mint (25 units - 1,998,743 gas)
    function test_hayaokiMint() external {
        // Set the stage for our mint
        vm.rollFork(16922864);

        // Execute our mint
        vm.prank(test_user);
        controller.callWorkers(0x3399B6e00b350b226AA18D3D552D750c326Ee475, abi.encodeWithSignature("publicMint(uint256)", 1), 0, 25, 0, true);
    }

    // Comparing to Katana V2 Hayaoki withdrawal (25 units - 329,331 gas)
    function test_hayaokiWithdraw() external {
        // Set the stage for our mint
        vm.rollFork(16922864);

        bytes[] memory cd = new bytes[](25);
        uint256[] memory values = new uint256[](25);
        uint256[] memory workerIndexes = new uint256[](25);

        address[] memory workers = controller.getWorkers(test_user);

        for(uint256 i = 1; i <= 25; i++){
            cd[i-1] = abi.encodeWithSignature("transferFrom(address,address,uint256)", workers[i-1], test_user, i);
            values[i-1] = 0;
            workerIndexes[i-1] = i-1;
        }

        // Execute our mint
        vm.prank(test_user);
        controller.callWorkersCustom(0x3399B6e00b350b226AA18D3D552D750c326Ee475, cd, values, workerIndexes, true);
    }

}