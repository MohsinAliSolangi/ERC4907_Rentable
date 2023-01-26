// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error totalSupplyExceed();
error PleaseWaitForPreSaleSaleStart();
error YouDontHaveBalance();
error YourPresaleMintingLimitExceed();
error WaitForSaleActivation();

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;

    bool public preSale;
    uint256 public limitPreSale=1;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSalePrice= 0.0027 ether;
    
    bool public sale;
    uint256 public limitSale=3;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public SalePrice= 0.1691 ether;

    uint256 public supply=1691;

    Details [] public details;

    IERC20 TOKEN;

    struct Details{
        uint256 TotalMintedNfts;
        uint256 MintedNFTByOwner;
        uint256 PreSaleEndTime;
        uint256 PreSaleStartTime;
        uint256 SaleEndTime;
        uint256 SaleStartTime;
        uint256 SalePrice;
        uint256 preSalePrice;
        uint256 totalSupply;
        uint256 limitOfuserSale;
        uint256 limitOfuserPreSale;
    }


    constructor(address _token) ERC721("MyToken", "MTK") {

        TOKEN=IERC20(_token);
    }

    function mint(address to) public {
    if(_tokenIdCounter.current()>=1691){
        revert totalSupplyExceed();
    }
    
    if(!preSale && !sale){
     revert PleaseWaitForPreSaleSaleStart();
    }

    if(preSale==true){
     if(block.timestamp>preSaleEndTime){
         preSale=false;
     }
     if(TOKEN.balanceOf(msg.sender)<preSalePrice){
            revert YouDontHaveBalance();
        }
     if(balanceOf(msg.sender)>=limitPreSale){
            revert YourPresaleMintingLimitExceed();
        }   
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        TOKEN.transferFrom(msg.sender,address(this),preSalePrice);
        
    }   
    else if(sale){
    if(block.timestamp>saleEndTime){
         sale=false;
     }
     if(TOKEN.balanceOf(msg.sender)<SalePrice){
            revert YouDontHaveBalance();
        }
     if(balanceOf(msg.sender)>=limitSale){
            revert YourPresaleMintingLimitExceed();
        }
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        TOKEN.transferFrom(msg.sender,address(this),SalePrice);    
    }
    
    }

    function bulkMinting(uint256 _amount)public{
        if(!sale){
            revert WaitForSaleActivation();
        }
     if(TOKEN.balanceOf(msg.sender)<(SalePrice*_amount)){
            revert YouDontHaveBalance();
        }
     if(balanceOf(msg.sender)>=3){
            revert YourPresaleMintingLimitExceed();
        }   
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        TOKEN.transferFrom(msg.sender,address(this),(SalePrice*_amount));
        
    }   
    

    function ActivePreSale(uint256 _time) public {
        preSaleStartTime=block.timestamp +_time;
        preSaleEndTime=preSaleStartTime+30 minutes; 
        preSale=true;
       
    }

    function ActiveSale(uint256 _time) public {
        saleStartTime=block.timestamp +_time;
        saleEndTime=saleStartTime+30 minutes;
        sale=true;
        preSale=false; 
    }   

    function status() public view returns(Details[] memory) {
    uint256 tokenId=_tokenIdCounter.current();
    uint256 tokensMint;
    for(uint256 i=0; i<(tokenId+1);i++){
        if(_exists(i)){
           tokensMint++; 
        }
    }
    details.push(Details({
        TotalMintedNfts: tokensMint,
        MintedNFTByOwner: balanceOf(owner()),
        PreSaleEndTime: preSaleEndTime,
        PreSaleStartTime:preSaleStartTime,
        SaleEndTime: saleEndTime,
        SaleStartTime: saleStartTime,
        SalePrice: SalePrice,
        preSalePrice: preSalePrice,
        totalSupply: supply,
        limitOfuserSale: limitSale, 
        limitOfuserPreSale: limitPreSale
    }));

    uint256 id = details.length;
        Details[] memory sales = new Details[](id);
    for(uint256 i=0; i<id; i++){
        sales[i];
    }
        return sales;
    }


    
    function DetailsOfNFT()public view returns(Details[] memory){
        uint256 id = details.length;
        Details[] memory sales = new Details[](id);
    for(uint256 i=0; i<id; i++){
        sales[i];
    }
        return sales;
    }
 

   

}