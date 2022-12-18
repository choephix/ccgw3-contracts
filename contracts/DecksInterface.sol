// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ICounter {
    function count() external view returns (uint);
    function increment() external;
}

contract DecksInterface {
    //// The business logic below is temporarily written in this one contract
    //// for simplicity and more comfortable deployment and testing,
    //// but will eventually be split into several contracts
    //// with DecksInterface wrapping over them and serving as their de facto 
    //// connection with the rest of the world.

    //// Contract 1 — DeckIndex

    struct DeckProperties {
        address owner;
        uint16 hrPrice;
    }

    uint40 public decksCount;
    mapping(uint40 => DeckProperties) public decks;
    mapping(address => uint40[]) public owners;

    function create() external returns (uint40, DeckProperties memory) {
        uint40 deckID = decksCount++;
        DeckProperties memory deck = DeckProperties(msg.sender, 1, address(0), 0);

        decks[deckID] = deck;
        owners[msg.sender].push(deckID);

        return (deckID, deck);
    }

    //// Contract 2 — RentADeck

    struct DeckRentalStatus {
        address renter;
        uint32 expiry;
    }

    uint constant MICROETH = .000001 * 1000000000000000000;
    uint32 constant RENT_DURATION = 1 hours;

    mapping(uint40 => DeckRentalStatus) public rentals;

    function rent(uint40 deckID) external payable returns(bool) {
        // console.log("msg.value", msg.value, "/", decks[deckID].hrPrice);

        uint256 price = MICROETH * decks[deckID].hrPrice;
        require(msg.value >= price, "Not enough ETH sent");

        bool success = rentTo(deckID, msg.sender);
        require(success, "Renting failed");

        Address.sendValue(payable(decks[deckID].owner), msg.value);
        
        return true;
    }

    function rentTo(uint40 deckID, address renter) public payable returns(bool) {
        // console.log("msg.value", msg.value, "/", decks[deckID].hrPrice);

        require(!isRentedOut(deckID), "Deck already rented out");

        DeckProperties memory deck = decks[deckID];

        deck.borrower = msg.sender;
        deck.expiry = uint32(block.timestamp + RENT_DURATION);
        
        return true;
    }

    function isRentedOut(uint40 deckID) public view returns (bool) {
        DeckProperties memory deck = decks[deckID];
        if (deck.borrower == address(0)) return false;
        if (deck.expiry < block.timestamp) return false;
        return true;
    }

    //// Contract 3 — DecksInterface

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
}
