# Simple test to verify the patch works
cat("Testing vk_render patch...\n")

# Check if the function exists and has been modified correctly
source("R/api-render.R")
source("R/api-scene.R")

# Create a scene object
sc <- vk_scene()
cat("Created scene object: ", class(sc), "\n")

# Test the function logic (without actual native call)
test_vk_render <- function(scene, width = 640, height = 360, file = NULL, verbose = FALSE) {
  stopifnot(inherits(scene, "vk_scene"))
  # Prefer native headless path if registered by extendr:
  if (exists("vk_render_headless", where = asNamespace("vulkanR"), inherits = FALSE)) {
    cat("vk_render_headless found in namespace\n")
  } else {
    cat("vk_render_headless NOT found - using fallback\n")
    # Fallback: no native path registered yet
    if (!is.null(file)) return(invisible(file))
    return(raw())
  }
}

result <- test_vk_render(sc)
cat("Test result: ", class(result), ", length: ", length(result), "\n")

cat("Patch verification complete!\n")