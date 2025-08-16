#[cfg(feature = "ffi")]
use extendr_api::prelude::*;

#[derive(Debug)]
pub enum VulkanRError {
    DeviceInit(String),
    ShaderCompilation(String),
    OutOfMemory { requested: usize, available: usize },
    InvalidInput { param: String, reason: String },
    Capability(String),
    Io(String),
}

#[cfg(feature = "ffi")]
impl From<VulkanRError> for extendr_api::Error {
    fn from(e: VulkanRError) -> Self {
        extendr_api::error::Error::Other(format!("{e:?}"))
    }
}
