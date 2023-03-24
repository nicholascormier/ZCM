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

    function testZenithBenchmarkCustom() external {
        vm.prank(test_user);
        uint256[] memory _workers = new uint256[](250);
        for(uint256 i = 1; i <= 250; i++) {
            _workers[i-1] = i;
        }
        controller.callWorkers(address(NFT), abi.encodeWithSignature("mint()"), 0 ether, _workers, false, 1);
    }

    function testCryBenchmark() external {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/9WjoVKjkHy_qshqiax-zh_GwDGhiA5w9");

        vm.prank(cry_user);

        iCry(0x8888885921e92D47844A51B68262D4FB122cfA16).walletcap_mint(250, address(NFT), abi.encodeWithSignature("mint()"));
    }    

}