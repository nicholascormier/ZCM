// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EthSender {
    function empty(address _sendTo) external {
        payable(_sendTo).call{value: address(this).balance}("");
    }

    function callEmpty(address _sendTo) external {
        this.empty(_sendTo);
    }
}