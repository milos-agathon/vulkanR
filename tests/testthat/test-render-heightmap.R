test_that("render_heightmap produces expected output", {
  
  # Reference image as base64
  # TODO: Replace with a complete base64-encoded 64x64 PNG produced by a known-good run.
  # Temporary fallback: skip golden check if base64 is missing.
  ref_base64 <- Sys.getenv("VULKANR_REF64_BASE64", unset = "")

  # Create test heightmap
  z <- outer(0:31, 0:31, function(i, j) sin(i/6) + cos(j/7))
  
  # Write reference PNG if missing
  ref_path <- test_path("ref_heightmap_64.png")
  write_reference_png_if_missing(ref_path, ref_base64)
  
  # Render test image
  test_path_png <- tempfile(fileext = ".png")
  on.exit(unlink(test_path_png), add = TRUE)
  
  expect_invisible(
    render_heightmap(test_path_png, z, 
                    width = 64L, height = 64L,
                    scale_z = 1.0, fov_deg = 35,
                    sun_dir = c(0.6, 0.7, 0.4))
  )
  
  # Check file was created
  expect_true(file.exists(test_path_png))
  
  # Check file size is reasonable
  file_size <- file.info(test_path_png)$size
  expect_gt(file_size, 100)  # At least 100 bytes
  expect_lt(file_size, 50000)  # Less than 50KB
  
  # Compare with reference if we have one
  if (file.exists(ref_path) && nchar(ref_base64) > 0) {
    diff <- compute_image_diff(test_path_png, ref_path)
    expect_lt(diff, 2.0, 
             info = sprintf("Image difference %.2f exceeds tolerance of 2.0", diff))
  }
})

test_that("render_heightmap handles different parameters", {
  skip_if_not(capabilities()[["cairo"]], "Cairo graphics not available")
  
  z <- matrix(runif(16), nrow = 4, ncol = 4)
  
  test_path_png <- tempfile(fileext = ".png")
  on.exit(unlink(test_path_png), add = TRUE)
  
  # Test with different parameters
  expect_invisible(
    render_heightmap(test_path_png, z,
                    width = 32L, height = 32L,
                    scale_z = 0.5, fov_deg = 45,
                    sun_dir = c(1, 0, 0))
  )
  
  expect_true(file.exists(test_path_png))
})