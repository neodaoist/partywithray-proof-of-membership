// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @notice
contract TheLow is ERC721, Owned {
    //
    event SupplyUpdated(uint8 indexed newSupply);
    // event MetadataUpdated(string uri);
    // event MetadataFrozen();

    uint8 public constant MAX_SUPPLY = 222;
    uint8 public totalSupply = 222;

    string[] internal _tierURIs;
    mapping(uint8 => uint8) internal _tokenTiers;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address bigNightAddr) ERC721("partywithray - The Low", "LOW") Owned(bigNightAddr) {
        // Add metadata URIs for each tier
        _tierURIs = new string[](6);
        _tierURIs[0] = "ipfs://ABC"; // prereveal metadata URI
        _tierURIs[1] = "ipfs://bafkreig6yehifub66r6hc6vifvfvsbpcluztpsxtsnlyu6bwcinmnm7w7q";
        _tierURIs[2] = "ipfs://bafkreiecosxi6zjigs2z3gikj4liujzpt3ffjdpnferrsau6qgvs4o47xe";
        _tierURIs[3] = "ipfs://bafkreias7kqlefzhiipc37zqa3dilqdmgdca2uqcqpzev43a2bd5ohpyoi";
        _tierURIs[4] = "ipfs://DEF";
        _tierURIs[5] = "ipfs://GHI";

        // Mint NFTs
        mintBatch(bigNightAddr, 1, MAX_SUPPLY, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return _tierURIs[_tokenTiers[uint8(_tokenId)]];
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
