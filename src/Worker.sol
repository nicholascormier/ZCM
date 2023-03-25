//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IProxyBeacon {
    function getImplementation() external view returns(address);
    function getControllerAddress() external view returns(address);
}

// Deployed by us, serves as template for proxies
contract Worker {

    modifier onlyOwner{
        require(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac == msg.sender, "Not owner");
        _;
    }
    
    function getOwner() external returns(address) {
        return 0xffD4505B3452Dc22f8473616d50503bA9E1710Ac;
    }

    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable onlyOwner returns (bool) {
        (bool success,) = _target.call{value: _value}(_data);
        return success;
    }

    // This shouldn't exist without Ownable (expensive gas-wise)
    function withdraw() external onlyOwner {
        payable(tx.origin).transfer(address(this).balance);
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

}
