#[derive(Debug)]
pub struct HeightfieldMesh {
    pub vertices: Vec<f32>,
    pub indices: Vec<u32>,
}

impl HeightfieldMesh {
    pub fn new(z_data: &[f32], rows: usize, cols: usize, scale_z: f32) -> Result<Self, String> {
        if z_data.len() != rows * cols {
            return Err(format!("z_data length {} doesn't match rows*cols {}", z_data.len(), rows * cols));
        }

        let mut vertices = Vec::new();
        let mut indices = Vec::new();

        // Generate vertices with positions, normals, and colors
        for i in 0..rows {
            for j in 0..cols {
                let idx = i * cols + j;
                let height = z_data[idx] * scale_z;
                
                // Position (normalize to [-1, 1] range)
                let x = (j as f32 / (cols - 1) as f32) * 2.0 - 1.0;
                let y = height;
                let z = (i as f32 / (rows - 1) as f32) * 2.0 - 1.0;
                
                // Compute normal using central differences with epsilon guard
                let epsilon = 1e-6f32;
                let dx = if j > 0 && j < cols - 1 {
                    (z_data[i * cols + j + 1] - z_data[i * cols + j - 1]) * scale_z
                } else if j == 0 {
                    (z_data[i * cols + j + 1] - z_data[i * cols + j]) * scale_z
                } else {
                    (z_data[i * cols + j] - z_data[i * cols + j - 1]) * scale_z
                };
                
                let dz = if i > 0 && i < rows - 1 {
                    (z_data[(i + 1) * cols + j] - z_data[(i - 1) * cols + j]) * scale_z
                } else if i == 0 {
                    (z_data[(i + 1) * cols + j] - z_data[i * cols + j]) * scale_z
                } else {
                    (z_data[i * cols + j] - z_data[(i - 1) * cols + j]) * scale_z
                };
                
                // Cross product for normal: (-dx, 2/grid_spacing, -dz)
                let grid_spacing = 2.0 / ((cols - 1).max(rows - 1) as f32);
                let normal_x = -dx;
                let normal_y = 2.0 * grid_spacing;
                let normal_z = -dz;
                
                // Normalize with epsilon guard
                let length = (normal_x * normal_x + normal_y * normal_y + normal_z * normal_z).sqrt();
                let inv_length = if length > epsilon { 1.0 / length } else { 0.0 };
                
                let nx = normal_x * inv_length;
                let ny = if length > epsilon { normal_y * inv_length } else { 1.0 };
                let nz = normal_z * inv_length;
                
                // Color based on height (simple grayscale)
                let color = (height + 1.0) * 0.5; // Normalize to [0, 1]
                let color = color.clamp(0.0, 1.0);
                
                // Add vertex: position (3) + normal (3) + color (3) = 9 floats
                vertices.extend_from_slice(&[
                    x, y, z,           // position
                    nx, ny, nz,        // normal
                    color, color, color // color
                ]);
            }
        }

        // Generate triangle indices
        for i in 0..(rows - 1) {
            for j in 0..(cols - 1) {
                let idx = (i * cols + j) as u32;
                let next_row = ((i + 1) * cols + j) as u32;
                
                // Two triangles per quad
                // Triangle 1: bottom-left, top-left, bottom-right
                indices.extend_from_slice(&[
                    idx, next_row, idx + 1
                ]);
                
                // Triangle 2: top-left, top-right, bottom-right
                indices.extend_from_slice(&[
                    next_row, next_row + 1, idx + 1
                ]);
            }
        }

        Ok(Self { vertices, indices })
    }
}