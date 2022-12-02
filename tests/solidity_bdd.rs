use std::{env, fs};
use std::collections::HashMap;
use std::fmt::Formatter;
use std::borrow::Borrow;
use ethers::utils::{Anvil, AnvilInstance};
use ethers_providers::{Provider, Http};
use ethers::prelude::*;
use ethers_contract::Contract;
use std::time::Duration;
use std::sync::Arc;
use async_std::task;
use cucumber::{ World, writer, WriterExt };
use ethers_core::k256;
use futures::FutureExt;

abigen!(TheLow, "out/TheLow.sol/TheLow.json");

#[derive(cucumber::World, Default, Debug)]
pub struct SCWorld {
    config: TestConfig,
    contracts: HashMap<String, ethers::contract::Contract<SignerMiddleware<Provider<Http>, Wallet<k256::ecdsa::SigningKey>>>>,
    addresses: HashMap<String, Address>,
    address_count: usize,  // TODO: Refactor into a separate address book struct
    anvil: Option<AnvilConnection>,
    pub thelow_contract: Option<the_low::TheLow<SignerMiddleware<Provider<Http>, Wallet<k256::ecdsa::SigningKey>>>> // FIXME: Find a generic way to do this
}


impl SCWorld {
    pub fn deployer_address(&mut self) -> &Address {
        self.get_address("deployer".to_string())
    }
    pub fn get_address(&mut self, name: String) -> &Address {
        if ! self.addresses.contains_key(&name) {
            let instance = self.anvil.as_ref().expect("Anvil must be initialized before client is called").anvil.borrow();
            let wallet: LocalWallet = instance.keys()[self.address_count].clone().into();
            self.address_count += 1;
            self.addresses.insert(name.clone(), wallet.address());
        }

        self.addresses.get(&name).expect("Address not found by name after insert")

    }
    pub fn client(&self) -> Arc<SignerMiddleware<ethers_providers::Provider<Http>, Wallet<ethers::core::k256::ecdsa::SigningKey>>> {
        let instance = self.anvil.as_ref().expect("Anvil must be initialized before client is called").anvil.borrow();
        let provider = Provider::<Http>::try_from(instance.endpoint()).expect("Failed to connect to Anvil").interval(Duration::from_millis(10u64));
        let wallet: LocalWallet = instance.keys()[0].clone().into();
        let client = Arc::new(SignerMiddleware::new(provider, wallet.with_chain_id(instance.chain_id())));
        client
    }
    pub fn add_contract(&mut self, contract: ethers::contract::Contract<SignerMiddleware<Provider<Http>, Wallet<k256::ecdsa::SigningKey>>>, name: String) {
        self.contracts.insert(name, contract);
    }


}

#[derive(Default, Debug)]
pub(crate) struct TestConfig {
    fork_endpoint: Option<String>,
    fork_chain_id: Option<u64>,
//    contracts: Vec<Contract<M>>,
//    addresses: HashMap<String, Address>,
}

impl TestConfig {
    pub(crate) fn fork(&mut self, endpoint: String, chain_id: u64) {
        self.fork_endpoint = Option::Some(endpoint);
        self.fork_chain_id = Option::Some(chain_id);
    }

}

#[derive(Debug)]
pub struct SmartContractInfo {
    filepath: String,
    name: String,
}

struct AnvilConnection {
    anvil: AnvilInstance,
    client: Arc<SignerMiddleware<ethers_providers::Provider<Http>, Wallet<ethers::core::k256::ecdsa::SigningKey>>>,
}

impl std::fmt::Debug for AnvilConnection {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AnvilConnection")
            .field("anvil", &self.anvil.endpoint())
            .field("client", &self.client)
            .finish()
    }
}

pub(crate) fn new() -> TestConfig {
    let config = TestConfig {
        fork_endpoint: Option::None,
        fork_chain_id: Option::None,
    };
    config
}

async fn start_anvil(fork_url: String, chain_id: u64, world: &mut SCWorld) {
    let anvil = Anvil::new().fork(fork_url).chain_id(chain_id);
    let instance: AnvilInstance = anvil.spawn();
    let endpoint = instance.endpoint();
    println!("Anvil running at `{}`", endpoint);

    let provider = Provider::<Http>::try_from(instance.endpoint()).expect("Failed to connect to Anvil").interval(Duration::from_millis(10u64));

    let wallet: LocalWallet = instance.keys()[0].clone().into();
    let client = Arc::new(SignerMiddleware::new(provider, wallet.with_chain_id(instance.chain_id())));
    let connection = AnvilConnection {
        anvil: instance,
        client,
    };
    world.anvil = Option::Some(connection);

}

// impl ContractTestHelper for TestConfig {
pub(crate) async fn run(config: TestConfig) -> () {
    //let file = fs::File::create(dbg!(format!("{}/junit.xml", env!("OUT_DIR")))).expect("File should be found");
    let fork_url = config.fork_endpoint.unwrap_or("localhost:8545".to_string());
    let chain_id = config.fork_chain_id.unwrap_or(31337_u64);

    SCWorld::cucumber()
        // Start a fresh anvil before each scenario
        .before(move |_feature, _rule, _scenario, world| {
            start_anvil(fork_url.clone(), chain_id.clone(), world).boxed_local()
        })
    /*
.with_writer(
    // Output to both console and JUnit XML
    // NOTE: `Writer`s pipeline is constructed in a reversed order.
    writer::Basic::stdout() // And output to STDOUT.
        .summarized()       // Simultaneously, add execution summary.
        .tee::<SCWorld, _>(writer::JUnit::for_tee(file, 0)) // Then, output to XML file.
        .normalized()       // First, normalize events order.
        )
     */
        .run("tests/features")
        .await;
}

