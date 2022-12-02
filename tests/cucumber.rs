mod solidity_bdd;
use std::{env};
use std::borrow::Borrow;
use async_std::task;
use crate::solidity_bdd::{SCWorld, TestConfig};
use cucumber::{gherkin::Step, given, when, then, World};
use ethers::prelude::k256;
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

#[given("the Partywithray Proof of Membership NFT contract is deployed")]
fn deploy_party_with_ray(world: &mut SCWorld) {
    println!("Deploying the low");
    let thelow_contract = task::block_on(solidity_bdd::the_low::TheLow::deploy(world.client(), ()).expect("Failed to deploy").send()).expect("Failed to send");
    world.thelow_contract = Some(thelow_contract);
}