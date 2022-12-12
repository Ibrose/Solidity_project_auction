// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted external {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted public{
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
