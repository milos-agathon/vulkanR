# vulkanR

Offscreen GPU renderer for R using Rust + extendr + wgpu.

## Features

- **Headless rendering**: Offscreen rendering to PNG files
- **Cross-platform**: Vulkan backend on Windows/Linux, Metal on macOS  
- **No SDK required**: Only platform GPU drivers needed
- **Deterministic**: Fixed rendering pipeline for reproducible results
- **WGSL shaders**: Compiled at runtime, no build-time shader compilation

## Installation

```r
# Install dependencies
install.packages(c("rextendr", "devtools"))

# Build and install
rextendr::document()
devtools::install()
```

## Usage

```r
library(vulkanR)

# Get GPU information
gpu_info()

# Create a heightmap
z <- outer(0:31, 0:31, function(i,j) sin(i/6) + cos(j/7))

# Render to PNG
render_heightmap("heightmap.png", z, 
                width = 64L, height = 64L, 
                scale_z = 1.0, fov_deg = 35,
                sun_dir = c(0.6, 0.7, 0.4))
```

## System Requirements

- **Windows/Linux**: GPU drivers with Vulkan 1.1+ support
- **macOS**: Metal support (macOS 10.11+)
- **CI/Testing**: mesa-vulkan-drivers, vulkan-tools, libvulkan1

## License

MIT