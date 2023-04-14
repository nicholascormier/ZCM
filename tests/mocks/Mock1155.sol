
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract Mock1155 is ERC1155 {
    constructor() ERC1155("") {}

    uint256 id;

    function mint() external {
        _mint(msg.sender, 0, 1, "");
        id++;
    }

}