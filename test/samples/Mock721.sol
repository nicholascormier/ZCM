// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Mock721 is ERC721 {
    constructor() ERC721("Niftee", "NFT") {}

    uint256 id;

    function mint() external {
        id++;
        _mint(msg.sender, id);
    }

    function safeMint() external {
        id++;
        _safeMint(msg.sender, id);
    }
    
}