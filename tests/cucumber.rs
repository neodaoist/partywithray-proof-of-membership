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
