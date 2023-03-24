// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";

import "./Shared.sol";
import "./samples/Mock721.sol";

// {
//         "inputs": [
//             {
//                 "internalType": "uint32",
//                 "name": "How many loops would you like to perform?",
//                 "type": "uint32"
//             },
//             {
//                 "internalType": "address",
//                 "name": "What is the NFT contract address you want to mint from?",
//                 "type": "address"
//             },
//             {
//                 "internalType": "bytes",
//                 "name": "What is the mint hexdata?",
//                 "type": "bytes"
//             }
//         ],
//         "name": "walletcap_mint",
//         "outputs": [],
//         "stateMutability": "payable",
//         "type": "function"
// }

interface iCry {
    function walletcap_mint(uint32, address, bytes calldata) external payable;
}

contract Benchmarks is Test, Shared {

    Mock721 NFT = new Mock721();
    address cry_user = 0xe749e9E7EAa02203c925A036226AF80e2c79403E;

    function setUp() external {
        _devDeploy();

        vm.prank(zenith_deployer);
        controller.authorizeCaller(test_user);

        vm.prank(test_user);
        // controller.newCreateWorkers(250, address(beacon_proxy));
        controller.createWorkers(250);

        vm.deal(test_user, 100 ether);
    }

    uint256[] _workers = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];

    function testZenithBenchmarkCustom() external {
        vm.prank(test_user);
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0 ether, _workers, false, 1);
    }

    function testZenithBenchmarkCustomNew() external {
        vm.prank(test_user);
        
    }

    // function testThreeGm() external {
    //     // vm.pauseGasMetering();

    //     vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/9WjoVKjkHy_qshqiax-zh_GwDGhiA5w9");

    //     vm.prank(zenith_deployer);
    //     controller.authorizeCaller(test_user);

    //     vm.prank(test_user);
    //     controller.createWorkers(20);

    //     vm.deal(test_user, 100 ether);
    //     vm.roll(16834623);

    //     vm.prank(0x1a876f4719515968f85123600cb6a62831cA2718);
    //     TheRobbersNFT(0xe470157F9d54Fab676c9B6A400EBd8beDAfE5BaB).activatePhases(_phase, false);
        
    //     bytes memory data = abi.encodeWithSignature("mintPhase(uint256,uint64)", 2, 2);

    //     // vm.resumeGasMetering();

    //     controller.callWorkers(0xe470157F9d54Fab676c9B6A400EBd8beDAfE5BaB, data, 0.0154 ether, _workers, false, 0);
        
    //     vm.pauseGasMetering();

    //     // verify mint success
    // }

    function testCryBenchmark() external {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/9WjoVKjkHy_qshqiax-zh_GwDGhiA5w9");

        vm.prank(cry_user);

        iCry(0x8888885921e92D47844A51B68262D4FB122cfA16).walletcap_mint(250, address(NFT), abi.encodeWithSignature("mint()"));
    }    

}