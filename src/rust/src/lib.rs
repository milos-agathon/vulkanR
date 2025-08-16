#[cfg(feature = "ffi")]
use extendr_api::prelude::*;

mod renderer;
mod mesh;
mod shaders;
mod errors;

use renderer::WgpuRenderer;
pub use errors::VulkanRError;

/// Get GPU information
#[cfg_attr(feature = "ffi", extendr)]
fn gpu_info() -> Result<String, VulkanRError> {
    let renderer = WgpuRenderer::new()?;
    Ok(renderer.get_info())
}

/// Render heightmap to PNG
#[cfg_attr(feature = "ffi", extendr)]
fn render_heightmap(
    path: &str,
    // FFI build: get an R matrix
    #[cfg(feature = "ffi")] z: RMatrix<f64>,
    // no-FFI build: get raw data + dims
    #[cfg(not(feature = "ffi"))] z: Vec<f64>,
    #[cfg(not(feature = "ffi"))] rows: usize,
    #[cfg(not(feature = "ffi"))] cols: usize,
    width: i32,
    height: i32,
    scale_z: f64,
    fov_deg: f64,
    sun_dir: Vec<f64>,
) -> Result<(), VulkanRError> {
    // Prepare z_data + dims in each mode
    #[cfg(feature = "ffi")]
    let (z_data, rows, cols) = {
        let z_data: Vec<f32> = z.data().iter().map(|&x| x as f32).collect();
        (z_data, z.nrows(), z.ncols())
    };

    #[cfg(not(feature = "ffi"))]
    let (z_data, rows, cols) = {
        if z.len() != rows * cols {
            return Err(VulkanRError::InvalidInput {
                param: "z",
                reason: format!("z length {} != rows*cols {}", z.len(), rows * cols),
            });
        }
        (z.iter().map(|&x| x as f32).collect::<Vec<f32>>(), rows, cols)
    };

    if sun_dir.len() != 3 {
        return Err(VulkanRError::InvalidInput {
            param: "sun_dir",
            reason: "must have length 3".into(),
        });
    }
    let sun_dir_f32 = [sun_dir[0] as f32, sun_dir[1] as f32, sun_dir[2] as f32];

    let mut renderer = WgpuRenderer::new()?;
    renderer.render_heightmap(
        path,
        &z_data,
        rows,
        cols,
        width as u32,
        height as u32,
        scale_z as f32,
        fov_deg as f32,
        sun_dir_f32,
    )?;
    Ok(())
}

#[cfg(feature = "ffi")]
extendr_module! {
    mod vulkanR;
    fn gpu_info;
    fn render_heightmap;
}
