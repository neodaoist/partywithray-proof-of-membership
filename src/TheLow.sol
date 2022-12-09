// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import "./utils.sol";

/// @notice
contract TheLow is ERC721, Owned {
    //
    event SupplyUpdated(uint8 indexed newSupply);
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
        uint8 portion;  // How many tokenIds, out of 222, of this type will be created
    }

    struct RandBytes {
        bytes32 data;
        uint8 index;
    }
   Tier[6] internal _tierInfo;
   uint8[MAX_SUPPLY+1] internal _tokenTiers;  // TokenIds are 1-indexed

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
        // Create the tier info table
        //                   Name                Rarity         Image CID                                                      Animation CID                                                  Animation Hash                                                     Post-reveal quantity (out of 222)
        _tierInfo[0] = Tier('Pre-reveal',       'Pre-reveal',  'bafybeiftai3ybdl727tbg7ajunjmehbmciinczprk6nxt2xznjxljsmm7y', 'bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm', 'd02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac', 0);
        _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', 'afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52', 111);
        _tierInfo[2] = Tier('The Basic Low',    'Common',      'bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa', 'bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4', 'af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460', 75);
        _tierInfo[3] = Tier('The Medium Low',   'Uncommon',    'bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey', 'bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq', '05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4', 22);
        _tierInfo[4] = Tier('The Low Low',      'Rare',        'bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb', 11);
        _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare',   'bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm', 'bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u', '8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879', 3);

        // Mint NFTs
        mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                        BATCH MINT
    //////////////////////////////////////////////////////////////*/
    function mintBatch(address to, uint256 start, uint256 end, uint8 tierIndex) public {
        for(uint i = start; i <= end; i++) {
            _mint(to, i);
            _tokenTiers[i] = tierIndex;
        }
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE SUPPLY
    //////////////////////////////////////////////////////////////*/

    // TODO account for existing tokens w/ owners
    function updateSupply(uint8 _newSupply) public onlyOwner {
        require(_newSupply < totalSupply, "INVALID_SUPPLY");

        for (uint256 i = _newSupply + 1; i <= totalSupply; i++) {
            _burn(i);
        }
        totalSupply = _newSupply;

        emit SupplyUpdated(_newSupply);
    }

   /*//////////////////////////////////////////////////////////////
                        RANDOM REVEAL
    //////////////////////////////////////////////////////////////*/
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
    function reveal() public onlyOwner {
        // Initialize PRNG -- using blocks.
        RandBytes memory randdata = RandBytes(keccak256(abi.encodePacked(block.difficulty)), 0);
        // Roll random dice for tiers 5 through 2
        for (uint8 tiernum = 5; tiernum > 1; tiernum-- ) {
            uint targetAmount = _tierInfo[tiernum].portion;
            for(uint count = 0; count < targetAmount; count++) {
//              for(int count = 0; count < 10; count++) { // FIXME hardcoded
                uint8 randIndex = getRandByte(randdata);
                // re-roll if out of range or we've already assigned a non-zero tier.
                // This uses some gas but saves on managing complex data structures, which would end up using more.
                if ( randIndex >= MAX_SUPPLY ) {
                    count--;
                } else if (_tokenTiers[randIndex] != 0 || _ownerOf[randIndex] == address(0)) {
                    count--;
                } else {
                    // assign the tokenId to the tier
                    _tokenTiers[randIndex] = tiernum;
                }
            }
        }
        // Assign any remaining tokenIds to tier 1, unless burned
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0) ) {
                _tokenTiers[tokenId] = 1;
            }
        }
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

}