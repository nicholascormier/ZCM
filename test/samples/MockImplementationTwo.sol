// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../src/Worker.sol";

contract ImplTwo {
    function impl() external pure returns (uint256) {
        return 2;
    }

    function workerTest(address _worker) external {
        Worker(payable(_worker)).withdraw(payable(msg.sender));
    }
}