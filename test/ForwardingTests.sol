// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";

import "./setup/Setup.sol";
import "./setup/ControllerSetup.sol";
import "./setup/MintSetup.sol";

import "../src/Worker.sol";
import "./mocks/MockWorker.sol";


contract ForwardingTests is Test, Setup, ControllerSetup, MintSetup{

    function setUp() external{
        // Create workers
        _deployController();
        _deployWorkers(controller);
    }

    // Simple test of the base callWorkers
    function test_callWorkers721() external {
        // Mint an NFT
        vm.prank(test_user);
        controller.callWorkers(address(nft), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        
        // Check that the worker's NFT is mined
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(nft.balanceOf(workers[0]) == 1);
    }

    // This testing the loop functionality of callWorkers
    function test_callWorkers721Loop() external {
        // Mint an NFT (loop twice)
        vm.prank(test_user);
        controller.callWorkers(address(nft), abi.encodeWithSignature("mint()"), 0, 1, 2, 0, false);
        
        // Expect balance to be 2 instead of 1 because of the loop
        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(nft.balanceOf(workers[0]) == 2);
    }

    // This is testing to make sure that execution will end if a transaction reverts
    function test_callWorkersRevert() external {
        // Expect mint to revert after 5 have been minted
        vm.prank(test_user);
        controller.callWorkers(address(nft), abi.encodeWithSignature("mintRevertAfterFive()"), 0, 7, 0, true);
        
        // Ensure the loop terminates all future mints once one reverts
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(nft.balanceOf(workers[0]) == 1);
        assertTrue(nft.balanceOf(workers[1]) == 1);
        assertTrue(nft.balanceOf(workers[2]) == 1);
        assertTrue(nft.balanceOf(workers[3]) == 1);
        assertTrue(nft.balanceOf(workers[4]) == 1);
        assertTrue(nft.balanceOf(workers[5]) == 0);
        assertTrue(nft.balanceOf(workers[6]) == 0);
    }

    // This tests calling a number of workers with sequential transaction data
    function test_callWorkersSequential721() external {
        vm.deal(test_user, 100 ether);

        // Get workers for safeTransferFrom
        address[] memory workers = controller.getWorkers(test_user);

        // Create arrays needed for function arguments
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("paidMint()");
        data[1] = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", workers[0], test_user, 1);

        uint256[] memory values = new uint256[](2);
        values[0] = 0.01 ether;
        values[1] = 0;

        // Mint with the paid mint
        vm.prank(test_user);
        controller.callWorkersSequential{value: 0.01 ether}(address(nft), data, values, 1, true);

        // Make sure the NFT was minted and transferred to the test user
        assertTrue(nft.balanceOf(test_user) == 1);
    }

    // This tests calling a custom worker (by ID) with transaction data
    function test_callWorkersCustom721() external {
        vm.deal(test_user, 100 ether);

        // Creates arrays needed for function arguments
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("paidMint()");
        data[1] = abi.encodeWithSignature("mint(uint256)", 5);

        uint256[] memory values = new uint256[](2);
        values[0] = 0.01 ether;
        values[1] = 0;

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = 0;
        indexes[1] = 1;

        // Run the custom mint
        vm.prank(test_user);
        controller.callWorkersCustom{value: 0.01 ether}(address(nft), data, values, indexes, true);

        // Make sure NFT balances match expected values
        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(nft.balanceOf(workers[0]) == 1);
        assertTrue(nft.balanceOf(workers[1]) == 5);
    }

    // This tests calling a custom worker (by ID) with sequential transaction data
    function test_callWorkersCustomSequential721() external {
        vm.deal(test_user, 100 ether);

        // Create arrays needed for function arguments
        bytes[][] memory data = new bytes[][](2);

        bytes[] memory firstCalls = new bytes[](2);
        firstCalls[0] = abi.encodeWithSignature("mint()");
        firstCalls[1] = abi.encodeWithSignature("mint(uint256)", 5);
        data[0] = firstCalls;

        bytes[] memory secondCalls = new bytes[](2);
        secondCalls[0] = abi.encodeWithSignature("paidMint()");
        secondCalls[1] = abi.encodeWithSignature("mint()");
        data[1] = secondCalls;

        uint256[][] memory values = new uint256[][](2);

        uint256[] memory firstValues = new uint256[](2);
        firstValues[0] = 0;
        firstValues[1] = 0;
        values[0] = firstValues;

        uint256[] memory secondValues = new uint256[](2);
        secondValues[0] = 0.01 ether;
        secondValues[1] = 0;
        values[1] = secondValues;

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = 0;
        indexes[1] = 1;

        // Call the workers function
        vm.prank(test_user);
        controller.callWorkersCustomSequential{value: 0.01 ether}(address(nft), data, values, indexes, true);

        // Make sure NFT balances match expected values
        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(nft.balanceOf(workers[0]) == 6);
        assertTrue(nft.balanceOf(workers[1]) == 2);
    }

    // Only 1155 test - if all the 721 tests worked, and this one passes, all the 1155 tests should work.
    function test_callWorkers1155() external {
        vm.prank(test_user);
        controller.callWorkers(address(nft2), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(nft2.balanceOf(workers[0], 0) == 1);
    }

    // Makes sure callWorkers will not exceed allowances even in multiple calls
    function test_mintAllowances() external {
        vm.startPrank(test_user);

        address[] memory workers = controller.getWorkers(test_user);
        controller.createAllowance(address(nft), 1);

        controller.callWorkers(address(nft), abi.encodeWithSignature("mint()"), 0, 2, 1, false);
        controller.callWorkers(address(nft), abi.encodeWithSignature("mint()"), 0, 2, 1, false);

        vm.stopPrank();

        console.log(nft.balanceOf(workers[0]), "worker zero");
        console.log(nft.balanceOf(workers[1]), "worker one");

        assertTrue(nft.balanceOf(workers[0]) == 1);
        assertTrue(nft.balanceOf(workers[1]) == 0);
    }
}