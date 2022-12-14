mod solidity_bdd;
use std::{env};
use std::collections::HashMap;
use std::str::FromStr;
use async_std::task;
use crate::solidity_bdd::{SCWorld, TestConfig};
use cucumber::{gherkin::Step, given, when, then};
use ethers::prelude::*; // {k256, U256};
use ethers_contract::{abigen};
use serde_json;
use base64;
use serde_json::{Value};

const FORK_CHAIN_ID: u64 = 31337_u64;

// Generate bindings for contracts
abigen!(TheLow, "out/TheLow.sol/TheLow.json");


// Test configuration and runner

#[tokio::main]
async fn main()
{
    // Generate bindings for the 3rd party contracts we'll need
    // TODO: Add VRF here if we end up using it

    // Read fork endpoint from environment variable ETH_NODE_URL
    let fork_endpoint = env::var("ETH_NODE_URL").expect("Environment variable ETH_NODE_URL should be defined and be a valid API URL");

    let mut config: solidity_bdd::TestConfig = solidity_bdd::new();
        config.fork(fork_endpoint, FORK_CHAIN_ID)
        //.thirdPartyContracts([])  // TODO: Add VRF here if we end up using it
        ;
    solidity_bdd::run(config).await
}

// Stepdefs
#[given(r#"the Partywithray Proof of Membership NFT contract is deployed"#)]
fn deploy_party_with_ray(world: &mut SCWorld) {
    let thelow_contract = task::block_on(solidity_bdd::the_low::TheLow::deploy(world.client(), world.deployer_address().clone()).expect("Failed to deploy").send()).expect("Failed to send");
    world.thelow_contract = Some(thelow_contract);
}

#[then(regex = r#"the name should be "(.*)" and the symbol should "(.*)""#)]
async fn verify_name_and_symbol(world: &mut SCWorld, expected_name: String, expected_symbol: String) {
    // TODO: I wish the following worked but I need the_low::TheLow to be an ethers_contract::Contract
    //let actual_name: String = world.contract_query(world.thelow_contract.unwrap().into(), "name", ());
    //let actual_symbol: String = world.contract_query(world.thelow_contract.unwrap().into(), "symbol", ());

    // Look up the contract name
    let actual_name = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, String>("name", ())
        .expect("Error finding name method").call().await.expect("Error sending name call");

    // Look up the contract symbol
    let actual_symbol = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, String>("symbol", ())
        .expect("Error finding symbol method").call().await.expect("Error sending symbol call");

    assert_eq!(expected_name, actual_name);
    assert_eq!(expected_symbol, actual_symbol);
}

#[then(regex = r#"^the supply should be ([\d]+)$"#)]
async fn verify_supply(world: &mut SCWorld, expected_supply_str: String) {
    let expected_supply = U256::from_dec_str(expected_supply_str.as_str()).expect("Expected supply value should be a number");

    let actual_supply = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, U256>("totalSupply", ())
        .expect("Error finding totalSupply method").call().await.expect("Error sending totalSupply call");

    assert_eq!(expected_supply, actual_supply);
}

#[then(regex = r#"^all ([\d]+) NFTs should have the pre-reveal art$"#)]
async fn verify_pre_reveal_art(world: &mut SCWorld, nft_count_str: String) {
    // ImageURI return a JSON blob -- parse out the image in all 222 NFTs
    let nft_count: i32 = nft_count_str.parse().expect("Number of NFTs should be a number");
    for i in 1..=nft_count {
        let jsondata = lookup_metadata(world, i).await;
        assert_eq!(&jsondata["image"],"ipfs://bafybeiehzuula2ao3fsfpvvjtr6mxhp7fdsh3rwqpgpamazjpbd7h7pu2m");
        assert_eq!(&jsondata["animation_url"],"ipfs://bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm");
        assert_eq!(&jsondata["content"]["uri"],"ipfs://bafybeig5tsvqpky2o5yz3tqjekghpuax6g6liptprebi7w4ghsrq47jppm");
        assert_eq!(&jsondata["content"]["hash"],"d02d2df27cd5a92eef66a7c8760ab28c06467532b09f870cff38bc32dd5984ac");
    }
}

#[then(regex = r#"each NFT title should be "(.*)""#)]
async fn verify_title(world: &mut SCWorld, title: String) {
    // ImageURI return a JSON blob -- parse out the image in all 222 NFTs
    for i in 1..=222 {
        let jsondata = lookup_metadata(world, i).await;
        let expected_title = title.replace("{id}", i.to_string().as_str());

        assert_eq!(&jsondata["name"], expected_title.as_str());
    }
}

#[then(regex = r#"each NFT description should be "(.*)""#)]
async fn verify_description(world: &mut SCWorld, description: String) {
    for i in 1..=222 {
        let jsondata = lookup_metadata(world, i).await;

        assert_eq!(&jsondata["description"], description.as_str());
    }
}

async fn lookup_metadata(world: &mut SCWorld, i: i32) -> Value {
    // Look up the JSON metadata
    let metadata: String = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, String>("tokenURI", U256::from(i))
        .expect("Error finding tokenURI method").call().await.expect("Error sending tokenURI call");

    // Decode base64
    let b64string: String = metadata.strip_prefix("data:application/json;base64,").expect("String should have base64 prefix").to_string();
    let json_bytes = base64::decode(b64string).expect("Base64 string should be valid");
    //println!("Got JSON: {}", String::from_utf8(jsonbytes).expect("String should be UTF-8"));
    // Parse JSON and inspect
    let json_data: Value = serde_json::from_slice(&*json_bytes).expect("JSON should be valid");
    json_data
}

#[given(regex = r#"([\d]+) NFTs were held for promo and all remaining ([\d]+) NFTs were sold"#)]
async fn simulate_sale(world: &mut SCWorld, reserved_count: i32, sold_count: i32) {
    let new_owner = Address::random();
    let owner: Address = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, Address>("ownerOf", U256::from(reserved_count))
        .expect("Error finding owner_of method").call().await.expect("Error sending owner_of call");
    //println!("TokenID {} is owned by {}", reserved_count, owner);

    let transfer_call = world.thelow_contract.as_ref().expect("Contract must be initialized").batch_transfer(owner,new_owner, U256::from(reserved_count), U256::from(reserved_count + sold_count));
    transfer_call.send().await.expect("Failed to send transfer transaction");
}

#[when(r#"we reveal the art"#)]
async fn reveal_art(world: &mut SCWorld) {
    let reveal_call = world.thelow_contract.as_ref().expect("Contract must be initialized").reveal();
    reveal_call.send().await.expect("Reveal call failed");
}

#[then(regex = r#"^there should be ([\d]+) tokens with the following metadata and quantities:$"#)]
async fn check_reveal(world: &mut SCWorld, step: &Step, expected_total: i32) {

    // Parse data table into tier info structure
    struct TierInfo<'a> {
        number: usize,
        name: & 'a String,
        rarity: & 'a String,
        image_uri: & 'a String,
        animation_uri: & 'a String,
        animation_hash: & 'a String,
        expected_quantity: i32,
    }
    let mut tiers: HashMap<usize, TierInfo> = HashMap::new();

    if let Some(table) = step.table.as_ref() {
        for row in table.rows.iter().skip(1) { // skip header
            let tier_info = TierInfo {
                number: usize::from_str(&row[6]).expect("Tier number should be a number"),
                name: &row[0],
                rarity: &row[1],
                image_uri: &row[2],
                animation_uri: &row[3],
                animation_hash: &row[4],
                expected_quantity: i32::from_str(&row[5]).expect("Tier number should be a number"),
            };
            tiers.insert(tier_info.number, tier_info);
        }
    } else {
        panic!("Step missing data table");
    }

    // Check that tokenId 0 is owned by 0 and in tier 0
    let tier: u8 = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, u8>("tier", U256::from(0))
        .expect("Error finding tier method").call().await.expect("Error sending tier call");
    assert_eq!(tier, 0, "Tier should be 0 for TokenId 0");

    // Loop through all NFTs.  Check that the metadata matches the tier number.
    // Keep a count of how many we have in each tier
    let mut token_count_by_tier: [i32; 6] = [0; 6];
    let mut total_count: i32 = 0;
    for i in 1..=222 {
        let tier: u8 = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
            .method::<_, u8>("tier", U256::from(i))
            .expect("Error finding tier method").call().await.expect("Error sending tier call");
        let jsondata = lookup_metadata(world, i).await;

        let tiernum: usize = tier.into();
        //println!("TokenID {} is in tier {}", i, tiernum);
        assert!(tiers.get(&tiernum).is_some());
        assert_eq!(tiers.get(&tiernum).unwrap().name,&jsondata["attributes"]["Tier Name"]);
        assert_eq!(tiers.get(&tiernum).unwrap().rarity,&jsondata["attributes"]["Tier Rarity"]);
        assert_eq!(tiers.get(&tiernum).unwrap().image_uri,&jsondata["image"]);
        assert_eq!(tiers.get(&tiernum).unwrap().animation_uri,&jsondata["animation_url"]);
        assert_eq!("video/mp4",&jsondata["content"]["mimeType"]);
        assert_eq!(tiers.get(&tiernum).unwrap().animation_hash,&jsondata["content"]["hash"]);
        assert_eq!(tiers.get(&tiernum).unwrap().animation_uri,&jsondata["content"]["uri"]);

        token_count_by_tier[tiernum] += 1;
        total_count += 1;
    }

    // Verify we have the expected count in each tier
    for i in 0..6 {
        println!("Tier {}: count: {}", i, token_count_by_tier[i]);
        if i > 0 {
            assert_eq!(token_count_by_tier[i], tiers.get(&i).expect("Tier data not found").expected_quantity);
        }
    }
    assert_eq!(total_count, expected_total);
}

#[then(r#"calling reveal a second time should not change any tiers"#)]
async fn no_rereveal(world: &mut SCWorld) {
    // Capture the arrangement of existing tiers
    let mut tiers: [u8; 223] = [0; 223];
    for i in 0..=222 {
        let tier: u8 = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
            .method::<_, u8>("tier", U256::from(i))
            .expect("Error finding tier method").call().await.expect("Error sending tier call");
        tiers[i] = tier;
    }

    // Call reveal
    let reveal_call = world.thelow_contract.as_ref().expect("Contract must be initialized").reveal();
    reveal_call.send().await.expect("Reveal call failed");

    // Check that tiers have not changed
    for i in 0..=222 {
        let tier: u8 = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
            .method::<_, u8>("tier", U256::from(i))
            .expect("Error finding tier method").call().await.expect("Error sending tier call");
        assert_eq!(tiers[i],tier);
    }
}

#[when(regex = r#"^we reduce the supply to ([\d]+)$"#)]
async fn reduce_supply(world: &mut SCWorld, supply: u8) {
    // Call reduce supply
    let reduce_supply_call = world.thelow_contract.as_ref().expect("Contract must be initialized").update_supply(supply);
    reduce_supply_call.send().await.expect("Reveal call failed");
}

#[then(regex = r#"^the distribution should be ([\d]+) ultrarares, ([\d]+) rares, ([\d]+) uncommons, ([\d]+) commons, and ([\d]+) ultracommons$"#)]
async fn check_distribution(world: &mut SCWorld, ultrarares: i32, rares: i32, uncommons: i32, commons: i32, ultracommons: i32) {
    let mut token_count_by_tier: [i32; 6] = [0; 6];

    for i in 1..=222 {
        let tier: u8 = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
            .method::<_, u8>("tier", U256::from(i))
            .expect("Error finding tier method").call().await.expect("Error sending tier call");
        let tiernum: usize = tier.into();
        token_count_by_tier[tiernum] += 1;
    }

    assert_eq!(token_count_by_tier[5], ultrarares);
    assert_eq!(token_count_by_tier[4], rares);
    assert_eq!(token_count_by_tier[3], uncommons);
    assert_eq!(token_count_by_tier[2], commons);
    assert_eq!(token_count_by_tier[1], ultracommons);
}
//royalties should be set at 7.5% going to the "Big Night" address
#[then(regex = r#"^royalties should be set at ([\d]+) basis points going to the "(.*)" address$"#)]
async fn verify_royalty(world: &mut SCWorld, basis_points: i32, _royalty_address_name: String) {

    let deployer = world.deployer_address().clone();
    let royalty_info = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, (Address, U256)>("royaltyInfo", (U256::from(1), U256::from(100000_u64)))
        .expect("Error finding royaltyInfo method").call().await.expect("Error sending royaltyInfo call");

    assert_eq!(royalty_info.0, deployer);
    assert_eq!(royalty_info.1, U256::from(100000 * basis_points / 10000));
}

#[then(r#"the ability to mint more NFTs should be frozen"#)]
async fn verify_cant_mint(world: &mut SCWorld) {
    let lookup_result = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, ()>("mint", U256::from(1));
    assert!(lookup_result.is_err());  // We don't have a mint function!
}