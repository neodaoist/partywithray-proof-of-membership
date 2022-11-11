// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract TheLow is ERC721 {
    //

    string[] internal _tierURIs;
    mapping(uint256 => string) _tokenURIs;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("partywithray - The Low", "LOW") {
        _tierURIs = new string[](5);
        _tierURIs[0] = "ipfs://bafkreig6yehifub66r6hc6vifvfvsbpcluztpsxtsnlyu6bwcinmnm7w7q";
        _tierURIs[1] = "ipfs://bafkreiecosxi6zjigs2z3gikj4liujzpt3ffjdpnferrsau6qgvs4o47xe";
        _tierURIs[2] = "ipfs://bafkreias7kqlefzhiipc37zqa3dilqdmgdca2uqcqpzev43a2bd5ohpyoi";
        // _tierURIs[4] = "";
        // _tierURIs[5] = "";
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                        MINT
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 tokenId, uint8 tierIndex) public {
        _tokenURIs[tokenId] = _tierURIs[tierIndex];
        _mint(to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        BURN
    //////////////////////////////////////////////////////////////*/

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
