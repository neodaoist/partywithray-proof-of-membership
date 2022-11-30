mod solidity_bdd;
use std::{env};
use crate::solidity_bdd::TestConfig;

const FORK_CHAIN_ID: u64 = 31337_u64;



#[tokio::main]
// Test runner
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