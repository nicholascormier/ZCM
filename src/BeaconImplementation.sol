// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Beacon.sol";

contract BeaconImplementation {

    Beacon private _beacon;

    function _delegate(address implementation) internal virtual {
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable{
        // REPLACE ADDRESS WITH DEPLOYED BEACON ADDRESS
        _delegate(_beacon.getImplementation());
    }

    // THIS IS FOR TESTING ONLY - DO NOT DEPLOY THIS FUNCTION
    function setBeacon(address beacon) external {
        _beacon = Beacon(beacon);
    }
}
