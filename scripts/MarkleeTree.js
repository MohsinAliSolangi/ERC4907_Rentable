// https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
//
// 1. Import libraries. Use `npm` package manager to install
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// 2. Collect list of wallet addresses from competition, raffle, etc.
// Store list of addresses in some data sheeet (Google Sheets or Excel)
let whitelistAddresses = [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    // The address in remix
  ];

  [
    "0x04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54",
    "0x9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65"
  ]

// 3. Create a new array of `leafNodes` by hashing all indexes of the `whitelistAddresses`
// using `keccak256`. Then creates a Merkle Tree object using keccak256 as the algorithm.
//
// The leaves, merkleTree, and rootHas are all PRE-DETERMINED prior to whitelist claim
const leafNodes = whitelistAddresses.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true});
const buf2hex = x => '0x' + x.toString('hex')
// 4. Get root hash of the `merkleeTree` in hexadecimal format (0x)
// Print out the Entire Merkle Tree.
const rootHash = buf2hex(merkleTree.getRoot());
console.log('Whitelist Merkle Tree\n', merkleTree.toString());
console.log("Root Hash: ", rootHash);

// ***** ***** ***** ***** ***** ***** ***** ***** // 

// CLIENT-SIDE: Use `msg.sender` address to query and API that returns the merkle proof
// required to derive the root hash of the Merkle Tree



//here we get proof
// const leaf = keccak256(leafNodes) // address from wallet using walletconnect/metamask
// const proof = merkleTree.getProof(leaf).map(x => buf2hex(x.data))
// console.log("this is proof",proof);

["0x04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54","0x9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65"]

// ✅ Positive verification of address
const claimingAddress = leafNodes[3];
// ❌ Change this address to get a `false` verification
// const claimingAddress = keccak256("0X5B38DA6A701C568545DCFCB03FCB875F56BEDDD6");

// `getHexProof` returns the neighbour leaf and all parent nodes hashes that will
// be required to derive the Merkle Trees root hash.
const hexProof = merkleTree.getHexProof(claimingAddress);
console.log(hexProof);

// ✅ - ❌: Verify is claiming address is in the merkle tree or not.
// This would be implemented in your Solidity Smart Contract
console.log(merkleTree.verify(hexProof, claimingAddress, rootHash));