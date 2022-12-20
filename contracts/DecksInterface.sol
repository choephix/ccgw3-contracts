// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";

error NotEnoughEtherProvided(uint256 requiredAmount, uint256 providedAmount);
error DeckAlreadyRentedOut(uint32 expiry);
error CannotRentOwnDeck();

contract DecksInterface {

    //// The business logic below is temporarily written in this one contract
    //// for simplicity and more comfortable deployment and testing,
    //// but will eventually be split into several contracts
    //// with DecksInterface wrapping over them and serving as their de facto
    //// connection with the rest of the world.

    //// Contract 1 — DeckIndex

    struct DeckProperties {
        address owner;
        uint8 priceTier;
    }

    uint40 public decksCount;
    mapping(uint40 => DeckProperties) public decks;
    mapping(address => uint40[]) public owners;

    function create(uint8 priceTier) external returns (uint40) {
        uint40 deckID = decksCount++;

        owners[msg.sender].push(deckID);
        decks[deckID] = DeckProperties(msg.sender, priceTier);
        rentals[deckID] = DeckRentalStatus(address(0), 0);

        return deckID;
    }

    //// Contract 2 — RentADeck

    struct DeckRentalStatus {
        address renter;
        uint32 expiry;
    }

    uint32 constant RENT_DURATION = 1 minutes;

    mapping(uint40 => DeckRentalStatus) public rentals;

    function rent(uint40 deckID) external payable {
        uint256 price = 2**decks[deckID].priceTier;

        if (price > 0 && msg.value < price) {
            revert NotEnoughEtherProvided(price, msg.value);
        }

        rentTo(deckID, msg.sender);

        if (price > 0) {
            Address.sendValue(payable(decks[deckID].owner), msg.value);
        }
    }

    function rentTo(uint40 deckID, address renter) private {
        if (decks[deckID].owner == renter) {
            revert CannotRentOwnDeck();
        }

        if (isRentedOut(deckID)) {
            revert DeckAlreadyRentedOut(rentals[deckID].expiry);
        }

        rentals[deckID].renter = renter;
        rentals[deckID].expiry = uint32(block.timestamp + RENT_DURATION);
    }

    function isRentedOut(uint40 deckID) public view returns (bool) {
        if (rentals[deckID].renter == address(0)) return false;
        if (rentals[deckID].expiry < block.timestamp) return false;

        return true;
    }

    //// Contract 3 — DecksInterface

    function canUseDeck(uint40 deckID, address user)
        public
        view
        returns (bool)
    {
        if (decks[deckID].owner == user) return true;

        if (rentals[deckID].renter != user) return false;
        if (rentals[deckID].expiry < block.timestamp) return false;

        return true;
    }
}
