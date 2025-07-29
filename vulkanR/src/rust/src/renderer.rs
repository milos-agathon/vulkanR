use wgpu;
use anyhow::Result;

pub struct Renderer {
    instance: wgpu::Instance,
    device: wgpu::Device,
    queue: wgpu::Queue,
}

impl Renderer {
    pub async fn new() -> Result<Self> {
        /* Enforce backend choice at runtime:
           - macOS: METAL
           - Others (Windows/Linux): VULKAN
        */
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: if cfg!(target_os = "macos") {
                wgpu::Backends::METAL
            } else {
                wgpu::Backends::VULKAN
            },
            ..Default::default()
        });

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                compatible_surface: None,
                force_fallback_adapter: false,
            })
            .await
            .ok_or_else(|| anyhow::anyhow!("Failed to find an appropriate adapter"))?;

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    features: wgpu::Features::empty(),
                    limits: wgpu::Limits::default(),
                    label: None,
                },
                None,
            )
            .await?;

        Ok(Self {
            instance,
            device,
            queue,
        })
    }
}