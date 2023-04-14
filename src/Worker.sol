//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Deployed by us, serves as template for proxies
contract Worker{
    address private immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Not owner");
        //require(0x9cC6334F1A7Bc20c9Dde91Db536E194865Af0067 == msg.sender, "Not owner");
        _;
    }

    // ERC721 safeMint compliance
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns(bytes4) {
        return 0x150b7a02;
    }

    // ERC1155 safeMint compliance
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure returns(bytes4) {
        return 0xf23a6e61;
    }

    fallback() external payable onlyOwner {

        bytes20 destination;
        bytes32 cd;

        assembly {
            let cdsize := calldatasize()
            let proxydatasize := sub(cdsize, 20)

            // copy last 20 bytes of calldata to memory address 0x80 (first free memory address)
            calldatacopy(0x80, sub(cdsize, 20), 20)

            // shifts right 12 bytes to convert from bytes20 to address 
            let proxyaddress := shr(96, mload(0x80))
            destination := proxyaddress 

            // update free mem pointer to point to 100th byte of memory
            mstore(0x40, add(0x80, 20))

            let proxydata := mload(0x40)
            calldatacopy(proxydata, 0, proxydatasize)
            cd := mload(proxydata)

            let success := call(gas(), proxyaddress, callvalue(), proxydata, proxydatasize, 0, 0)
        }
    }

    // If called with no calldata
    receive() external payable {
    }

}
