use ethers::prelude::*;


fn main() {
    println!("cargo:rerun-if-changed=out/TheLow.sol/TheLow.json");
    Abigen::new("TheLow", "./out/TheLow.sol/TheLow.json").expect("Failed to create new abigen")
        .generate().expect("Failed to generate")
        .write_to_file("target/TheLow.rs").expect("Failed to write to file");

}
