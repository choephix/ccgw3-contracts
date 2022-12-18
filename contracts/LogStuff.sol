// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract LogStuff {
    function log() public payable {
        console.log(msg.sender, msg.value);
    }
}
