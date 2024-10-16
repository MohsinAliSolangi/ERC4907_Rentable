const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");


["Put Account Private Keys Here ","Put Account Private Keys Here"]
let nft
let token

describe("Deployment  ", function () {
  it("Contracts Deploy here", async function () {
   [per1,per2, per3 ,per4] = await ethers.getSigners();

    const ERC20Token = await ethers.getContractFactory("MyToken");
    token = await ERC20Token.deploy();
    console.log(`This is ERC20Token ${token.address} deployed `);

    const NFTContract = await ethers.getContractFactory("Rentable");
    nft = await NFTContract.deploy(token.address);
    console.log(`This is NFTContract ${nft.address} deployed `);   
  });
});


describe("Minting Funtionality ", function () {
  it("Owner Reserve nft's dont Need to Token", async function(){
    await nft.mint(per1.address);
    const balace = await nft.balanceOf(per1.address);
    console.log("this is after Minting owner Balance:",balace)
    console.log("this is  minted nft's:",await nft.mintedNFTs());
    console.log("this is counter ownerReserve:", await nft.ownerReserve());
    console.log("this is counter tokenIds:",await nft.tokenIds());
  });

  //Failllllllllllllllllllllllll
  // it("This call will be fail because sales is not start",async function(){
  //   await nft.connect(per2).mint(per2.address);
  //   const balace = await nft.balanceOf(per2.address);
  //   console.log("this is after Minting owner Balance:",balace)
  //   console.log("this is  minted nft's:",await nft.mintedNFTs());
  //   console.log("this is counter tokenIds:",await nft.tokenIds());
  // })
  
  it("this is presale activate call ",async function(){
    await nft.activePreSale(5);
    console.log("successfully activate");
  })

  it("this call (minting) will be fail becasue this is not whitelistaddr:", async function (){
    await nft.connect(per2).mint(per2.address);    
  })

  

});