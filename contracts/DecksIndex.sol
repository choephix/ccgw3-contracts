// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";

contract DecksIndex {
    uint constant MICROETH = .000001 * 1000000000000000000;

    uint40 public decksCount;

    mapping(uint40 => DeckProperties) public decks;
    mapping(address => uint40[]) public owners;

    function create() external returns (uint40, DeckProperties memory) {
        uint40 deckID = decksCount++;
        owners[msg.sender].push(deckID);

        DeckProperties memory deck = DeckProperties(msg.sender, 1, address(0), 0);
        decks[deckID] = deck;

        return (deckID, deck);
    }

    function borrow(uint40 deckID) external payable returns(bool) {
        // console.log("msg.value", msg.value, "/", decks[deckID].hrPrice);

        require(!isAlreadyBorrowed(deckID), "Deck is already borrowed");

        DeckProperties memory deck = decks[deckID];
        uint256 price = MICROETH * deck.hrPrice;
        require(msg.value >= price, "Not enough ETH sent");

        deck.borrower = msg.sender;
        deck.expiry = uint32(block.timestamp + 1 hours);
        
        Address.sendValue(payable(deck.owner), msg.value);
        
        return true;
    }

    function isAlreadyBorrowed(uint40 deckID) public view returns (bool) {
        DeckProperties memory deck = decks[deckID];
        if (deck.borrower == address(0)) return false;
        if (deck.expiry < block.timestamp) return false;
        return true;
    }

    function canUserUse(uint40 deckID, address user) public view  returns (bool) {
        DeckProperties memory deck = decks[deckID];
        if (deck.owner == user) return true;
        if (deck.borrower != user) return false;
        if (deck.expiry < block.timestamp) return false;
        return true;
    }

    function canIUse(uint40 deckID) external view returns (bool) {
        return canUserUse(deckID, msg.sender);
    }

    struct DeckProperties {
        address owner;
        uint16 hrPrice;
        address borrower;
        uint32 expiry;
    }
}
