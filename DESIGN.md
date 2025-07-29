# vulkanR — Milestone 1 Design Notes

## Public R API (frozen for M1)

- `vk_scene(scene_opts = list(), ...)` → create a scene object (class `vk_scene`).
- `add_mesh(scene, mesh, material = NULL, ...)` → add geometry to a scene.
- `add_light(scene, type = "directional", params = list(), ...)` → add a light.
- `vk_render(scene, width = 640, height = 360, file = NULL, verbose = FALSE, ...)` → render image; returns raw() or `invisible(file)`.
- `vk_view(scene, title = "vulkanR", ...)` → open interactive view (stub for M1).
- `vk_is_available()` → stub diagnostic; native probe planned for M2.
- Existing: `render_heightmap(output, z, width = 512, height = 512, ...)` → returns **invisibly**.

## Object System

- **S3** chosen for M1 due to simplicity and minimal ceremony.
- Classes: `vk_scene` with `print.vk_scene`.
- Generics: `add_geometry(x, ...)`, `add_texture(x, ...)` + **default methods** (friendly errors).
- Future M2+: S3 methods for specific mesh/texture classes.

## Error & Diagnostics Policy

- Validate inputs **early** in R; human-readable `stop()` messages.
- For M1, wrappers are side‑effect‑free; diagnostics via `vk_is_available()` (stub).
- Future M2+: native errors mapped to R with clear messages.

## Binding Map (forward-looking)

- `vk_scene()` → `scene_create()` (Rust/extendr, planned)
- `add_mesh()` → `scene_add_mesh()` (Rust/extendr, planned)
- `add_light()` → `scene_add_light()` (Rust/extendr, planned)
- `vk_render()` → `render_scene()` (Rust/extendr or C++, planned)
- `vk_is_available()` → `vk_is_available_native()` (Rust/ash, planned)
- `render_heightmap()` → current R/native wrapper (returns invisibly)

## Testing Scope (M1)

- Smoke tests only; no GPU work.
- Golden images deferred to later milestones with headless surfaces in CI.

## Notes

- Regenerate docs via roxygen2 (`devtools::document()`).
- CI across platforms will be configured in later milestones.

## Milestone 1 — Definition of Done (DoD)

- [ ] **API surface frozen** for M1: `vk_scene()`, `add_mesh()`, `add_light()`, `vk_render()`, `vk_view()`, `vk_is_available()`, and `render_heightmap()` (returns invisibly).
- [ ] **Exports present** in `NAMESPACE` for all public functions and `S3method(print,vk_scene)`.
- [ ] **Roxygen complete**: each export has `@title`, `@description`, `@param`, `@return`, `@examples`, `@export`.
- [ ] **Generics**: `add_geometry()`, `add_texture()` plus default methods that error with clear messages.
- [ ] **Diagnostics**: `vk_is_available()` documented as stub for M1.
- [ ] **Tests**: `tests/testthat.R` runner in top‑level `tests/`; smoke tests pass locally.
- [ ] **Docs regenerated** via `devtools::document()`; no new `R CMD check` issues expected at this stage.