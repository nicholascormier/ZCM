// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;
contract EthSender {
    function empty(address _sendTo) external {
        payable(_sendTo).call{value: address(this).balance}("");
    }
}