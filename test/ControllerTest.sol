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

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";

import "./Shared.sol";

contract ControllerTest is Test, Shared {

    // Variable storing the address of the controller logic contract
    Controller controller_logic = new Controller();

    // Proxy management variables
    ProxyController controller_proxy;
    ProxyAdmin controller_admin;

    // Variable storing test_
    address test_user = vm.addr(3493847394);

    ProxyTester proxy = new ProxyTester();
    address proxy_address;
    address admin;

    Mock721 NFT = new Mock721();
    Mock1155 NFT2 = new Mock1155();

    bytes[] data;
    uint256[] values;
    uint256[] workerIndexes;

    function setUp() external {
        // shared
        _devDeployBase();
        _deployProxySetup();
    }

    function _deployProxySetup() internal {
        vm.startPrank(zenith_deployer);
        admin = vm.addr(69);

        proxy.setType("uups");
        proxy_address = proxy.deploy(address(controller_logic), admin);

        bytes32 implSlot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );
        bytes32 proxySlot = vm.load(proxy_address, implSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }

        assertEq(address(controller_logic), addr);

        Controller(proxy_address).initialize();
        Controller(proxy_address).setWorkerTemplate(address(worker_implementation));

        vm.stopPrank();
    }

    // this is not really testing anything :)
    function testUpgradeProxy() public {
        vm.prank(zenith_deployer);
        Controller newImpl = new Controller();
        proxy.upgrade(address(newImpl), admin, address(0));
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
    }

    function testAuthorizeUser() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
    }

    function testDeauthorizeUser() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);

        vm.prank(zenith_deployer);
        Controller(proxy_address).deauthorizeCaller(test_user);

        vm.expectRevert();
        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
    }

    function testUnauthorizedCaller() external {
        vm.expectRevert();
        Controller(proxy_address).createWorkers(1);
    }

    function testAuthorizedCaller() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
    }

    function testWorkerCreation() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(workers.length == 2);
        assertTrue(workers[0] == test_user);
    }

    function testWorkerForwarding() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        address response = Worker(workers[1]).getBasicResponse();
        assertTrue(response == workers[1]);
    }

    function testWorkerDirectAccess() external {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).createWorkers(1);
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        vm.expectRevert();
        Worker(workers[1]).getBasicResponseProtected();
    }

    uint256[] ww = [1];
    function testWorkerAccessRevoked() external {
        _workerAccess();
    }

    function testWorkerAccessReinstated() external {
        _workerAccess();
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.prank(test_user);
        Controller(proxy_address).withdrawFromWorkers(ww);
    }

    // saves some lines.
    function _workerAccess() internal {
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(1);
        Controller(proxy_address).withdrawFromWorkers(ww);
        vm.stopPrank();

        vm.prank(zenith_deployer);
        Controller(proxy_address).deauthorizeCaller(test_user);

        vm.expectRevert();

        vm.prank(test_user);
        Controller(proxy_address).withdrawFromWorkers(ww);
    }

    function _mintTestSetup() internal {
        _mintTestSetup(1);
    }

    function _mintTestSetup(uint256 workerCount) internal {
        NFT = new Mock721();
        NFT2 = new Mock1155();
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(workerCount);
        vm.stopPrank();
    }

    function testCallWorkers721() external {
        _mintTestSetup();

        vm.prank(test_user);
        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 1, false, 0);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

    function testCallWorkersSequential721() external {
        _mintTestSetup();
        
        vm.startPrank(test_user);

        Controller controller = Controller(proxy_address);

        data = [abi.encodeWithSignature("mint()"), abi.encodeWithSignature("mint()")];
        values = [uint256(0), uint256(0)];

        controller.callWorkersSequential(address(NFT), data, values, 1, false, 0);

        vm.stopPrank();

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 2);
    }

    function testCallWorkersCustom721() external {
        _mintTestSetup(2);
        
        vm.startPrank(test_user);

        Controller controller = Controller(proxy_address);

        data = [abi.encodeWithSignature("mint()"), abi.encodeWithSignature("mint(uint256)", 5)];
        values = [uint256(0), uint256(0)];
        workerIndexes = [1, 2];

        //controller.callWorkersCustom(address(NFT), data, values, workers, false, 0);
        controller.callWorkersCustom(address(NFT), data, values, workerIndexes);

        vm.stopPrank();

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        assertTrue(NFT.balanceOf(workers[1]) == 1);
        assertTrue(NFT.balanceOf(workers[2]) == 5);
    }

    function testCallWorkers1155() external {
        _mintTestSetup();
        
        vm.startPrank(test_user);

        Controller controller = Controller(proxy_address);

        controller.callWorkers(address(NFT2), abi.encodeWithSignature("mint()"), 0, 1, false, 0);
        vm.stopPrank();
        
        address[] memory workers = controller.getWorkers(test_user);
        
        assertTrue(NFT2.balanceOf(workers[1], 0) == 1);
    }

    /*function testGasCosts() external {
        vm.startPrank(test_user);
        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, 250, false, 0);
        vm.stopPrank();

        //console.log(address(controller_logic), "proxy addy");

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        //workers[1].call(abi.encodeWithSignature("getBasicResponse()"));

        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }*/

}