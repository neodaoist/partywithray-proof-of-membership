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
        //                 Name           Rarity        Image CID                  Animation CID                    Animation Hash
        _tierInfo[0] = Tier('Pre-reveal', 'Pre-reveal', 'TBD -- prereveal square', '', '', 0);
        _tierInfo[1] = Tier('The Lightest Low', 'Ultracommon', 'TBD -- lowestlow square', '', '', 111);
        _tierInfo[2] = Tier('The Basic Low', 'Common', 'TBD -- basiclow square', '', '', 75);
        _tierInfo[3] = Tier('The Medium Low', 'Uncommon', 'TBD -- mediumlow square', 'bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y', '', 22);
        _tierInfo[4] = Tier('The Low Low', 'Rare', 'TBD -- lowlow square', 'bafybeiagu3uu5ckzoe7nc2l4ljvh6wser3f5whtxhtayc4prneql6sclq4', '', 11);
        _tierInfo[5] = Tier('The Ultimate Low', 'Ultrarare', 'TBD -- ultimatelow square', 'bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a', '', 3);

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
                                '"}}'
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
        for (uint8 tier = 5; tier > 1; tier-- ) {
            uint targetAmount = _tierInfo[tier].portion;
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
                    _tokenTiers[randIndex] = tier;
                }
            }
        }
        // Assign any remaining tokenIds to tier 1
        for (uint8 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_tokenTiers[tokenId] == 0 && _ownerOf[tokenId] != address(0) ) {
                _tokenTiers[tokenId] = 1;
            }
        }
    }

    function tier(uint256 tokenId) public view returns (uint8) {
        return _tokenTiers[uint8(tokenId)];
    }

    function batchTransfer(address from, address to, uint256 startTokenId, uint256 endTokenId) public {
        for(uint256 i = startTokenId; i < endTokenId; i++) {
            transferFrom(from, to, i);
        }
    }

}