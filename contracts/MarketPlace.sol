// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error MarketPlace__NotApprovedForMarketplace();
error MarketPlace__PriceMustBeAboveZero();
error MarketPlace__NotOwner();
error MarketPlace__NotListed(address nftAddress,uint256 tokenId);
error MarketPlace__AlreadyListed(address nftAdress,uint256 tokenId);
error  MarketPlace__PriceNotMet(address nftAdress, uint256 tokenId, uint256 prices);
error MarketPlace__TransferFailed();
error MarketPlace__NoProceeds();


contract MarketPlace 
//is ReentrancyGuard
{
  struct Listing {
    uint256 prices;
    address seller;
  }

  event itemlist(
    address indexed seller,
    address indexed nftAdress,
    uint256 indexed tokenId,
    uint256 prices
  );

  event ItemBought(
  address indexed buyer,
  address indexed nftAddress,
  uint256 indexed tokenId,
  uint256 prices
  );

  event ItemCancel(
    address indexed seller,
    address indexed nftAdress,
    uint256 indexed tokenId
  );
 
 mapping(address => mapping(uint256 => Listing)) private s_listing;
 
 //seller adress->amount earned
 mapping(address => uint256) private s_proceeds;

 modifier notListed(address nftAdress, uint256 tokenId, address owner){
    Listing memory listing = s_listing[nftAdress][tokenId];
    if(listing.prices >0){
        revert MarketPlace__AlreadyListed(nftAdress, tokenId);
    }
 _;
 }

 modifier isOwner(address nftAdress, uint256 tokenId, address spender){
    IERC721 nft = IERC721(nftAdress);
    address owner = nft.ownerOf(tokenId);
    if(spender != owner){
        revert MarketPlace__NotOwner();
    }
    _;
 }

 modifier isListed(address nftAdress, uint256 tokenId){
    Listing memory listing = s_listing[nftAdress][tokenId];
    if (listing.prices <=0 ){
        revert MarketPlace__NotListed(nftAdress, tokenId);
    }
  _;}


 function ListProducts(address nftAdress, uint256 tokenId, uint256 prices) 
 
 external notListed(nftAdress, tokenId, msg.sender)
 isOwner(nftAdress,tokenId, msg.sender)
 {

 if(prices<=0){
    revert MarketPlace__PriceMustBeAboveZero();
 }
 
 IERC721 nft = IERC721(nftAdress);
  if (nft.getApproved(tokenId) != address(this)){
    revert MarketPlace__NotApprovedForMarketplace();
  }

 s_listing[nftAdress][tokenId] = Listing(prices,msg.sender);
 emit itemlist(msg.sender, nftAdress, tokenId, prices);
 }

 /// buy list fuction

 function BuyItem(address nftAdress, uint256 tokenId) 
 external payable
 //nonReentrant
 isListed(nftAdress, tokenId) {
 
 Listing memory listedItem = s_listing[nftAdress][tokenId];

 if (msg.value < listedItem.prices){
    revert MarketPlace__PriceNotMet(nftAdress, tokenId, listedItem.prices);
 }
  
  s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
   delete(s_listing[nftAdress][tokenId]);
   IERC721(nftAdress).safeTransferFrom(listedItem.seller, msg.sender,tokenId);
   
   emit ItemBought(msg.sender, nftAdress, tokenId, listedItem.prices);
 
 }

function cancelListing(address nftAdress, uint256 tokenId)
external isOwner(nftAdress, tokenId, msg.sender)
isListed (nftAdress, tokenId)
{
    delete(s_listing[nftAdress][tokenId]);
    emit ItemCancel(msg.sender, nftAdress, tokenId);
}

function updateListing(
    address nftAdress,
    uint256 tokenId,
    uint256 newPrice
) external isListed(nftAdress, tokenId) isOwner (nftAdress,tokenId, msg.sender)
{
s_listing[nftAdress][tokenId].prices = newPrice;
emit itemlist(msg.sender, nftAdress, tokenId, newPrice);
}

function withdrawProceeds() external {
    uint256 proceeds = s_proceeds[msg.sender];
    if (proceeds <= 0){
        revert MarketPlace__NoProceeds();
    }
    s_proceeds[msg.sender] = 0;
    (bool success, )= payable(msg.sender).call{value: proceeds}("");
    if(!success){
        revert MarketPlace__TransferFailed();
    }
}

/// getters

function getListing(address nftAdress, uint256 tokenId)
external
view 
returns (Listing memory)
{
    return s_listing[nftAdress][tokenId];
}

function getProceeds(address seller)
external 
view
returns (uint256)
{
    return s_proceeds[seller];
} 

//end of file
}