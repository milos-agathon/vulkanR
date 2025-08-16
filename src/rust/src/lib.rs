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
    #[cfg(feature = "ffi")] z: RMatrix<f64>,
    #[cfg(not(feature = "ffi"))] _z_dummy: Vec<f64>,
    #[cfg(not(feature = "ffi"))] _rows: usize,
    #[cfg(not(feature = "ffi"))] _cols: usize,
    width: i32,
    height: i32,
    scale_z: f64,
    fov_deg: f64,
    sun_dir: Vec<f64>,
) -> Result<(), VulkanRError> {
    #[cfg(feature = "ffi")]
    {
        let (z_data, rows, cols) = {
            let z_data: Vec<f32> = z.data().iter().map(|&x| x as f32).collect();
            (z_data, z.nrows(), z.ncols())
        };

        let mut renderer = WgpuRenderer::new()?;

        if sun_dir.len() != 3 {
            return Err(VulkanRError::InvalidInput {
                param: "sun_dir".into(),
                reason: "must have length 3".into(),
            });
        }
        let sun_dir_f32 = [sun_dir[0] as f32, sun_dir[1] as f32, sun_dir[2] as f32];

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

    #[cfg(not(feature = "ffi"))]
    {
        // Suppress unused variable warnings for the no-ffi build
        let _ = (path, _z_dummy, _rows, _cols, width, height, scale_z, fov_deg, sun_dir);
        Err(VulkanRError::InvalidInput {
            param: "z".into(),
            reason: "functionality not available without the `ffi` feature".into(),
        })
    }
}

#[cfg(feature = "ffi")]
extendr_module! {
    mod vulkanR;
    fn gpu_info;
    fn render_heightmap;
}
