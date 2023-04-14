// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "../lib/forge-std/src/console.sol";

contract EthSender {

    address immutable addy;
    constructor(){
        addy = address(this);
    }

    function empty(address _sendTo) external {
        console.log(address(this), "current address");
        console.log(address(this).balance, "current balance");
        payable(_sendTo).call{value: address(this).balance}("");
    }

    function callEmpty(address _sendTo) external {
        //this.empty(_sendTo);
        //payable(_sendTo).call{value: msg.sender.balance}("");
        addy.call(abi.encodeWithSignature("empty(address)", _sendTo));
    }
}