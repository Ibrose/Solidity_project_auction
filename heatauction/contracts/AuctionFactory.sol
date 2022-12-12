// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Pok8Coin } from './testblockcoin.sol';

contract AuctionFactory {
    address [] public auctions;
    address ddd;

    event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

    function AuctionFactoryMain() public {
    }

    function createAuction(address _owner, uint _bidIncrement, uint _startBlock, uint _endBlock, string memory _ipfsHash, uint maxauctheat) public {
        
        Pok8Coin newAuction = new Pok8Coin();
        newAuction.mainAuction(_owner, _bidIncrement, _startBlock, _endBlock, _ipfsHash, maxauctheat);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length, auctions);
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}
