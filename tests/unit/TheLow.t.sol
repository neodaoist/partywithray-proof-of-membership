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



    /* ------------------------------------------------------------
                        UPDATE SUPPLY
    ------------------------------------------------------------ */

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

    function test_UpdateSupplyDoesntBurnSold() public {
        console.log("Transferring");
        vm.prank(team);
        low.transferFrom(team,alice,201);
        console.log("Burning");
        vm.prank(team);
        low.updateSupply(100);
        assertEq(low.totalSupply(), 100);
        assertEq(low.ownerOf(201),alice);
        console.log("Checking");
        vm.expectRevert("NOT_MINTED");
        low.ownerOf(100);
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


    function testMintBatch() public {
        // Minting happens in the constructor
        assertEq(low.totalSupply(), 222);
    }

    /* -------------------------------------------------------------
                        BURN
    ------------------------------------------------------------- */

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

    /* -----------------------------------------------
                        REVEAL
    ----------------------------------------------- */

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

    function testDivideRoundUp() public {
        assertEq(10,low.divideRoundUp(99,10,1));
        assertEq(10,low.divideRoundUp(100,10,1));
        assertEq(11,low.divideRoundUp(101,10,1));
        assertEq(0,low.divideRoundUp(0,20,1));
        assertEq(26,low.divideRoundUp(251,10,1));

        assertEq(3,low.divideRoundUp(222,7400,100));
        assertEq(11,low.divideRoundUp(222,2019,100));   // 222/20.19 = 11
        assertEq(22,low.divideRoundUp(222,1010,100));     // 222/10.1 = 22
        assertEq(75,low.divideRoundUp(222,296,100));    // 222/2.96 = 75
        assertEq(111,low.divideRoundUp(222,200,100));

        vm.expectRevert();
        low.divideRoundUp(100,0,1);
    }

        function testRoyalty() public {
            vm.startPrank(team);
            low.transferFrom(team,alice,2);

            (address recipient, uint256 amount) = low.royaltyInfo(1, 100_000);
            assertEq(team, recipient);
            assertEq(amount, 10_000); // 10%
            (recipient, amount) = low.royaltyInfo(2, 7_777);
            assertEq(team, recipient);
            assertEq(amount, 777); // 10%
            (recipient, amount) = low.royaltyInfo(3, 0);
            assertEq(team, recipient);
            assertEq(amount, 0); // 10%

    }
}

