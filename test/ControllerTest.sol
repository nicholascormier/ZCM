// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Beacon.sol";
import "../src/BeaconImplementation.sol";
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

    Controller controller_logic = new Controller();

    ProxyController controller_proxy;
    ProxyAdmin controller_admin;

    address test_user = vm.addr(3493847394);

    ProxyTester proxy = new ProxyTester();
    address proxy_address;
    address admin;

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
        Controller(proxy_address).setWorkerTemplate(address(beacon_implementation));
        beacon.updateController(proxy_address);

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

    function test721Mint() external {
        Mock721 NFT = new Mock721();
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, ids, false, 0);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

    function test1155Mint() external {
        Mock1155 NFT = new Mock1155();
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0, ids, false, 0);
        vm.stopPrank();
        
        address[] memory workers = Controller(proxy_address).getWorkers(test_user);
        
        assertTrue(NFT.balanceOf(workers[1], 0) == 1);
    }

    function testGasCosts() external {
        Mock721 NFT = new Mock721();
        vm.prank(zenith_deployer);
        Controller(proxy_address).authorizeCaller(test_user);

        vm.startPrank(test_user);
        Controller(proxy_address).createWorkers(100);

        Controller(proxy_address).testCloneCosts();

        uint256[] memory workerArray = new uint256[](100);
        for (uint256 i = 1; i < 101; i++) {
            workerArray[i-1] = i;
        }

        Controller(proxy_address).callWorkers(address(NFT), abi.encodeWithSignature("safeMint()"), 0, workerArray, false, 0);
        vm.stopPrank();

        address[] memory workers = Controller(proxy_address).getWorkers(test_user);

        assertTrue(NFT.balanceOf(workers[1]) == 1);
    }

}