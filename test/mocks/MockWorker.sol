// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../src/Worker.sol";

contract MockWorker {
    function impl() external pure returns (uint256) {
        return 2;
    }
}