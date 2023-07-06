// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "../src/Controller.sol";

import "../src/Worker.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/foundry-upgrades/src/ProxyTester.sol";
import "../lib/solady/src/utils/ERC1967Factory.sol";

interface NFTMint {
    function publicMint(uint256 amount) external;
}

contract Benchmarks is Test {

    address multi;
    Controller controllerLogic;

    address test_user = vm.addr(3424423);
    address admin = vm.addr(1042423423);

    address[] authorizedCallers = [test_user];

    Controller controller;

    address nft;

    function setUp() external {
        vm.startPrank(test_user);
        ERC1967Factory factory = new ERC1967Factory();
        controllerLogic = new Controller();
        controller = Controller(payable(factory.deploy(address(controllerLogic), admin)));
        // controller = new Controller();
        controller.initialize();

        Worker worker = new Worker(address(controller));
        controller.setWorkerTemplate(address(worker));

        controller.authorizeCallers(authorizedCallers);

        //controller.createWorkers(300);
        vm.stopPrank();
        
        nft = 0x3399B6e00b350b226AA18D3D552D750c326Ee475;
        vm.startPrank(0xd22751a2b759d47993A6bDC466ECEfa0BdDCaF0a);
        nft.call(abi.encodeWithSignature("setState(uint8)", 2));
        nft.call(abi.encodeWithSignature("setNoCost(uint256)", 1));
        nft.call(abi.encodeWithSignature("setNoCostLimit(uint256)", 800));
        nft.call(abi.encodeWithSignature("setSalePrice(uint256)", 3000000000000000));
        nft.call(abi.encodeWithSignature("setMaxTx(uint256)", 20));
        NFTMint(nft).publicMint(1);
        vm.stopPrank();
        // address nft = 0x28E775AcdAE23d86564525fdefa7f843Dc991cF1;
        // vm.startPrank(0x307890cE363FdB31f83aC7d9BB06D1c64bCC793e);
        // nft.call(abi.encodeWithSignature("setSaleActive(bool)", true));
        // nft.call(abi.encodeWithSignature("mint(uint8)", 1));
        // vm.stopPrank();
    }

    function testGasCosts() external {
        vm.prank(test_user);
        controller.callWorkers(nft, abi.encodeWithSignature("publicMint(uint256)", 1), 0, 25, 0, true);
        //NFTMint(0x3399B6e00b350b226AA18D3D552D750c326Ee475).publicMint(1);
    }

    function testCreations() external {
        vm.prank(test_user);
        controller.createWorkers(25);
    }

}