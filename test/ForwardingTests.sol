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


    function testCallWorkers721() external {
        // Mint an NFT
        vm.prank(test_user);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        vm.stopPrank();
        
        // Check that the worker's NFT is mined
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

    function testCallWorkers721Loop() external {
        // Set up with a worker
        _mintTestSetup(1);

        // Mint an NFT (loop twice)
        vm.prank(test_user);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, 2, 0, false);
        vm.stopPrank();
        
        // Expect balance to be 2 instead of 1 because of the loop
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 2);
    }

    function testCallWorkersRevert() external {
        _mintTestSetup(7);

        Mock721Revert NFT = new Mock721Revert();
        
        // Expect mint to revert after 5 have been minted
        vm.prank(test_user);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 7, 0, true);
        vm.stopPrank();
        
        // Ensure the loop terminates all future mints once one reverts
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 1);
        assertTrue(NFT.balanceOf(workers[3]) == 1);
        assertTrue(NFT.balanceOf(workers[4]) == 1);
        assertTrue(NFT.balanceOf(workers[5]) == 1);
        assertTrue(NFT.balanceOf(workers[6]) == 0);
        assertTrue(NFT.balanceOf(workers[7]) == 0);
    }

    function testCallWorkersSequential721() external {
        _mintTestSetup(1);
        vm.startPrank(test_user);
        vm.deal(test_user, 100 ether);

        // Create the function arguments
        Controller controller = controller;
        address[] memory workers = controller.getWorkers(test_user);

        data = [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", workers[1], test_user, 1)];
        values = [0.01 ether, uint256(0)];

        // Mint with the paid mint
        controller.callWorkersSequential{value: 0.01 ether}(address(NFT), data, values, 1, true);

        vm.stopPrank();

        // Make sure the NFT was minted and transferred to the test user
        assertTrue(NFT.balanceOf(test_user) == 1);
    }

    function testCallWorkersCustom721() external {
        _mintTestSetup(2);
        vm.startPrank(test_user);
        vm.deal(test_user, 100 ether);

        Controller controller = controller;

        data = [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("mint(uint256)", 5)];
        values = [uint256(0.01 ether), uint256(0)];
        workerIndexes = [1, 2];

        controller.callWorkersCustom{value: 0.01 ether}(address(NFT), data, values, workerIndexes, true);

        vm.stopPrank();

        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 5);
    }

    function testCallWorkersCustomSequential721() external {
        _mintTestSetup(2);
        vm.startPrank(test_user);
        vm.deal(test_user, 100 ether);

        Controller controller = controller;

        recursiveData = [[abi.encodeWithSignature("mint()"), abi.encodeWithSignature("mint(uint256)", 5)], [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("mint()")]];
        recursiveValues = [[uint256(0), uint256(0)], [0.01 ether, uint256(0)]];
        recursiveTotalValues = [uint256(0), 0.01 ether];
        workerIndexes = [1, 2];

        //controller.callWorkersCustoSequential(address(NFT), data, values, workers, false, 0);
        controller.callWorkersCustomSequential{value: 0.01 ether}(address(NFT), recursiveData, recursiveValues, workerIndexes, true);

        vm.stopPrank();

        address[] memory workers = controller.getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 6);
        assertTrue(NFT.balanceOf(workers[2]) == 2);
    }

    // Only 1155 test - if all the 721 tests worked, and this one passes, all the 1155 tests should work.
    function testCallWorkers1155() external {
        _mintTestSetup(1);
        vm.startPrank(test_user);

        Controller controller = controller;

        controller.callWorkers(address(NFT2), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        vm.stopPrank();
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT2.balanceOf(workers[1], 0) == 1);
    }

    function testAllowances() external {
        _mintTestSetup(2);
        vm.startPrank(test_user);
        Controller controller = controller;

        address[] memory workers = controller.getWorkers(test_user);
        controller.createAllowance(address(NFT), 1);

        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 2, 1, false);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 2, 1, false);

        vm.stopPrank();

        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 0);
    }
}