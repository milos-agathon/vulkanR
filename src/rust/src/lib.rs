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
    let r = WgpuRenderer::new()?;
    Ok(format!(
        "Backend: {backend}; Device: {name}; max_tex_2d: {mt2d}; max_bind_groups: {bg}; budget_mb: {mb}",
        backend = r.get_backend_name(),
        name = r.get_device_name(),
        mt2d = r.caps.max_texture_dimension_2d,
        bg   = r.caps.max_bind_groups,
        mb   = r.get_vram_budget_bytes() / (1024*1024),
    ))
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

    if sun_dir.len() != 3 || !sun_dir.iter().all(|v| v.is_finite()) {
        return Err(VulkanRError::InvalidInput {
            param: "sun_dir".into(),
            reason: "must be length-3 finite numeric".into(),
        });
    }

    if width <= 0 || height <= 0 {
        return Err(VulkanRError::InvalidInput {
            param: "width/height".into(),
            reason: "must be positive".into(),
        });
    }

    let (w, h) = (width as u32, height as u32);
    let mut renderer = WgpuRenderer::new()?;
    renderer.ensure_target_ok(w, h)?; // B1: guard BEFORE allocation

    // continue with render, as before …
    renderer.render_heightmap(
        path, &z_data, rows, cols, w, h, scale_z as f32, fov_deg as f32,
        [sun_dir[0] as f32, sun_dir[1] as f32, sun_dir[2] as f32],
    )?;
    Ok(())
}

#[cfg(feature = "ffi")]
extendr_module! {
    mod vulkanR;
    fn gpu_info;
    fn render_heightmap;
}
