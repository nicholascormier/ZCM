// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/ERC721A/contracts/ERC721A.sol";
import "../../lib/forge-std/src/console.sol";

contract Mock721Revert is ERC721A {
    constructor() ERC721A("Niftee", "NFT") {}

    function mint() external {
        require(_totalMinted() < 5, "Too many minted");
        _mint(msg.sender, 1);
    }
    
}