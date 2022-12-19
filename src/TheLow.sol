// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

import "./utils.sol";

/// @title partywithray - The Low NFT Collection
/// @author plaird523
/// @author neodaoist
/// @dev The full supply of this contract (222 items) is minted in the constructor.
contract TheLow is ERC721, Owned {
    //

    /* -----------------------------------------------------------
                        EVENTS
    ----------------------------------------------------------- */

    /// @notice Emitted when supply is updated
    event SupplyUpdate(uint8 indexed newSupply);

    /// @notice Emitted when metadata is updated
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /* -----------------------------------------------------------
                        DATA STRUCTURES
    ----------------------------------------------------------- */

    /// @notice Data structure for a rarity/artwork tier
    struct Tier {
        string name;
        string rarity;
        string image_cid;
        string animation_cid;
        string animation_hash;
        uint16 portion; // Used to compute the portion of items that fall into this tier: (ceil(supply / portion/100))
    }

    /// @notice Data structure for pseudorandom rarity/artwork reveal
    struct RandBytes {
        bytes32 data;
        uint8 index;
    }

    /* -----------------------------------------------------------
                        CONSTANT VARIABLES - PUBLIC
    ----------------------------------------------------------- */
    
    /// @notice Maximum possible supply
    uint8 public constant MAX_SUPPLY = 222;

    /* -----------------------------------------------------------
                        STATE VARIABLES - PUBLIC
    ----------------------------------------------------------- */
    
    /// @notice Actual supply
    uint8 public totalSupply = 222;

    /* -----------------------------------------------------------
                        STATE VARIABLES - INTERNAL
    ----------------------------------------------------------- */

    /// @notice All 6 rarity/artwork tiers
    Tier[6] internal _tierInfo;

    /// @notice Rarity/artwork tier for each token ID (tokenIds are 1-indexed)
    uint8[MAX_SUPPLY + 1] internal _tokenTiers;

    /* -----------------------------------------------------------
                        CONSTRUCTOR
    ----------------------------------------------------------- */

    constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
        // Create the tier info table
        //                   Name                Rarity         Image CID                                                      Animation CID                                                  Animation Hash                                                     Post-reveal portion (ceil(222 / N*100))
        _tierInfo[0] = Tier('Pre-reveal',       'Pre-reveal',  'bafybeiehzuula2ao3fsfpvvjtr6mxhp7fdsh3rwqpgpamazjpbd7h7pu2m', 'bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm', 'd02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac', 0);
        _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', 'afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52', 200);
        _tierInfo[2] = Tier('The Basic Low',    'Common',      'bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa', 'bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4', 'af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460', 296);
        _tierInfo[3] = Tier('The Medium Low',   'Uncommon',    'bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey', 'bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq', '05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4', 1010);
        _tierInfo[4] = Tier('The Low Low',      'Rare',        'bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb', 2019);
        _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare',   'bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm', 'bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u', '8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879', 7400);

        // Mint NFTs
        mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
    }

    /* -----------------------------------------------------------
                        TOKEN INFO
    ----------------------------------------------------------- */

    /// @notice Get the dynamic metadata. This will change one time, when reveal is called, following the initial sale.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory description =
            "A Proof of Membership NFT for partywithray fans, granting future access to shows, new music, and merch. \u1FAA9 \u26A1 In collaboration with Hyperforge, a smart contract development and security research firm, and Kairos Music, a music NFT information platform that seeks to make a living salary for artists in the music industry achievable.";

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                utils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "The Low ',
                                utils.toString(tokenId),
                                "/222",
                                '", "description": "',
                                description,
                                '", "image": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].image_cid,
                                '", "animation_url": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].animation_cid,
                                '", "attributes": { "Tier Name": "',
                                _tierInfo[_tokenTiers[tokenId]].name,
                                '", "Tier Rarity" : "',
                                _tierInfo[_tokenTiers[tokenId]].rarity,
                                '"}, "content": {"mimeType": "video/mp4", "hash": "',
                                _tierInfo[_tokenTiers[tokenId]].animation_hash,
                                '", "uri": "ipfs://',
                                _tierInfo[_tokenTiers[tokenId]].animation_cid,
                                '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /// @notice Returns the numeric tier for a given tokenId
    /// @param tokenId The tokenId to check
    /// @return The tier of a given tokenId
    function tier(uint256 tokenId) external view returns (uint8) {
        return _tokenTiers[uint8(tokenId)];
    }

    /* -----------------------------------------------------------
                        BATCH MINT
    ----------------------------------------------------------- */

    /// @notice Mints a batch of tokens, with contiguous tokenIds
    /// @param to The address to mint to
    /// @param start The starting tokenId
    /// @param end The ending tokenId
    /// @param tierIndex The initial Pre-reveal tier for each minted token
    function mintBatch(address to, uint256 start, uint256 end, uint8 tierIndex) private {
        for (uint256 i = start; i <= end; i++) {
            _mint(to, i);
            _tokenTiers[i] = tierIndex;
        }
    }

    /* -----------------------------------------------------------
                        UPDATE SUPPLY
    ----------------------------------------------------------- */

    /// @notice Reduces the supply of this token by burning unsold tokenIds (those not owned by the contract owner)
    /// @param _newSupply The new supply amount
    function updateSupply(uint8 _newSupply) public onlyOwner {
        require(_newSupply < totalSupply, "INVALID_SUPPLY");
        require(_tokenTiers[1] == 0, "ALREADY_REVEALED");

        uint256 currentSupply = totalSupply;

        // Burn the highest tokenIds first for aesthetics
        for (uint8 index = MAX_SUPPLY; index > 0 && currentSupply > _newSupply; index--) {
            if (_ownerOf[index] == msg.sender) {
                // Only burn the tokens we own
                //FIXME console.log("Burning: ", index, ", Owned by: ", _ownerOf[index]);
                _burn(index);
                currentSupply--;
            }
        }
        totalSupply = _newSupply;

        emit SupplyUpdate(_newSupply);
    }

    /* --------------------------------------------------------------
                        RANDOM REVEAL
    -------------------------------------------------------------- */

    /// @notice Randomly reveals the tiers for each unburned, unrevealed tokenId in this 
    /// contract. Will not change the tier of any tokenId that's previously been revealed.
    /// @dev Uses blocks.prevrandao as random source. Small MEV risk but simple. Could use Chainlink VRF here too.
    function reveal() public onlyOwner {
        // Initialize PRNG -- using blocks
        RandBytes memory randdata = RandBytes(keccak256(abi.encodePacked(block.difficulty)), 0);

        // Build an array of all the un-burned tokenIds
        uint8[] memory lottery = new uint8[](totalSupply);
        uint8 index = 0;
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_ownerOf[tokenId] != address(0)) {
                lottery[index] = tokenId; // Can't use .push on memory arrays so we maintain our own index
                index++;
            }
        }
        assert(index == totalSupply); // FIXME: Remove before mainnet deploy
        index--; // Index will be totalSupply, or one past the end of lottery's used range

        // Roll random dice for tiers 5 through 2
        for (uint8 tiernum = 5; tiernum > 1; tiernum--) {
            uint256 targetAmount = utils.divideRoundUp(totalSupply, _tierInfo[tiernum].portion, 100); // FIXME: Proportional amounts if we don't sell out
            while (targetAmount > 0) {
                uint8 randIndex = getRandByte(randdata);
                if (index < 128) {
                    randIndex = randIndex & 0x7F; // Optimization: use 7 bits of entropy if we're below 128 items to reduce re-rolls
                }

                if (randIndex <= index) {
                    // Assign the tokenId rolled to the tier
                    _tokenTiers[lottery[randIndex]] = tiernum;
                    // Remove the item from the lottery by replacing it with the item at the end of the array to avoid shifting
                    lottery[randIndex] = lottery[index];
                    // Update the loop counters
                    index--;
                    targetAmount--;
                }
            }
        }

        // Assign any remaining tokenIds to tier 1, unless burned
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0)) {
                _tokenTiers[tokenId] = 1;
            }
        }
        
        emit BatchMetadataUpdate(1, 222);
    }

    /// @notice Returns one byte of pseudorandom data from a pre-seeded structure
    /// @dev Re-hashes to get more randomness from the same seed as needed
    /// @param randdata pre-seeded pseudorandom data struct
    /// @return One byte of pseudorandom data
    function getRandByte(RandBytes memory randdata) private pure returns (uint8) {
        if (randdata.index >= 8) {
            randdata.data = keccak256(abi.encodePacked(randdata.data));
            randdata.index = 0;
        }
        bytes1 value = randdata.data[randdata.index];
        randdata.index++;

        return uint8(value);
    }

    /* -----------------------------------------------------------
                        BATCH TRANSFER
    ----------------------------------------------------------- */

    /// @notice Transfers a contiguous range of tokenIds to a given address -- useful
    /// @notice for efficiently transferring a block to a vault
    /// @param from pre-seeded pseudorandom data struct
    /// @param to pre-seeded pseudorandom data struct
    /// @param startTokenId pre-seeded pseudorandom data struct
    /// @param endTokenId pre-seeded pseudorandom data struct
    function batchTransfer(address from, address to, uint256 startTokenId, uint256 endTokenId) external {
        for (uint256 i = startTokenId; i < endTokenId; i++) {
            transferFrom(from, to, i);
        }
    }

    /* -----------------------------------------------------------
                        EIP-165
    ----------------------------------------------------------- */

    /// @dev See ERC165
    function supportsInterface(bytes4 interfaceId) public pure override (ERC721) returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 -- supportsInterface
            || interfaceId == 0x80ac58cd // ERC721 -- Non-Fungible Tokens
            || interfaceId == 0x5b5e139f // ERC721Metadata
            || interfaceId == 0x2a55205a; // ERC2981 -- royaltyInfo
    }

    /* -----------------------------------------------------------
                        EIP-2981
    ----------------------------------------------------------- */

    /// @notice Returns royalty info for a given token and sale price
    /// @dev Not using SafeMath here as the denominator is fixed and can never be zero,
    /// @dev but consider doing so if changing royalty percentage to a variable.
    /// @return receiver Receiver is always the contract owner's address
    /// @return royaltyAmount Royalty amount is a fixed 10% royalty based on the sale price
    function royaltyInfo(uint256, /* tokenId */ uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner, salePrice * 750 / 10_000);  // 750 basis points or 7.5%
    }
}
