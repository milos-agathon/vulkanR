test_that("gpu_info returns non-empty string", {
  
  info <- gpu_info()
  expect_type(info, "character")
  expect_gt(nchar(info), 0)
  expect_true(grepl("Backend:", info))
  expect_true(grepl("Device:", info))
})

test_that("render_heightmap validates inputs", {
  z <- matrix(0, nrow = 4, ncol = 4)
  
  # Invalid path
  expect_error(render_heightmap(c("a", "b"), z), "single character string")
  expect_error(render_heightmap(123, z), "single character string")
  
  # Invalid z matrix
  expect_error(render_heightmap("test.png", "not a matrix"), "numeric matrix")
  expect_error(render_heightmap("test.png", c(1, 2, 3)), "numeric matrix")
  
  # Invalid dimensions
  expect_error(render_heightmap("test.png", z, width = -1L), "positive integer")
  expect_error(render_heightmap("test.png", z, height = 0L), "positive integer")
  expect_error(render_heightmap("test.png", z, width = 1.5), "positive integer")
  
  # Invalid scale_z
  expect_error(render_heightmap("test.png", z, scale_z = -1), "positive number")
  expect_error(render_heightmap("test.png", z, scale_z = c(1, 2)), "positive number")
  
  # Invalid fov_deg
  expect_error(render_heightmap("test.png", z, fov_deg = 0), "between 0 and 180")
  expect_error(render_heightmap("test.png", z, fov_deg = 180), "between 0 and 180")
  expect_error(render_heightmap("test.png", z, fov_deg = c(35, 45)), "between 0 and 180")
  
  # Invalid sun_dir
  expect_error(render_heightmap("test.png", z, sun_dir = c(1, 2)), "length 3")
  expect_error(render_heightmap("test.png", z, sun_dir = "not numeric"), "length 3")
})