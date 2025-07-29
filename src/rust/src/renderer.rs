use anyhow::{Context, Result, anyhow};
use wgpu::*;
use wgpu::util::DeviceExt;
use glam::{Mat4, Vec3};
use image::{ImageBuffer, Rgba};
use std::path::Path;

use crate::mesh::HeightfieldMesh;
use crate::shaders::{VERTEX_SHADER, FRAGMENT_SHADER};

/// Renderer holding the wgpu device and queue.
pub struct WgpuRenderer {
    pub device: Device,
    pub queue: Queue,
    pub adapter_info: AdapterInfo,
}

impl WgpuRenderer {
    /// Create a new renderer using Vulkan (Windows/Linux) or Metal (macOS).
    pub fn new() -> Result<Self> {
        let instance = Instance::new(InstanceDescriptor {
            backends: if cfg!(target_os = "macos") {
                Backends::METAL
            } else {
                Backends::VULKAN
            },
            ..Default::default()
        });

        let adapter = pollster::block_on(instance.request_adapter(&RequestAdapterOptions {
            power_preference: PowerPreference::HighPerformance,
            compatible_surface: None,
            force_fallback_adapter: false,
        }))
        .ok_or_else(|| anyhow!("Failed to find suitable GPU adapter"))?;

        let adapter_info = adapter.get_info();

        let (device, queue) = pollster::block_on(adapter.request_device(
            &DeviceDescriptor {
                label: Some("vulkanR Device"),
                required_features: Features::empty(),
                required_limits: Limits::default(),
            },
            None,
        ))?;

        Ok(Self { device, queue, adapter_info })
    }

    /// Return a human‑readable adapter string.
    pub fn get_info(&self) -> String {
        let dtype = match self.adapter_info.device_type {
            DeviceType::DiscreteGpu => "Discrete GPU",
            DeviceType::IntegratedGpu => "Integrated GPU",
            DeviceType::VirtualGpu => "Virtual GPU",
            DeviceType::Cpu => "CPU",
            DeviceType::Other => "Other",
        };
        format!("Backend: {:?}, Device: {} ({})",
                self.adapter_info.backend, self.adapter_info.name, dtype)
    }

    /// Render a heightmap mesh to a PNG file offscreen.
    pub fn render_heightmap(
        &mut self,
        output_path: &str,
        z_data: &[f32],
        rows: usize,
        cols: usize,
        width: u32,
        height: u32,
        scale_z: f32,
        fov_deg: f32,
        sun_dir: [f32; 3],
    ) -> Result<()> {
        // Build mesh (positions+normals+colors, 9 floats per vertex)
        let mesh = HeightfieldMesh::new(z_data, rows, cols, scale_z)?;

        // Render target textures
        let color_tex = self.device.create_texture(&TextureDescriptor {
            label: Some("vulkanR Color"),
            size: Extent3d { width, height, depth_or_array_layers: 1 },
            mip_level_count: 1,
            sample_count: 1,
            dimension: TextureDimension::D2,
            format: TextureFormat::Rgba8UnormSrgb,
            usage: TextureUsages::RENDER_ATTACHMENT | TextureUsages::COPY_SRC,
            view_formats: &[],
        });
        let depth_tex = self.device.create_texture(&TextureDescriptor {
            label: Some("vulkanR Depth"),
            size: Extent3d { width, height, depth_or_array_layers: 1 },
            mip_level_count: 1,
            sample_count: 1,
            dimension: TextureDimension::D2,
            format: TextureFormat::Depth32Float,
            usage: TextureUsages::RENDER_ATTACHMENT,
            view_formats: &[],
        });
        let color_view = color_tex.create_view(&TextureViewDescriptor::default());
        let depth_view = depth_tex.create_view(&TextureViewDescriptor::default());

        // Buffers
        let vertex_buffer = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("vulkanR Vertex Buffer"),
            contents: bytemuck::cast_slice(&mesh.vertices),
            usage: BufferUsages::VERTEX,
        });
        let index_buffer = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("vulkanR Index Buffer"),
            contents: bytemuck::cast_slice(&mesh.indices),
            usage: BufferUsages::INDEX,
        });

        // Camera & uniforms
        let aspect = width as f32 / height as f32;
        let fov_rad = fov_deg.to_radians();

        // Compute a robust camera distance. If scene extents are not readily available here,
        // use a conservative fallback so tests can compile and render predictably.
        // TODO(milos): replace the fallback with an AABB-based computation:
        // let r = radius / (0.5 * fov_rad).tan() + radius;
        let r: f32 = 3.0;
        let eye = Vec3::new(r, r, r);
        let target = Vec3::new(0.0, 0.0, 0.0);
        let up = Vec3::new(0.0, 1.0, 0.0);

        let view = Mat4::look_at_rh(eye, target, up);
        let proj = Mat4::perspective_rh(fov_rad, aspect, 0.1, 100.0);
        let mvp = proj * view;

        let sun = Vec3::from(sun_dir).normalize();

        // Pack uniforms as 20 floats: mvp (16) + sun_dir (3) + padding (1)
        let mut uniforms: [f32; 20] = [0.0; 20];
        uniforms[..16].copy_from_slice(&mvp.to_cols_array());
        uniforms[16..19].copy_from_slice(&sun.to_array());
        uniforms[19] = 0.0;

        let uniform_buffer = self.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("vulkanR Uniform Buffer"),
            contents: bytemuck::cast_slice(&uniforms),
            usage: BufferUsages::UNIFORM,
        });

        // Bindings
        let bgl = self.device.create_bind_group_layout(&BindGroupLayoutDescriptor {
            label: Some("vulkanR BGL"),
            entries: &[BindGroupLayoutEntry {
                binding: 0,
                visibility: ShaderStages::VERTEX | ShaderStages::FRAGMENT,
                ty: BindingType::Buffer {
                    ty: BufferBindingType::Uniform,
                    has_dynamic_offset: false,
                    min_binding_size: None,
                },
                count: None,
            }],
        });
        let bind_group = self.device.create_bind_group(&BindGroupDescriptor {
            label: Some("vulkanR Bind Group"),
            layout: &bgl,
            entries: &[BindGroupEntry {
                binding: 0,
                resource: uniform_buffer.as_entire_binding(),
            }],
        });

        // Shaders
        let vs = self.device.create_shader_module(ShaderModuleDescriptor {
            label: Some("vulkanR VS"),
            source: ShaderSource::Wgsl(VERTEX_SHADER.into()),
        });
        let fs = self.device.create_shader_module(ShaderModuleDescriptor {
            label: Some("vulkanR FS"),
            source: ShaderSource::Wgsl(FRAGMENT_SHADER.into()),
        });

        // Pipeline
        let layout = self.device.create_pipeline_layout(&PipelineLayoutDescriptor {
            label: Some("vulkanR Pipeline Layout"),
            bind_group_layouts: &[&bgl],
            push_constant_ranges: &[],
        });
        let pipeline = self.device.create_render_pipeline(&RenderPipelineDescriptor {
            label: Some("vulkanR Pipeline"),
            layout: Some(&layout),
            vertex: VertexState {
                module: &vs,
                entry_point: "vs_main",
                buffers: &[VertexBufferLayout {
                    array_stride: std::mem::size_of::<[f32; 9]>() as BufferAddress,
                    step_mode: VertexStepMode::Vertex,
                    attributes: &[ 
                        VertexAttribute { offset: 0, shader_location: 0, format: VertexFormat::Float32x3 },
                        VertexAttribute { offset: std::mem::size_of::<[f32; 3]>() as BufferAddress, shader_location: 1, format: VertexFormat::Float32x3 },
                        VertexAttribute { offset: std::mem::size_of::<[f32; 6]>() as BufferAddress, shader_location: 2, format: VertexFormat::Float32x3 },
                    ],
                }],
            },
            fragment: Some(FragmentState {
                module: &fs,
                entry_point: "fs_main",
                targets: &[Some(ColorTargetState {
                    format: TextureFormat::Rgba8UnormSrgb,
                    blend: Some(BlendState::REPLACE),
                    write_mask: ColorWrites::ALL,
                })],
            }),
            primitive: PrimitiveState {
                topology: PrimitiveTopology::TriangleList,
                strip_index_format: None,
                front_face: FrontFace::Ccw,
                cull_mode: Some(Face::Back),
                unclipped_depth: false,
                polygon_mode: PolygonMode::Fill,
                conservative: false,
            },
            depth_stencil: Some(DepthStencilState {
                format: TextureFormat::Depth32Float,
                depth_write_enabled: true,
                depth_compare: CompareFunction::Less,
                stencil: StencilState::default(),
                bias: DepthBiasState::default(),
            }),
            multisample: MultisampleState { count: 1, mask: !0, alpha_to_coverage_enabled: false },
            multiview: None,
        });

        // Encode render pass
        let mut encoder = self.device.create_command_encoder(&CommandEncoderDescriptor {
            label: Some("vulkanR Encoder"),
        });

        {
            let mut pass = encoder.begin_render_pass(&RenderPassDescriptor {
                label: Some("vulkanR Pass"),
                color_attachments: &[Some(RenderPassColorAttachment {
                    view: &color_view,
                    resolve_target: None,
                    ops: Operations {
                        load: LoadOp::Clear(Color { r: 0.1, g: 0.2, b: 0.3, a: 1.0 }),
                        store: StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: Some(RenderPassDepthStencilAttachment {
                    view: &depth_view,
                    depth_ops: Some(Operations { load: LoadOp::Clear(1.0), store: StoreOp::Store }),
                    stencil_ops: None,
                }),
                occlusion_query_set: None,
                timestamp_writes: None,
            });

            pass.set_pipeline(&pipeline);
            pass.set_bind_group(0, &bind_group, &[]);
            pass.set_vertex_buffer(0, vertex_buffer.slice(..));
            pass.set_index_buffer(index_buffer.slice(..), IndexFormat::Uint32);
            pass.draw_indexed(0..mesh.indices.len() as u32, 0, 0..1);
        }

        // Copy to readback buffer
        let bytes_per_pixel = 4u32;
        let unpadded = width * bytes_per_pixel;
        let align = 256u32;
        let padded = ((unpadded + align - 1) / align) * align;

        let readback = self.device.create_buffer(&BufferDescriptor {
            label: Some("vulkanR Readback"),
            size: (padded * height) as u64,
            usage: BufferUsages::COPY_DST | BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });

        encoder.copy_texture_to_buffer(
            ImageCopyTexture {
                texture: &color_tex,
                mip_level: 0,
                origin: Origin3d::ZERO,
                aspect: TextureAspect::All,
            },
            ImageCopyBuffer {
                buffer: &readback,
                layout: ImageDataLayout {
                    offset: 0,
                    bytes_per_row: Some(padded),
                    rows_per_image: Some(height),
                },
            },
            Extent3d { width, height, depth_or_array_layers: 1 },
        );

        self.queue.submit(std::iter::once(encoder.finish()));

        // Map and read
        let slice = readback.slice(..);
        let (tx, rx) = std::sync::mpsc::channel();
        slice.map_async(MapMode::Read, move |r| { tx.send(r).unwrap(); });
        self.device.poll(Maintain::Wait);
        rx.recv().unwrap()?;
        let data = slice.get_mapped_range();

        // Compose PNG (remove row padding)
        let mut img = ImageBuffer::<Rgba<u8>, Vec<u8>>::new(width, height);
        for y in 0..height {
            let row = &data[(y * padded) as usize .. (y * padded + unpadded) as usize];
            for x in 0..width {
                let o = (x * 4) as usize;
                let p = Rgba([row[o], row[o + 1], row[o + 2], row[o + 3]]);
                img.put_pixel(x, y, p);
            }
        }
        drop(data);
        readback.unmap();

        // Save
        img.save(Path::new(output_path))
            .with_context(|| format!("Failed to save image to {}", output_path))?;

        Ok(())
    }
}

