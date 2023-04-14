// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Test.sol";

import "../../src/Controller.sol";
import "../../src/Worker.sol";
import "../../lib/solady/src/utils/ERC1967Factory.sol";

contract AuthorizationSetup is Test{
    // Have a storage array for a test authorized user
    address authorized_user = vm.addr(1);
    address[] authorized_user_array = [vm.addr(1)];

}