// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Market {
    IERC20 public erc20;
    IERC721 public erc721;

    struct NFTListing {
        IERC721 nftAddress;
        uint256 tokenId;
        uint256 price;
        bool isListed;
        bool isSold; 
    }

    uint256 public currentOrderId;
    mapping(uint256 => NFTListing) public listings; 

    // Event declarations
    event NFTListed(uint256 indexed orderId, address indexed nftAddress, uint256 tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed orderId);
    event NFTPriceChanged(uint256 indexed orderId, uint256 newPrice);
    event NFTBought(uint256 indexed orderId, address indexed buyer, uint256 price);

    constructor(IERC20 _erc20, IERC721 _erc721) {
        erc20 = _erc20;
        erc721 = _erc721;
    }

    function listNFTToMarket(
        IERC721 _nft, 
        uint256 _tokenId, 
        uint256 _price
        ) public {
            require(
                _nft.ownerOf(_tokenId) == msg.sender, 
                "You are not the owner of this NFT"
            );
            require(
                _nft.getApproved(_tokenId) == address(this), 
                "Token is not approved for the market"
            );

        NFTListing memory listing;
        listing.nftAddress = _nft;
        listing.tokenId = _tokenId;
        listing.price = _price;
        listing.isListed = true;

        listings[currentOrderId] = listing;
        
        emit NFTListed(
            currentOrderId, 
            address(_nft), 
            _tokenId, 
            _price
        );

        currentOrderId++;
    }

    function unlistNFTFromMarket(uint256 _orderId) external {
        require(listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId) == msg.sender, "You are not the owner of this NFT");
        listings[_orderId].isListed = false;

        emit NFTUnlisted(_orderId);
    }

    function changeNFTPrice(
        uint256 _orderId, 
        uint256 _newPrice
        ) external {
        require(listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId) == msg.sender, "You are not the owner of this NFT");
        listings[_orderId].price = _newPrice;

        emit NFTPriceChanged(_orderId, _newPrice);
    }

    function buyNFT(uint256 _orderId) external payable{
        require(msg.value >= listings[_orderId].price, "Insufficient funds to buy this NFT");
        require(!listings[_orderId].isSold, "This NFT has already been sold");

        address owner = listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId);
        listings[_orderId].nftAddress.transferFrom(owner, msg.sender, listings[_orderId].tokenId);
        payable(owner).transfer(listings[_orderId].price);

        listings[_orderId].isSold = true;

        emit NFTBought(_orderId, msg.sender, listings[_orderId].price);
    }

    function getListNFTsOrderNumber() public view returns(
        uint256[] memory
        ){
        uint256 count = 0;
        for (uint256 i = 0; i < currentOrderId; i++) {
            if (listings[i].isListed) {
                count++;
            }
        }

        uint256[] memory allListNFTs = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < currentOrderId; i++) {
            if (listings[i].isListed) {
                allListNFTs[index] = i;
                index++;
            }
        }

        return allListNFTs;
    }

    function getListLength() public view returns(uint256) {
        return getListNFTsOrderNumber().length;
    }

    receive() external payable {}
}