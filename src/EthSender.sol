// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../lib/forge-std/src/console.sol";

contract EthSender {
    function empty(address _sendTo) external {
        console.log(address(this).balance, "current bal");
        console.log(address(this), "current addy");
        payable(_sendTo).call{value: address(this).balance}("");
    }
}