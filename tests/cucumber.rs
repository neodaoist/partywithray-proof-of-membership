mod solidity_bdd;
use std::{env};
use std::borrow::Borrow;
use async_std::task;
use crate::solidity_bdd::{SCWorld, TestConfig};
use cucumber::{gherkin::Step, given, when, then, World};
use ethers::prelude::*; // {k256, U256};
use ethers_contract::{abigen, Contract};
use ethers_middleware::SignerMiddleware;
use ethers_providers::{Http, Provider};
use ethers_signers::Wallet;
use serde_json;
use base64;

const FORK_CHAIN_ID: u64 = 31337_u64;

// Generate bindings for contracts
abigen!(TheLow, "out/TheLow.sol/TheLow.json");


// Test configuration and runner

#[tokio::main]
async fn main()
{
    // Generate bindings for the 3rd party contracts we'll need


    // Read fork endpoint from environment variable ETH_NODE_URL
    let fork_endpoint = env::var("ETH_NODE_URL").expect("Environment variable ETH_NODE_URL should be defined and be a valid API URL");

    let mut config: solidity_bdd::TestConfig = solidity_bdd::new();
        config.fork(fork_endpoint, FORK_CHAIN_ID)
        //.thirdPartyContracts([])  // FIXME: Add VRF here if we end up using it
        ;
    solidity_bdd::run(config).await
}

// Stepdefs
#[given(r#"the Partywithray Proof of Membership NFT contract is deployed"#)]
fn deploy_party_with_ray(world: &mut SCWorld) {
    let thelow_contract = task::block_on(solidity_bdd::the_low::TheLow::deploy(world.client(), (*world.deployer_address())).expect("Failed to deploy").send()).expect("Failed to send");
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
    let expected_supply = ethers::types::U256::from_dec_str(expected_supply_str.as_str()).expect("Expected supply value should be a number");

    let actual_supply = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
        .method::<_, U256>("totalSupply", ())
        .expect("Error finding totalSupply method").call().await.expect("Error sending totalSupply call");

    assert_eq!(expected_supply, actual_supply);
}

#[then(regex = r#"^all ([\d]+) NFTs should have the pre-reveal art$"#)]
async fn verify_pre_reveal_art(world: &mut SCWorld, nft_count_str: String) {
    // ImageURI return a JSON blob -- parse out the image in all 222 NFTs
    let nft_count: i32 = nft_count_str.parse().expect("Number of NFTs should be a number");
    for i in 1..nft_count {
        // Look up the JSON metadata
        let metadata: String = world.thelow_contract.as_ref().expect("TheLow Contract should be initialized")
            .method::<_, String>("tokenURI", U256::from(i))
            .expect("Error finding tokenURI method").call().await.expect("Error sending tokenURI call");

        // Decode base64
        let b64string: String = metadata.strip_prefix("data:application/json;base64,").expect("String should have base64 prefix").to_string();
        let jsonbytes = base64::decode(b64string).expect("Base64 string should be valid");

        // Parse JSON and inspect
        let jsondata: serde_json::Value = serde_json::from_slice(&*jsonbytes).expect("JSON should be valid");
        assert_eq!(&jsondata["image"],"ipfs://ABC");  // FIXME -- Real IPFS URI here
    }
}