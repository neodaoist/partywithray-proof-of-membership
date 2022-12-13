// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import "./utils.sol";
import "forge-std/console.sol";     // FIXME: Remove before mainnet deploy

/// @notice
contract TheLow is ERC721, Owned {
    //
    event SupplyUpdated(uint8 indexed newSupply);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event UpdateMetadata(uint256 tokenId);
    // event MetadataUpdated(string uri);
    // event MetadataFrozen();

    uint8 public constant MAX_SUPPLY = 222;
    uint8 public totalSupply = 222;

    struct Tier {
        string name;
        string rarity;
        string image_cid;
        string animation_cid;
        string animation_hash;
        uint16 portion;  // How many tokenIds, out of 222, of this type will be created
    }

    struct RandBytes {
        bytes32 data;
        uint8 index;
    }
    Tier[6] internal _tierInfo;
    uint8[MAX_SUPPLY+1] internal _tokenTiers;  // TokenIds are 1-indexed

/*
CONSTRUCTOR
*/

constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
    // Create the tier info table
    //                   Name                Rarity         Image CID                                                      Animation CID                                                  Animation Hash                                                     Post-reveal portion (ceil(222 / N*100))
    _tierInfo[0] = Tier('Pre-reveal',       'Pre-reveal',  'bafybeiftai3ybdl727tbg7ajunjmehbmciinczprk6nxt2xznjxljsmm7y', 'bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm', 'd02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac', 0);
    _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', 'afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52', 200);
    _tierInfo[2] = Tier('The Basic Low',    'Common',      'bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa', 'bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4', 'af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460', 296);
    _tierInfo[3] = Tier('The Medium Low',   'Uncommon',    'bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey', 'bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq', '05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4', 1010);
    _tierInfo[4] = Tier('The Low Low',      'Rare',        'bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb', 2019);
    _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare',   'bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm', 'bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u', '8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879', 7400);

    // Mint NFTs
    mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
}

    /* TOKEN URI */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                utils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "The Low ', utils.uint256ToString(tokenId), '/222',
                                '", "description": "partywithray Proof of Membership", "image": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].image_cid,
                                '", "animation_url": "ipfs://', _tierInfo[_tokenTiers[tokenId]].animation_cid,
                                '", "attributes": { "Tier Name": "',
                                _tierInfo[_tokenTiers[tokenId]].name,
                                 '", "Tier Rarity" : "',
                                _tierInfo[_tokenTiers[tokenId]].rarity,
                                '"}, "content": {"mimeType": "video/mp4", "hash": "',
                                 _tierInfo[_tokenTiers[tokenId]].animation_hash, '", "uri": "ipfs://',
                                 _tierInfo[_tokenTiers[tokenId]].animation_cid, '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /* -----------------------------------------------------------
                        BATCH MINT
    ----------------------------------------------------------- */
    function mintBatch(address to, uint256 start, uint256 end, uint8 tierIndex) public {
        for(uint i = start; i <= end; i++) {
            _mint(to, i);
            _tokenTiers[i] = tierIndex;
        }
    }

    /* -----------------------------------------------------------
                        UPDATE SUPPLY
    ----------------------------------------------------------- */

    function updateSupply(uint8 _newSupply) public onlyOwner {
        require(_newSupply < totalSupply, "INVALID_SUPPLY");
        require(_tokenTiers[1] == 0, "ALREADY_REVEALED");
        uint256 currentSupply = totalSupply;
        // Burn the highest tokenIds first for aesthetics
        for(uint8 index = MAX_SUPPLY; index > 0 && currentSupply > _newSupply; index--) {
            if(_ownerOf[index] == msg.sender) {  // Only burn the tokens we own
                //FIXME console.log("Burning: ", index, ", Owned by: ", _ownerOf[index]);
                _burn(index);
                currentSupply--;
            }
        }
        totalSupply = _newSupply;

        emit SupplyUpdated(_newSupply);
    }

    /* --------------------------------------------------------------
                        RANDOM REVEAL
    -------------------------------------------------------------- */
    /// Returns one byte of pseudorandom data from a pre-seeded structure.  Re-hashes to get more randomness from the same seend as needed
    /// @param randdata pre-seeded pseudorandom data struct
    function getRandByte(RandBytes memory randdata) private pure returns (uint8) {
        if(randdata.index >= 8) {
            randdata.data = keccak256(abi.encodePacked(randdata.data));
            randdata.index = 0;
        }
        bytes1 value = randdata.data[randdata.index];
        randdata.index++;
        return uint8(value);
    }


    /// @dev Uses blocks.prevrandao as random source.  Small MEV risk but simple.  Could use Chainlink VRF here too.
    function reveal() onlyOwner public {
        // Initialize PRNG -- using blocks.
        RandBytes memory randdata = RandBytes(keccak256(abi.encodePacked(block.difficulty)), 0);

        // Build an array of all the un-burned tokenIds
        uint8[] memory lottery = new uint8[](totalSupply);
        uint8 index = 0;
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if ( _ownerOf[tokenId] != address(0) ) {
                lottery[index] = tokenId;  // Can't use .push on memory arrays so we maintain our own index
                index++;
            }
        }
        assert(index == totalSupply);  // FIXME: Remove before mainnet deploy
        index--;  // index will be totalSupply, or one past the end of lottery's used range

        // Roll random dice for tiers 5 through 2
        for (uint8 tiernum = 5; tiernum > 1; tiernum-- ) {
            uint targetAmount = divideRoundUp(totalSupply,_tierInfo[tiernum].portion,100);   // FIXME: Proportional amounts if we don't sell out
            while(targetAmount > 0) {
                uint8 randIndex = getRandByte(randdata);
                if(index < 128 ) {
                    randIndex = randIndex & 0x7F;  // Optimization: use 7 bits of entropy if we're below 128 items
                }
//FIXME console.log("Next Rand: ",randIndex,", Index: ",index);
                if (randIndex <= index) {
                    // assign the tokenId rolled to the tier
                    _tokenTiers[lottery[randIndex]] = tiernum;
                    // remove the item from the lottery by replacing it with the item at the end of the array to avoid shifting
                    lottery[randIndex] = lottery[index];
//FIXME console.log("Assigned tokenId to tier: ",lottery[index],tiernum);
                    index--;
                    targetAmount--;
                }
            }
        }
        // Assign any remaining tokenIds to tier 1, unless burned
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0) ) {
                _tokenTiers[tokenId] = 1;
            }
        }
        emit BatchMetadataUpdate(1, 222);

    }

    /// numeric tier for a given tokenId
    function tier(uint256 tokenId) public view returns (uint8) {
        return _tokenTiers[uint8(tokenId)];
    }

    /// Transfers a contiguous range of tokenIds to a given address -- useful for efficiently transferring a block to a vault
    function batchTransfer(address from, address to, uint256 startTokenId, uint256 endTokenId) public {
        for(uint256 i = startTokenId; i < endTokenId; i++) {
            transferFrom(from, to, i);
        }
    }

    /// Divide and round UP
    /// @dev does not check for division by zero
    function divideRoundUp(uint numerator, uint denominator, uint precision) public pure returns(uint8 quotient) {
        // Add precision
        return uint8(((numerator * precision + denominator - 1) / denominator));
    }

    /// @dev see ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721) returns (bool) {
        return interfaceId == 0x2a55205a // ERC2981 -- royaltyInfo
            || interfaceId == 0x01ffc9a7 // ERC165 -- supportsInterface
            || interfaceId == 0x80ac58cd // ERC721 -- Non-Fungible Tokens
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    /// @notice Returns royalty info for a given token and sale price
    /// @dev Not using SafeMath here as the denominator is fixed and can never be zero,
    /// @dev but consider doing so if changing royalty percentage to a variable
    /// @return receiver the contract owner's address
    /// @return royaltyAmount a fixed 10% royalty based on the sale price
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner, salePrice / 10);
    }

}