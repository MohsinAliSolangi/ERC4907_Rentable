// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC4907.sol";

error totalSupplyExceed();
error PleaseWaitForPreSaleSaleStart();
error YouDontHaveBalance();
error YourPresaleMintingLimitExceed();
error WaitForSaleActivation();
error youAreNotWhiteLidted();

contract Rentable  is ERC721,Ownable {
    
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
    uint256 public tokenIds=51;
    uint256 public ownerReserve;
    uint256 public mintedNFTs;

    uint64 public rentAmount = 1 ether;


    struct UserInfo 
    {
        address user;  
        uint64 expires; 
    }
    
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    
    mapping (uint256  => UserInfo) internal _users;
    mapping(address => bool) public whiteListUser;

    IERC20 TOKEN;

    // Calculated from `merkle_tree.js`
    bytes32 public merkleRoot = 
    0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097;


    constructor(address _token) ERC721("MyToken", "MTK") {

        TOKEN=IERC20(_token);
    }

    function mint(address to) public {
    
    if(owner()==msg.sender && ownerReserve<=50){
        ownerReserve++;
        mintedNFTs++;
        _safeMint(to,ownerReserve); 
    }
    
   else if(mintedNFTs>=supply){
        revert totalSupplyExceed();
    }

   else if(!preSale && !sale){
     revert PleaseWaitForPreSaleSaleStart();
    }
    
   else if(preSale==true){
     if(block.timestamp>preSaleEndTime){
         preSale=false;
     }
     else if (whiteListUser[msg.sender] == false){
         revert youAreNotWhiteLidted();
     }
     else if(TOKEN.balanceOf(msg.sender)<preSalePrice){
            revert YouDontHaveBalance();
        }
     else if(balanceOf(msg.sender)>=limitPreSale){
            revert YourPresaleMintingLimitExceed();
        }   
        _safeMint(to, tokenIds);
        TOKEN.transferFrom(msg.sender,address(this),preSalePrice);
        tokenIds++;
        mintedNFTs++; 
    }   
    else if(sale){
    if(block.timestamp>saleEndTime){
         sale=false;
     }
     else if(TOKEN.balanceOf(msg.sender)<SalePrice){
            revert YouDontHaveBalance();
        }
     else if(balanceOf(msg.sender)>=limitSale){
            revert YourPresaleMintingLimitExceed();
        }
        _safeMint(to, tokenIds);
        TOKEN.transferFrom(msg.sender,address(this),SalePrice);    
        tokenIds++;
        mintedNFTs++;
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
     
     TOKEN.transferFrom(msg.sender,address(this),(SalePrice*_amount));
   
    for (uint256 i; i < _amount; i++ ){     
            _safeMint(msg.sender, tokenIds);
            tokenIds++;
            mintedNFTs++;
        }
       
    }   
    

    function activePreSale(uint256 _time) public {
        preSaleStartTime=block.timestamp +_time;
        preSaleEndTime=preSaleStartTime+30 minutes; 
        preSale=true;
       
    }

    function activeSale(uint256 _time) public {
        saleStartTime=block.timestamp +_time;
        saleEndTime=saleStartTime+30 minutes;
        sale=true;
        preSale=false; 
    }  
       

    function stats() public view returns (uint256[] memory) {
    uint256[] memory res = new uint256[](11);
        res[0] = mintedNFTs;
        res[1] = balanceOf(owner());
        res[2] = preSaleEndTime;
        res[3] = preSaleStartTime;
        res[4] = saleEndTime;
        res[5] = saleStartTime;
        res[6] = SalePrice;
        res[7] = preSalePrice;
        res[8] = supply;
        res[9] = limitSale;
        res[10] = limitPreSale;
    return res;
  }

    function getNftType(address nftContract) public view returns(string memory){
     if(IERC721(nftContract).supportsInterface(0x80ac58cd))
      return "ERC721" ;
     else
      return "ERC1155" ;
    }

  //++++++++++++++++++++++++ NFTRental+++++++++++++++//
    
    function setUser(uint256 tokenId, address user, uint64 expires) public virtual{
        require(expires>2,"Please add more time");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        UserInfo storage info =  _users[tokenId];
        require(info.user==address(0),"nft already on Rent"); 
        
        TOKEN.transferFrom(user,msg.sender,rentAmount);
        
        uint64 temp=(uint64(block.timestamp)+expires);     
        info.user = user;
        info.expires = temp;
        emit UpdateUser(tokenId, user, temp);
    }


    function userOf(uint256 tokenId) public view virtual returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].user;
        }
        else{
            return owner();
        }
    }
    
    function userExpires(uint256 tokenId) public view virtual returns(uint256){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return _users[tokenId].expires;
        }
        else{
            return 1010101010101010101010101010;
        }
    }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId,1);
        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }

    //++++++++++++++++++++Marklee Tree +++++++++++++++
  
    // --- FUNCTIONS ---- //

    function addwhiteListUser(bytes32[] calldata _merkleProof) public {
        require(!whiteListUser[msg.sender], "Address already Added");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof."
        );
        whiteListUser[msg.sender] = true;
    }

  

}