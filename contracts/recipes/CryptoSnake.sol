// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UniqueNFT} from "@unique-nft/solidity-interfaces/contracts/UniqueNFT.sol";
import {Converter} from "../libraries/Converter.sol";
import {CollectionMinter} from "../CollectionMinter.sol";
import {TokenMinter, Attribute, CrossAddress} from "../TokenMinter.sol";
import {TokenManager} from "../TokenManager.sol";
import {AddressValidator} from "../AddressValidator.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct TokenStats {
    string nickname;
    uint256 totalScore;
    uint256 gamesPlayed;
}

/// @title Crypto Snake
/// @dev A contract that work as a game plaform of snake game
contract CryptoSnake is CollectionMinter, TokenMinter, TokenManager, AddressValidator, ERC721, ERC721URIStorage {
    mapping(uint256 tokenId => TokenStats) private s_tokenStats;

    /// @dev Address of the NFT collection. Created at the deploy time.
    address private immutable COLLECTION_ADDRESS;
    /// @dev This contract mints a snake game collection in the constructor.
    ///      CollectionMinter(true, true, false) means token attributes will be:
    ///      mutable (true) by the collection admin (true), but not by the token owner (false).
    constructor() CollectionMinter(true, true, false) {
        // The contract mints a collection and becomes the collection owner,
        // so it has permissions to mutate its tokens' attributes.
        COLLECTION_ADDRESS = _mintCollection(
            "Crypto Snake",
            "Crypto Snake",
            "CrSk",
            "https://crypto-snake.vercel.app/logo.png"
        );
    }

    receive() external payable {}

    function createSnake(CrossAddress memory _owner, string memory _nickname) external payable {
        // Construct token image URL.
        string memory img = "https://crypto-snake.vercel.app/logo.png";

        Attribute[] memory attributes = new Attribute[](4);
        // Each NFT has 3 traits. These traits are mutated when the `_fight` method is invoked.
        attributes[0] = Attribute({trait_type: "Nickname", value: _nickname});
        attributes[1] = Attribute({trait_type: "Total Score", value: "0"});
        attributes[2] = Attribute({trait_type: "Games Played", value: "0"});

        uint256 tokenId = _createToken(COLLECTION_ADDRESS, img, attributes, _owner);
        s_tokenStats[tokenId] = TokenStats({
            nickname: _nickname,
            totalScore: 0,
            gamesPlayed: 0
        });
    }

    /**
     * @dev Function to mint a new collection.
     * @param _name Name of the collection.
     * @param _description Description of the collection.
     * @param _symbol Symbol prefix for the tokens in the collection.
     * @param _collectionCover URL of the cover image for the collection.
     * @return Address of the created collection.
     */
    function _mintCollection(
        string memory _name,
        string memory _description,
        string memory _symbol,
        string memory _collectionCover
    ) private returns (address) {
        address collectionAddress = _createCollection(_name, _description, _symbol, _collectionCover);

        // You may also set sponsorship for the collection to create a fee-less experience:
        // import {UniqueNFT} from "@unique-nft/solidity-interfaces/contracts/UniqueNFT.sol";
        // UniqueNFT collection = UniqueNFT(collectionAddress);
        // collection.setCollectionSponsorCross(CrossAddress({eth: address(this), sub: 0}));
        // collection.confirmCollectionSponsorship();

        return collectionAddress;
    }
}
