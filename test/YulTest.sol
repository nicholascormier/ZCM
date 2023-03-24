// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "../lib/forge-std/src/Test.sol";

// contract YulTest is Test {
    
//     bytes somebytes = abi.encodePacked("");

//     function setUp() external {
//         _testCalldata(vm.addr(69), abi.encodePacked(""));
//     }

//     function _testCalldata(address _person, bytes memory _data) internal {
    
//         uint256 dataSize;

//         assembly {
//             dataSize := calldatasize()
//             let pt := mload(0x40)
//             calldatacopy(pt, 0, dataSize)
//         }

//         console.log(dataSize);

//     }

//     function testE() public {}
// }