// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC4907.sol";
import "hardhat/console.sol";

error totalSupplyExceed();
error PleaseWaitForPreSaleStart();
error YouDontHaveBalance();
error YourPresaleMintingLimitExceed();
error youAreNotWhiteLidted();
error YourSaleMintingLimitExceed();
error PleaseWaitForSaleStart();

contract MyToken is ERC721, Ownable {
    bool public preSale;
    uint256 public limitPreSale = 1;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSalePrice = 0.0027 ether;

    bool public sale;
    uint256 public limitSale = 3;
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public SalePrice = 0.1691 ether;

    uint256 public supply = 1691;
    uint256 public tokenIds = 51;
    uint256 public ownerReserve = 1;
    uint256 public mintedNFTs;

    uint64 public rentAmount = 1 ether;

    struct UserInfo {
        address user;
        uint64 expires;
    }

    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    mapping(uint256 => UserInfo) internal _users;
    mapping(address => bool) public whiteListUser;
    mapping(address => uint256) public mintingLimit;

    IERC20 TOKEN;

    // Calculated from `merkle_tree.js`
    bytes32 public root;

    constructor(address _token, bytes32 _root) ERC721("MyToken", "MTK") {
        TOKEN = IERC20(_token);
        root = _root;
    }

    function mint(address to) public {
        if (block.timestamp > saleEndTime && sale == true) {
            sale = false;
        } else if (sale) {
            if (owner() == msg.sender) {
                if (ownerReserve > 50) {
                    revert YourSaleMintingLimitExceed();
                }
                mintedNFTs++;
                _safeMint(to, ownerReserve);
                ownerReserve++;
                mintingLimit[msg.sender] += 1;
            } else if (mintedNFTs >= supply) {
                revert totalSupplyExceed();
            } else if (TOKEN.balanceOf(msg.sender) < SalePrice) {
                revert YouDontHaveBalance();
            } else if (mintingLimit[msg.sender] >= limitSale) {
                revert YourSaleMintingLimitExceed();
            }
            TOKEN.transferFrom(msg.sender, address(this), SalePrice);
            mintedNFTs++;
            _safeMint(to, tokenIds);
            tokenIds++;
            mintingLimit[msg.sender] += 1;
        } else if (!sale) {
            revert PleaseWaitForSaleStart();
        }
    }

    function preSaleMinting(address to, bytes32[] memory proof) public {
        if (block.timestamp > preSaleEndTime && preSale == true) {
            preSale = false;
        } else if (preSale) {
            if (TOKEN.balanceOf(msg.sender) < preSalePrice) {
                revert YouDontHaveBalance();
            } else if (mintingLimit[msg.sender] >= limitPreSale) {
                revert YourPresaleMintingLimitExceed();
            }
            require(isValid(proof), "You are not whiteListed");
            TOKEN.transferFrom(msg.sender, address(this), preSalePrice);
            mintedNFTs++;
            _safeMint(to, tokenIds);
            tokenIds++;
            mintingLimit[msg.sender] += 1;
        } else {
            revert PleaseWaitForPreSaleStart();
        }
    }

    function bulkMinting(uint256 _amount) public {
        if (owner() == msg.sender) {
            for (uint256 i; i < _amount; i++) {
                if (ownerReserve > 50) {
                    revert YourSaleMintingLimitExceed();
                }
                mintedNFTs++;
                _safeMint(msg.sender, ownerReserve);
                ownerReserve++;
                mintingLimit[msg.sender] += 1;
            }
        } else if (TOKEN.balanceOf(msg.sender) < (SalePrice * _amount)) {
            revert YouDontHaveBalance();
        } else if (sale) {
            require(
                _amount <= limitSale,
                "Plase input only limited(saleLimit) values"
            );
            TOKEN.transferFrom(
                msg.sender,
                address(this),
                (SalePrice * _amount)
            );
            for (uint256 i; i < _amount; i++) {
                if (mintingLimit[msg.sender] >= limitSale) {
                    revert YourSaleMintingLimitExceed();
                }
                mintedNFTs++;
                _safeMint(msg.sender, tokenIds);
                tokenIds++;
                mintingLimit[msg.sender] += 1;
            }
        } else {
            revert PleaseWaitForSaleStart();
        }
    }

    function activePreSale(uint256 _time) public {
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + _time;
        preSale = true;
    }

    function activeSale(uint256 _time) public {
        saleStartTime = block.timestamp;
        saleEndTime = saleStartTime + _time;
        sale = true;
        preSale = false;
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

    function getNftType(
        address nftContract
    ) public view returns (string memory) {
        if (IERC721(nftContract).supportsInterface(0x80ac58cd)) return "ERC721";
        else return "ERC1155";
    }

    //++++++++++++++++++++++++ NFTRental+++++++++++++++//

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        require(expires > 2, "Please add more time");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC4907: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        require(info.user == address(0), "nft already on Rent");

        TOKEN.transferFrom(user, msg.sender, rentAmount);

        uint64 temp = (uint64(block.timestamp) + expires);
        info.user = user;
        info.expires = temp;
        emit UpdateUser(tokenId, user, temp);
    }

    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0x110001111000111);
        }
    }

    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].expires;
        } else {
            return 1010101010101010101010101010;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }

    //++++++++++++++++++++Marklee Tree +++++++++++++++

    function isValid(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function BlockTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }
}
