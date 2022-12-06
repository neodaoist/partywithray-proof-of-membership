// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/TheLow.sol";

contract TheLowTest is Test {
    //
    
    TheLow internal low;

    address internal constant alice = address(0xAAAA);
    address internal constant bob = address(0xBBBB);

    string internal constant tier1 = "ipfs://bafkreig6yehifub66r6hc6vifvfvsbpcluztpsxtsnlyu6bwcinmnm7w7q";
    string internal constant tier2 = "ipfs://bafkreiecosxi6zjigs2z3gikj4liujzpt3ffjdpnferrsau6qgvs4o47xe";
    string internal constant tier3 = "ipfs://bafkreias7kqlefzhiipc37zqa3dilqdmgdca2uqcqpzev43a2bd5ohpyoi";
    // string internal constant tier4 = "";
    // string internal constant tier5 = "";

    function setUp() public {
        low = new TheLow();
    }

    function testInitial() public {
        assertEq(low.name(), "partywithray - The Low");
        assertEq(low.symbol(), "LOW");
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

    function testTokenUri() public {
        low.mint(alice, 1, 0);
        low.mint(bob, 2, 1);
        low.mint(alice, 3, 2);

        assertEq(low.tokenURI(1), tier1);
        assertEq(low.tokenURI(2), tier2);
        assertEq(low.tokenURI(3), tier3);
    }

    /*//////////////////////////////////////////////////////////////
                        MINT
    //////////////////////////////////////////////////////////////*/

    function testMint() public {
        low.mint(alice, 1, 0);
        low.mint(bob, 2, 1);
        low.mint(alice, 3, 2);

        assertEq(low.balanceOf(alice), 2);
        assertEq(low.balanceOf(bob), 1);
        assertEq(low.ownerOf(1), alice);
        assertEq(low.ownerOf(2), bob);
        assertEq(low.ownerOf(1), alice);
    }

    /*//////////////////////////////////////////////////////////////
                        BURN
    //////////////////////////////////////////////////////////////*/

    function testBurn() public {
        low.mint(alice, 1, 0);
        low.mint(bob, 2, 1);
        low.mint(alice, 3, 2);

        low.burn(3);

        assertEq(low.balanceOf(alice), 1);
        assertEq(low.ownerOf(1), alice); // still alice

        vm.expectRevert("NOT_MINTED");
        low.ownerOf(3); // burned
    }
}
