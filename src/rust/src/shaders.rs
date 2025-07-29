pub const VERTEX_SHADER: &str = r#"
struct Uniforms {
    mvp: mat4x4<f32>,
    sun_dir: vec3<f32>,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) world_pos: vec3<f32>,
}

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
    var output: VertexOutput;
    
    output.clip_position = uniforms.mvp * vec4<f32>(input.position, 1.0);
    output.color = input.color;
    output.normal = input.normal;
    output.world_pos = input.position;
    
    return output;
}
"#;

pub const FRAGMENT_SHADER: &str = r#"
struct Uniforms {
    mvp: mat4x4<f32>,
    sun_dir: vec3<f32>,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

struct FragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) world_pos: vec3<f32>,
}

@fragment
fn fs_main(input: FragmentInput) -> @location(0) vec4<f32> {
    let normal = normalize(input.normal);
    let sun_dir = normalize(uniforms.sun_dir);
    
    // Ambient lighting
    let ambient = 0.45;
    
    // Diffuse lighting
    let diffuse = max(dot(normal, sun_dir), 0.0) * 0.7;
    
    // Final color
    let lighting = ambient + diffuse;
    let final_color = input.color * lighting;
    
    return vec4<f32>(final_color, 1.0);
}
"#;