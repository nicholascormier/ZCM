// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    constructor() ERC721("Niftee", "NFT") {}

    function mint(uint256 _quantity) external {
        _mint(msg.sender, _quantity);
    }

    function safeMint(uint256 _quantity) external {
        _safeMint(msg.sender, _quantity);
    }
}