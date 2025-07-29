# Re-generate registration + wrappers
rextendr::clean()
rextendr::register_extendr()
devtools::document()

# Install to your dev library to avoid the locked-DLL problem
devlib <- file.path(
  Sys.getenv("USERPROFILE"), "R", "win-library",
  paste0(R.Version()$major, ".", R.Version()$minor, "-dev")
)
dir.create(devlib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(devlib, .libPaths()))

# Make sure nothing is loaded
if ("package:vulkanR" %in% search()) detach("package:vulkanR", unload = TRUE, character.only = TRUE)
dlls <- getLoadedDLLs()
if ("vulkanR" %in% rownames(dlls)) try(dyn.unload(dlls["vulkanR", "path"]), silent = TRUE)
unlink(file.path(.libPaths()[1], "00LOCK-vulkanR"), recursive = TRUE, force = TRUE)

devtools::install(upgrade = "never")
library(vulkanR, lib.loc = devlib)
devtools::test()

# check graphics card
vulkanR::gpu_info()

# try a tiny render
z <- outer(0:31, 0:31, function(i, j) sin(i / 6) + cos(j / 7))
vulkanR::render_heightmap(
  "out.png", z,
  width = 256L, height = 256L,
  scale_z = 0.8, fov_deg = 35, sun_dir = c(0.6, 0.7, 0.4)
)

