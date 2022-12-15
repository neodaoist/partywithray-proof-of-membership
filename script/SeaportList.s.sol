pragma solidity ^0.8.13;
import "forge-std/Script.sol";

import {TheLow} from "../src/TheLow.sol";
import {SeaportInterface} from "lib/seaport/contracts/interfaces/SeaportInterface.sol";
import {
OrderParameters,
OrderComponents,
OfferItem,
ConsiderationItem,
//Fulfillment,
//FulfillmentComponent,
//Execution,
Order
//AdvancedOrder,
//OrderStatus,
//CriteriaResolver
} from "lib/seaport/contracts/lib/ConsiderationStructs.sol";

import {
OrderType,
ItemType
} from "lib/seaport/contracts/lib/ConsiderationEnums.sol";

contract ListEssayScript is Script {
    //


    function run() public {
        // Config
        bytes32 OPENSEA_CONDUIT_KEY = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        address payable OPENSEA_MARKETPLACE = payable(0x0000a26b00c1F0DF003000390027140000fAa719);
        address SEAPORT_CONTRACT = 0x00000000006c3852cbEf3e08E8dF289169EdE581; // All networks

        address payable TEAM = payable(0xf068e6F80fA1d55A27be3408cbdad3fCDa704514); // Testnet Deployer
        address TOKEN_ADDR = 0x69b79E3d630198577B3e2b18d88E8223325E6ABA;  // Testnet, pre-reveal

        // Create OfferItem (the NFT for listing)
        OfferItem memory item = OfferItem(
            ItemType.ERC721,
            TOKEN_ADDR,
            1,  // Token ID
            1,  // Start Amount
            1   // End Amount
        );

        // Create ConsiderationItem (0.111 ETH + 2.5% fee to OpenSea
        ConsiderationItem memory payment = ConsiderationItem(
            ItemType.NATIVE,  // Eth on Mainnet
            address(0),  // token -- Ignored for Eth
            0x00,  // identifier -- Ignored for Eth
            0.0111 ether,  // start amount
            0.0111 ether,   // end amount
            TEAM   // payable
        );


        ConsiderationItem memory fee = ConsiderationItem(
            ItemType.NATIVE,  // Eth on Mainnet
            address(0),  // token -- Ignored for Eth
            0x00,  // identifier -- Ignored for Eth
            0.002775 ether,  // start amount
            0.002775 ether,   // end amount
            OPENSEA_MARKETPLACE   // payable
        );

        ConsiderationItem[] memory considerationItems = new ConsiderationItem[](2);
        considerationItems[0] = payment;
        considerationItems[1] = fee;

        OfferItem[] memory offerItems = new OfferItem[](1);
        offerItems[0] = item;

        // Create OrderParameters
        OrderParameters memory parameters = OrderParameters(
            TEAM,  // offerer
            address(0),  // zone
            offerItems,  // offer
            considerationItems,  // consideration
            OrderType.FULL_OPEN,
            block.timestamp,       // start time -- current time
            block.timestamp + 86400 * 14,       // two weeks
            bytes32(0),  // zone hash
            0x22212345678, // salt
            OPENSEA_CONDUIT_KEY,
            1      // total original consideration items
        );

        // Create Order
        bytes memory signature = abi.encodePacked(uint(0));
        Order memory order = Order(parameters, signature);

        Order[] memory orders = new Order[](1);
        orders[0] = order;

        // load the seaport contract
        SeaportInterface seaport = SeaportInterface(SEAPORT_CONTRACT);
        seaport.validate(orders);

    }
}

