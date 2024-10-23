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

/// @title Crypto Snake
/// @dev A contract that work as a game plaform of snake game
contract CryptoSnake is CollectionMinter, TokenMinter, TokenManager, AddressValidator, UniqueNFT {
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

    function createSnake(CrossAddress memory _owner) external {
        // For simplicity, we have only 2 predefined images, type 1 or type 2.
        // Each player receives a pseudo-random token breed.
        uint32 randomTokenBreed = _getPseudoRandom(BREEDS, 1);

        // Construct token image URL.
        string memory randomImage = string.concat(
            s_generationIpfs[0],
            "monster-",
            Converter.uint2str(randomTokenBreed),
            ".png"
        );

        Attribute[] memory attributes = new Attribute[](4);
        // Each NFT has 3 traits. These traits are mutated when the `_fight` method is invoked.
        attributes[0] = Attribute({trait_type: "Experience", value: "0"});
        attributes[1] = Attribute({trait_type: "Victories", value: "0"});
        attributes[2] = Attribute({trait_type: "Defeats", value: "0"});
        attributes[3] = Attribute({trait_type: "Generation", value: "0"});

        uint256 tokenId = _createToken(COLLECTION_ADDRESS, randomImage, attributes, _owner);
        s_tokenStats[tokenId] = TokenStats({
            breed: randomTokenBreed,
            generation: 0,
            victories: 0,
            defeats: 0,
            experience: 0
        });
    }

    /**
     * @notice Evolves the token to the next generation if it has enough experience.
     *         The token's image changes upon evolution.
     * @param _tokenId The ID of the token to evolve.
     */
    function evolve(uint256 _tokenId) external onlyTokenOwner(_tokenId, COLLECTION_ADDRESS) {
        TokenStats memory tokenStats = s_tokenStats[_tokenId];
        require(tokenStats.experience >= EVOLUTION_EXPERIENCE, "Experience not enough");
        require(tokenStats.generation == 0, "Already evolved");

        s_tokenStats[_tokenId].generation = 1;
        _setTrait(COLLECTION_ADDRESS, _tokenId, "Generation", "1");
        _setImage(_tokenId, false);
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
