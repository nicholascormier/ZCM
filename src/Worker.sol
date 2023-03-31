//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/forge-std/src/console.sol";

interface IProxyBeacon {
    function getImplementation() external view returns(address);
    function getControllerAddress() external view returns(address);
}

// Deployed by us, serves as template for proxies
contract Worker {
    address private immutable owner;

    constructor(address _owner){
        owner = _owner;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Not owner");
        //require(0x9cC6334F1A7Bc20c9Dde91Db536E194865Af0067 == msg.sender, "Not owner");
        _;
    }
    
    function getOwner() external view returns(address) {
        //return 0x9cC6334F1A7Bc20c9Dde91Db536E194865Af0067;
        return owner;
    }

    function withdraw(address payable withdrawTo) external onlyOwner {
        withdrawTo.transfer(address(this).balance);
    }

    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable onlyOwner returns (bool) {
        (bool success,) = _target.call{value: _value}(_data);
        return success;
    }

    function forwardCalls(address _target, bytes[] calldata _data, uint256[] calldata _values) external payable onlyOwner returns(uint256 successes) {
        for(uint256 i = 0; i < _data.length; i++){
            (bool success,) = _target.call{value: _values[i]}(_data[i]);
            if(success) successes++;
        }
        return successes;
    }

    // ERC721 safeMint compliance
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns(bytes4) {
        return 0x150b7a02;
    }

    // ERC1155 safeMint compliance
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure returns(bytes4) {
        return 0xf23a6e61;
    }

    // Also exists for testing but doesn't matter
    function getBasicResponse() external view returns(address) {
        return address(this);
    }

    function getBasicResponseProtected() external view onlyOwner returns(address) {
        return address(this);
    }

    function testPayment() external payable {}

}
