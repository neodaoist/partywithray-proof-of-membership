// SPDX-License-Identifier: MIIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {utils} from "../../src/utils.sol";

import {TheLow} from "../../src/TheLow.sol";

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
        tierURIs = [prereveal, tier1, tier2, tier3, tier4, tier5];
    }

    function test_Initial() public {
        assertEq(low.name(), "partywithray - The Low");
        assertEq(low.symbol(), "LOW");

        assertEq(low.owner(), team);
        assertEq(low.totalSupply(), 222);
    }

    /* ------------------------------------------------------------
                        UPDATE SUPPLY
    ------------------------------------------------------------ */

    function testUpdateSupply() public {
        vm.prank(team);
        low.updateSupply(137);

        assertEq(low.totalSupply(), 137);

        uint256 i;
        for (i = 1; i <= 137; i++) {
            assertEq(low.ownerOf(i), team);
        }
        for (i = 138; i <= 222; i++) {
            vm.expectRevert("NOT_MINTED");
            low.ownerOf(i);
        }
    }

    function testEventUpdateSupply() public {
        vm.expectEmit(true, true, true, true);
        emit SupplyUpdate(137);

        vm.prank(team);
        low.updateSupply(137);
    }

    function testUpdateSupplyDoesntBurnSold() public {
        console.log("Transferring");
        vm.prank(team);
        low.transferFrom(team, alice, 201);
        console.log("Burning");
        vm.prank(team);
        low.updateSupply(100);
        assertEq(low.totalSupply(), 100);
        assertEq(low.ownerOf(201), alice);
        console.log("Checking");
        vm.expectRevert("NOT_MINTED");
        low.ownerOf(100);
    }

    function testRevertUpdateSupplyWhenNotOwner() public {
        vm.expectRevert("UNAUTHORIZED");
        low.updateSupply(137);
    }

    function testRevertUpdateSupplyWhenInvalidSupply() public {
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

    event SupplyUpdate(uint8 indexed newSupply);

    /* -----------------------------------------------
                        REVEAL
    ----------------------------------------------- */

    function testReveal() public {
        vm.prank(team);
        low.reveal();
        for (uint256 i = 1; i <= 222; i++) {
            assert(low.tier(i) != 0);
        }
    }

    function testRevealIsOnlyOwner() public {
        vm.prank(bob);
        vm.expectRevert("UNAUTHORIZED");
        low.reveal();
    }

    // FIXME or REMOVEME
    function testRevealSkipsBurned() public {}

    function testDivideRoundUp() public {
        assertEq(10, utils.divideRoundUp(99, 10, 1));
        assertEq(10, utils.divideRoundUp(100, 10, 1));
        assertEq(11, utils.divideRoundUp(101, 10, 1));
        assertEq(0, utils.divideRoundUp(0, 20, 1));
        assertEq(26, utils.divideRoundUp(251, 10, 1));

        assertEq(3, utils.divideRoundUp(222, 7400, 100));
        assertEq(11, utils.divideRoundUp(222, 2019, 100)); // 222/20.19 = 11
        assertEq(22, utils.divideRoundUp(222, 1010, 100)); // 222/10.1 = 22
        assertEq(75, utils.divideRoundUp(222, 296, 100)); // 222/2.96 = 75
        assertEq(111, utils.divideRoundUp(222, 200, 100));

        vm.expectRevert();
        utils.divideRoundUp(100, 0, 1);
    }

    function testRoyalty() public {
        vm.startPrank(team);
        low.transferFrom(team, alice, 2);

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
