use extendr_api::prelude::*;

mod renderer;
mod mesh;
mod shaders;

use renderer::WgpuRenderer;

/// Get GPU information
#[extendr]
fn gpu_info() -> extendr_api::Result<String> {
    let renderer = WgpuRenderer::new().map_err(|e| extendr_api::Error::Other(e.to_string()))?;
    Ok(renderer.get_info())
}

/// Render heightmap to PNG
#[extendr]
fn render_heightmap(
    path: &str,
    z: RMatrix<f64>,
    width: i32,
    height: i32,
    scale_z: f64,
    fov_deg: f64,
    sun_dir: Vec<f64>,
) -> extendr_api::Result<()> {
    let z_data: Vec<f32> = z.data().iter().map(|&x| x as f32).collect();
    let rows = z.nrows();
    let cols = z.ncols();

    let mut renderer = WgpuRenderer::new().map_err(|e| extendr_api::Error::Other(e.to_string()))?;

    if sun_dir.len() != 3 {
        return Err(extendr_api::Error::Other("sun_dir must have length 3".to_string()));
    }
    let sun_dir_f32 = [sun_dir[0] as f32, sun_dir[1] as f32, sun_dir[2] as f32];

    renderer
        .render_heightmap(
            path,
            &z_data,
            rows,
            cols,
            width as u32,
            height as u32,
            scale_z as f32,
            fov_deg as f32,
            sun_dir_f32,
        )
        .map_err(|e| extendr_api::Error::Other(e.to_string()))?;

    Ok(())
}

extendr_module! {
    mod vulkanR;
    fn gpu_info;
    fn render_heightmap;
}
