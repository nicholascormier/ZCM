// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";

import "./samples/Mock721.sol";
import "./samples/Mock1155.sol";
import "./samples/MockImplementationOne.sol";
import "./samples/MockImplementationTwo.sol";
import "./samples/Mock721Revert.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "./Shared.sol";

contract ControllerTest is Test, Shared {

    Mock721 NFT = new Mock721();
    Mock1155 NFT2 = new Mock1155();

    bytes[] data;
    bytes[][] recursiveData;
    uint256[] values;
    uint256[][] recursiveValues;
    uint256[] recursiveTotalValues;
    uint256[] workerIndexes;

    function setUp() external {
        // shared
        _devDeployBase();
        _authorizeCallers();
    }

    // this is not really testing anything :)
    function testUpgradeProxy() public {
        vm.startPrank(zenith_deployer);
        ProxyAdmin proxyAdmin = ProxyAdmin(admin);

        Controller newImpl = new Controller();

        proxyAdmin.upgrade(TransparentUpgradeableProxy(proxy_address), address(newImpl));
        
        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxy_address, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(newImpl), addr);
        vm.stopPrank();
    }

    function testDeauthorizeUser() external {
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);

        _deauthorizeCallers();

        vm.expectRevert();
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
    }

    function testUnauthorizedCaller() external {
        vm.expectRevert();
        Controller(proxy_address).createWorkers(1);
    }

    function testWorkerCreation() external {
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(workers.length == 2);
        assertTrue(workers[0] == test_user);
    }

    function testWorkerForwarding() external {
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        address response = Worker(payable(workers[1])).getBasicResponse();
        assertTrue(response == workers[1]);
    }

    function testWorkerDirectAccess() external {
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        vm.expectRevert();
        Worker(payable(workers[1])).getBasicResponseProtected();
    }

    uint256[] ww = [1];
    function testWorkerAccessRevoked() external {
        _workerAccess();
    }

    function testWorkerAccessReinstated() external {
        _workerAccess();
        _deauthorizeCallers();

        vm.expectRevert();
        vm.prank(test_user);
        Controller(proxy_address).withdrawFromWorkers(ww, payable(test_user));
    }

    // saves some lines.
    function _workerAccess() internal {
        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(1);
        Controller(proxy_address).withdrawFromWorkers(ww, payable(test_user));
        vm.stopPrank();
    }

    function _mintTestSetup(uint256 workerCount) internal {
        NFT = new Mock721();
        NFT2 = new Mock1155();

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(workerCount);
        vm.stopPrank();
    }

    function testCallWorkers721() external {
        _mintTestSetup(1);

        vm.prank(test_user);
        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

    function testCallWorkers721Loop() external {
        _mintTestSetup(1);

        vm.prank(test_user);
        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, 0, 2, false);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 2);
    }

    function testCallWorkersRevert() external {
        _mintTestSetup(7);

        Mock721Revert NFT = new Mock721Revert();

        vm.prank(test_user);
        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 7, 0, true);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
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

        Controller controller = Controller(proxy_address);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        data = [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", workers[1], test_user, 1)];
        values = [0.01 ether, uint256(0)];

        controller.callWorkersSequential{value: 0.01 ether}(address(NFT), data, values, 0.01 ether, 1);

        vm.stopPrank();

        assertTrue(NFT.balanceOf(test_user) == 1);
    }

    function testCallWorkersCustom721() external {
        _mintTestSetup(2);
        
        vm.startPrank(test_user);
        vm.deal(test_user, 100 ether);

        Controller controller = Controller(proxy_address);

        data = [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("mint(uint256)", 5)];
        values = [uint256(0.01 ether), uint256(0)];
        workerIndexes = [1, 2];

        //controller.callWorkersCustom(address(NFT), data, values, workers, false, 0);
        controller.callWorkersCustom{value: 0.01 ether}(address(NFT), data, values, workerIndexes);

        vm.stopPrank();

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 5);
    }

    function testCallWorkersCustomSequential721() external {
        _mintTestSetup(2);
        
        vm.startPrank(test_user);
        vm.deal(test_user, 100 ether);

        Controller controller = Controller(proxy_address);

        recursiveData = [[abi.encodeWithSignature("mint()"), abi.encodeWithSignature("mint(uint256)", 5)], [abi.encodeWithSignature("paidMint()"), abi.encodeWithSignature("mint()")]];
        recursiveValues = [[uint256(0), uint256(0)], [0.01 ether, uint256(0)]];
        recursiveTotalValues = [uint256(0), 0.01 ether];
        workerIndexes = [1, 2];

        //controller.callWorkersCustoSequential(address(NFT), data, values, workers, false, 0);
        controller.callWorkersCustomSequential{value: 0.01 ether}(address(NFT), recursiveData, recursiveValues, recursiveTotalValues, workerIndexes);

        vm.stopPrank();

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 6);
        assertTrue(NFT.balanceOf(workers[2]) == 2);
    }

    // Only 1155 test - if all the 721 tests worked, and this one passes, all the 1155 tests should work.
    function testCallWorkers1155() external {
        _mintTestSetup(1);
        vm.startPrank(test_user);

        Controller controller = Controller(proxy_address);

        controller.callWorkers(address(NFT2), abi.encodeWithSignature("mint()"), 0, 1, 0, false);
        vm.stopPrank();
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT2.balanceOf(workers[1], 0) == 1);
    }

    function testAllowances() external {
        _mintTestSetup(2);

        vm.startPrank(test_user);
        Controller controller = Controller(proxy_address);

        address[] memory workers = controller.getWorkers(test_user);
        controller.createAllowance(address(NFT), 1);

        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 2, 1, false);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 2, 1, false);

        vm.stopPrank();

        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 0);
    }

    function testWithdrawFromWorker() external {
        _mintTestSetup(1);

        vm.startPrank(test_user);

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        vm.deal(test_user, 1 ether);
        workers[1].call{value: 1 ether}(abi.encodeWithSignature("testPayment()"));

        assertTrue(workers[1].balance == 1 ether);
        
        workerIndexes = [1];

        Controller(proxy_address).withdrawFromWorkers(workerIndexes, payable(test_user));
        // tx.origin is not a known address - figure out vm cheat code
        // address does not have any excess eth for some reason
        assertTrue(test_user.balance == 1 ether);
        vm.stopPrank();
    }

    function testGasCosts() external {
        _mintTestSetup(250);

        Controller controller = Controller(proxy_address);

        vm.prank(test_user);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 100, 0, true);
    }

    function testFallback() external {
        // Controller controller = Controller(proxy_address);
        // uint160 addy = uint160(bytes20(0x0D24e6e50EeC8A1f1DeDa82d94590098A7E664B4));
        // controller.callWorkersFallback()

        _mintTestSetup(1);

        vm.deal(test_user, 100 ether);
        vm.prank(test_user);
        // original call
        // Controller(proxy_address).callWorkersFallback(address(NFT), abi.encodePacked(bytes4(keccak256("mint()")), address(0x0D24e6e50EeC8A1f1DeDa82d94590098A7E664B4)), 0, 1, 0, false);
        bytes memory workerdata = abi.encodePacked(bytes4(keccak256("mint()")), bytes20(address(NFT)));
        console.log(address(NFT));
        Controller(proxy_address).callWorkersFallback(workerdata, 1, 0, false);

        vm.stopPrank();
    } 

}