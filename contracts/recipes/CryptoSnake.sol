// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {UniqueNFT} from "@unique-nft/solidity-interfaces/contracts/UniqueNFT.sol";
import {Converter} from "../libraries/Converter.sol";
import {CollectionMinter} from "../CollectionMinter.sol";
import {TokenMinter, Attribute, CrossAddress} from "../TokenMinter.sol";
import {TokenManager} from "../TokenManager.sol";
import {AddressValidator} from "../AddressValidator.sol";
import {Base64} from "../libraries/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct TokenStats {
    string nickname;
    uint256 totalScore;
    uint256 gamesPlayed;
    CrossAddress owner;
}

/// @title Crypto Snake
/// @dev A contract that work as a game plaform of snake game
contract CryptoSnake is CollectionMinter, TokenMinter, TokenManager, AddressValidator, ERC721, ERC721URIStorage {
    mapping(uint256 tokenId => TokenStats) private s_tokenStats;
    uint256 private s_tokenCreationFee;

    /// @dev Address of the NFT collection. Created at the deploy time.
    address private immutable COLLECTION_ADDRESS;

    /// @dev This contract mints a snake game collection in the constructor.
    ///      CollectionMinter(true, true, false) means token attributes will be:
    ///      mutable (true) by the collection admin (true), but not by the token owner (false).
    constructor(uint256 _tokenCreationFee) CollectionMinter(true, true, false) {
        s_tokenCreationFee = _tokenCreationFee;

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

    error Snake__IncorrectFee();

    function createSnake(CrossAddress memory _owner, string memory _nickname) external payable {
        if (msg.value != s_tokenCreationFee) revert Snake__IncorrectFee();

        // Construct token image URL.
        string memory img = "https://crypto-snake.vercel.app/logo.png";

        Attribute[] memory attributes = new Attribute[](4);
        // Each NFT has 3 traits. These traits are mutated when the `_fight` method is invoked.
        attributes[0] = Attribute({trait_type: "Nickname", value: _nickname});
        attributes[1] = Attribute({trait_type: "Total Score", value: "0"});
        attributes[2] = Attribute({trait_type: "Games Played", value: "0"});

        uint256 tokenId = _createToken(COLLECTION_ADDRESS, img, attributes, _owner);
        s_tokenStats[tokenId] = TokenStats({owner: _owner, nickname: _nickname, totalScore: 0, gamesPlayed: 0});
    }

    error Snake__NotOwner();

    function playSnake(uint256 _tokenId, uint256 _score) external payable {
        if (s_tokenStats[_tokenId].owner.eth != msg.sender) revert Snake__NotOwner();

        s_tokenStats[_tokenId].totalScore += _score;
        s_tokenStats[_tokenId].gamesPlayed += 1;

        _setTrait(COLLECTION_ADDRESS, _tokenId, "Total Score", Converter.uint2str(s_tokenStats[_tokenId].totalScore));
        _setTrait(COLLECTION_ADDRESS, _tokenId, "Games Played", Converter.uint2str(s_tokenStats[_tokenId].gamesPlayed));
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

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory tokenName = s_tokenStats[tokenId].nickname;
        string memory tokenDescription = "Crypto Snake";
        uint256 totalScore = s_tokenStats[tokenId].totalScore;
        uint256 gamesPlayed = s_tokenStats[tokenId].gamesPlayed;
        string memory svgString = _tokenSVG(tokenName, tokenId, totalScore, gamesPlayed);
        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                tokenName,
                '","description":"',
                tokenDescription,
                '","totalScore":',
                Converter.uint2str(totalScore),
                '","gamesPlayed":',
                Converter.uint2str(gamesPlayed),
                '","image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svgString)),
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));

        return super.tokenURI(tokenId);
    }

    function _tokenSVG(
        string memory _nickname,
        uint256 _tokenId,
        uint256 _totalScore,
        uint256 _gamePlayed
    ) public pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:green">',
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "40"),
                        svg.prop("font-size", "22"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Crypto Snake #"), utils.uint2str(_tokenId))
                ),
                svg.rect(
                    string.concat(
                        svg.prop("fill", "red"),
                        svg.prop("x", "20"),
                        svg.prop("y", "50"),
                        svg.prop("width", utils.uint2str(160)),
                        svg.prop("height", utils.uint2str(10))
                    ),
                    utils.NULL
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "100"),
                        svg.prop("font-size", "22"),
                        svg.prop("fill", "white")
                    ),
                    _nickname
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "160"),
                        svg.prop("font-size", "22"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Total Score: "), utils.uint2str(_totalScore))
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "200"),
                        svg.prop("font-size", "22"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Games Played: "), utils.uint2str(_gamePlayed))
                ),
                "</svg>"
            );
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
