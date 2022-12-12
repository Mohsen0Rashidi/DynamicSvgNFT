// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

/*Errors*/
error ERC721Metadata__URI_QueryFor_NonExistentToken();

/**@title A dynamic NFT hosted onchain
 * @author Mohsen Rashidi
 * @notice This contract is for creating a dynamic NFT that change based on Chainlink price
 * @dev This implements the Chainlink Price Feed and Base64
 */

contract DynamicSvgNft is ERC721 {
    /*Variables*/
    uint256 private s_tokenCounter;
    string private s_lowImageURI;
    string private s_highImageURI;

    AggregatorV3Interface private immutable i_priceFeed;
    mapping(uint256 => int256) public s_tokenIdToHighValues;

    /*Events*/
    event CreatedNft(uint256 indexed tokenId, int256 highValue);

    /*Functions*/
    constructor(
        address priceFeed,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("SVG NFT", "SN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeed);
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);
    }

    /**
     * @dev This is the function that mint an NFT with high Value for each tokenId
     */
    function mintNft(int256 highValue) public {
        s_tokenIdToHighValues[s_tokenCounter] = highValue;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
        emit CreatedNft(s_tokenCounter, highValue);
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /**
     * @notice if price is less than the high value then mint the frowny NFT
     * and if price is over the high value then mint the happy NFT
     */

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_lowImageURI;
        if (price >= s_tokenIdToHighValues[tokenId]) {
            imageURI = s_highImageURI;
        }

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '","descriptoin":"An NFT that changed based on the Chainlink Feed","attributes":[{"trait_type":"coolness","value":100}],"image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getLowImageURI() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighImageURI() public view returns (string memory) {
        return s_highImageURI;
    }
}
