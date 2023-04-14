// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Mock721 is ERC721 {
    constructor() ERC721("Niftee", "NFT") {}

    uint256 id;

    function mint() external {
        id++;
        _mint(msg.sender, id);
    }

    function paidMint() external payable {
        require(msg.value == 0.01 ether, "Must pay 0.01 ETH");
        id++;
        _mint(msg.sender, id);
    }

    function mint(uint256 quantity) external {
        require(quantity > 0, "Quantity must be greater than 0");
        for(uint256 i = 0; i < quantity; i++){
            id++;
            _mint(msg.sender, id);
        }
    }

    function mintRevert() external {
        revert();
    }

    function safeMint() external {
        id++;
        _safeMint(msg.sender, id);
    }
    
}