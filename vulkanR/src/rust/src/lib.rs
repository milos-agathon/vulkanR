use extendr_api::prelude::*;

pub mod renderer;

// Expose functions to R
#[extendr]
fn hello_rust() -> String {
    "Hello from Rust!".to_string()
}

// Generate the R bindings
extendr_module! {
    mod vulkanr;
    fn hello_rust;
}