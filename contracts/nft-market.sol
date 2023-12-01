// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol"; 
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

    constructor(IERC20 _erc20, IERC721 _erc721) {
        erc20 = _erc20;
        erc721 = _erc721;
    }

    function listNFTToMarket(IERC721 _nft, uint256 _tokenId, uint256 _price) public {
        require(_nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_nft.getApproved(_tokenId) == address(this), "Token is not approved for the market");

        NFTListing memory listing;
        listing.nftAddress = _nft;
        listing.tokenId = _tokenId;
        listing.price = _price;
        listing.isListed = true;

        listings[currentOrderId] = listing;
        currentOrderId++;
    }

    function unlistNFTFromMarket(uint256 _orderId) external {
        require(listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId) == msg.sender, "You are not the owner of this NFT");
        listings[_orderId].isListed = false;
    }

    function changeNFTPrice(uint256 _orderId, uint256 _newPrice) external {
        require(listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId) == msg.sender, "You are not the owner of this NFT");
        listings[_orderId].price = _newPrice;
    }

    function buyNFT(uint256 _orderId) external payable{
        require(msg.value >= listings[_orderId].price, "Insufficient funds to buy this NFT");
        require(!listings[_orderId].isSold, "This NFT has already been sold");

        address owner = listings[_orderId].nftAddress.ownerOf(listings[_orderId].tokenId);
        listings[_orderId].nftAddress.transferFrom(owner, msg.sender, listings[_orderId].tokenId);
        payable(owner).transfer(listings[_orderId].price);

        listings[_orderId].isSold = true;
    }

    receive() external payable {}
}