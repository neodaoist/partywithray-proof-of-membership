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
    string[] internal _tierURIs;
//    mapping(uint8 => uint8) internal _tokenTiers;

   Tier[6] internal _tierInfo;
   uint8[MAX_SUPPLY] internal _tokenTiers;

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


        // Add metadata URIs for each tier
        _tierURIs = new string[](6);
        _tierURIs[0] = "ABC"; // prereveal metadata URI
        _tierURIs[1] = "bafkreig6yehifub66r6hc6vifvfvsbpcluztpsxtsnlyu6bwcinmnm7w7q";
        _tierURIs[2] = "bafkreiecosxi6zjigs2z3gikj4liujzpt3ffjdpnferrsau6qgvs4o47xe";
        _tierURIs[3] = "bafkreias7kqlefzhiipc37zqa3dilqdmgdca2uqcqpzev43a2bd5ohpyoi";
        _tierURIs[4] = "DEF";
        _tierURIs[5] = "GHI";

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
                                _tierInfo[0].image_cid,
                                '", "attributes": { "Tier Name": "',
                                _tierInfo[0].name,
                                 '", "Tier Rarity" : "',
                                _tierInfo[0].rarity,
                                '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE METADATA
    //////////////////////////////////////////////////////////////*/

    function updateMetadata(uint8[] calldata _updatedTokenTiers) public onlyOwner {
        require(_updatedTokenTiers.length == totalSupply, "INVALID_TIERS");

        for (uint8 i = 1; i <= _updatedTokenTiers.length; i++) {
            _tokenTiers[i] = _updatedTokenTiers[i - 1];
        }
    }

    function mintBatch(address to, uint256 start, uint256 quantity, uint8 tierIndex) public {
        for(uint i = start; i < (start+quantity); i++) {
            _mint(to, i /*, tierIndex */);
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
}
