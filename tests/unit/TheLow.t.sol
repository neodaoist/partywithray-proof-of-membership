// SPDX-License-Identifier: MIIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../src/TheLow.sol";

contract TheLowTest is Test {
    //
    
    TheLow internal low;

    address internal constant alice = address(0xAAAA);
    address internal constant bob = address(0xBBBB);
    address internal constant team = address(0xCAFE);

    string[] internal tierURIs;
    string internal constant prereveal = "ipfs://ABC";
    string internal constant tier1 = "ipfs://bafkreig6yehifub66r6hc6vifvfvsbpcluztpsxtsnlyu6bwcinmnm7w7q";
    string internal constant tier2 = "ipfs://bafkreiecosxi6zjigs2z3gikj4liujzpt3ffjdpnferrsau6qgvs4o47xe";
    string internal constant tier3 = "ipfs://bafkreias7kqlefzhiipc37zqa3dilqdmgdca2uqcqpzev43a2bd5ohpyoi";
    string internal constant tier4 = "ipfs://DEF";
    string internal constant tier5 = "ipfs://GHI";

    function setUp() public {
        low = new TheLow(team);
        tierURIs = [
            prereveal,
            tier1,
            tier2,
            tier3,
            tier4,
            tier5
        ];
    }

    function test_Initial() public {
        assertEq(low.name(), "partywithray - The Low");
        assertEq(low.symbol(), "LOW");

        assertEq(low.owner(), team);
        assertEq(low.totalSupply(), 222);

        // Moved to Cucumber
        //for (uint8 i = 1; i <= low.MAX_SUPPLY(); i++) {
        //    assertEq(low.tokenURI(i), prereveal);
        //}
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE METADATA
    //////////////////////////////////////////////////////////////*/

// FIXME: Revisit this
/*
    function test_UpdateMetadata() public {
        vm.prank(team);
        low.updateMetadata(updatedTokenTiers);

        for (uint256 i = 1; i <= low.totalSupply(); i++) {
            assertEq(low.tokenURI(i), tierURIs[updatedTokenTiers[i - 1]]);
        }
    }
*/

    /*//////////////////////////////////////////////////////////////
                        UPDATE SUPPLY
    //////////////////////////////////////////////////////////////*/

    function test_UpdateSupply() public {
        vm.prank(team);
        low.updateSupply(137);

        assertEq(low.totalSupply(), 137);

        uint i;
        for (i = 1; i <= 137; i++) {
            assertEq(low.ownerOf(i), team);
        }
        for (i = 138; i <= 222; i++) {
            vm.expectRevert("NOT_MINTED");
            low.ownerOf(i);
        }
    }

    function testEvent_UpdateSupply() public {
        vm.expectEmit(true, true, true, true);
        emit SupplyUpdated(137);
        
        vm.prank(team);
        low.updateSupply(137);
    }

    function testRevert_UpdateSupply_WhenNotOwner() public {
        vm.expectRevert("UNAUTHORIZED");

        low.updateSupply(137);
    }

    function testRevert_UpdateSupply_WhenInvalidSupply() public {
        // Equal to current
        vm.prank(team);
        vm.expectRevert("INVALID_SUPPLY");

        low.updateSupply(222);

        // Greater than current
        vm.prank(team);
        vm.expectRevert("INVALID_SUPPLY");

        low.updateSupply(223);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN URI
    //////////////////////////////////////////////////////////////*/

    // function testTokenUri() public {
    //     low.mint(alice, 1, 0);
    //     low.mint(bob, 2, 1);
    //     low.mint(alice, 3, 2);

    //     assertEq(low.tokenURI(1), tier1);
    //     assertEq(low.tokenURI(2), tier2);
    //     assertEq(low.tokenURI(3), tier3);
    // }

    /*//////////////////////////////////////////////////////////////
                        MINT
    //////////////////////////////////////////////////////////////*/

    // function testMint() public {
    //     low.mint(alice, 1, 0);
    //     low.mint(bob, 2, 1);
    //     low.mint(alice, 3, 2);

    //     assertEq(low.balanceOf(alice), 2);
    //     assertEq(low.balanceOf(bob), 1);
    //     assertEq(low.ownerOf(1), alice);
    //     assertEq(low.ownerOf(2), bob);
    //     assertEq(low.ownerOf(1), alice);
    // }

    function testMintBatch() public {
        // Minting happens in the constructor
        assertEq(low.totalSupply(), 222);
    }

    /*//////////////////////////////////////////////////////////////
                        BURN
    //////////////////////////////////////////////////////////////*/

    // function testBurn() public {
    //     low.mint(alice, 1, 0);
    //     low.mint(bob, 2, 1);
    //     low.mint(alice, 3, 2);

    //     low.burn(3);

    //     assertEq(low.balanceOf(alice), 1);
    //     assertEq(low.ownerOf(1), alice); // still alice

    //     vm.expectRevert("NOT_MINTED");
    //     low.ownerOf(3); // burned
    // }

    event SupplyUpdated(uint8 indexed newSupply);

    /*//////////////////////////////////////////////////////////////
                        REVEAL
    //////////////////////////////////////////////////////////////*/

    function testReveal() public {
        vm.prank(team);
        low.reveal();
        for(uint256 i = 1; i <= 222; i++) {
            assert(low.tier(i) != 0);
        }
    }

    function testRevealIsOnlyOwner() public {
         vm.prank(bob);
         vm.expectRevert("UNAUTHORIZED");
         low.reveal();
    }

    function testRevealSkipsBurned() public {

    }
}
