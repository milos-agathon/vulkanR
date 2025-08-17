test_that("non-matrix z is rejected", {
  tmp <- tempfile(fileext = ".png")
  cond <- tryCatch(render_heightmap(tmp, 1, 64L, 64L), error = function(e) e)
  expect_true(inherits(cond, "vkr_input"))
})

test_that("non-numeric matrix is rejected", {
  tmp <- tempfile(fileext = ".png")
  m <- matrix("a", 2, 2)
  cond <- tryCatch(render_heightmap(tmp, m, 64L, 64L), error = function(e) e)
  expect_true(inherits(cond, "vkr_input"))
})

test_that("non-finite values are rejected", {
  tmp <- tempfile(fileext = ".png")
  m <- matrix(c(1, NA, 3, 4), 2, 2)
  cond <- tryCatch(render_heightmap(tmp, m, 64L, 64L), error = function(e) e)
  expect_true(inherits(cond, "vkr_input"))
})

test_that("non-positive dimensions are rejected", {
  tmp <- matrix(0, 2, 2)
  cond <- tryCatch(render_heightmap(tempfile(fileext = ".png"), tmp, 0L, 64L), error = function(e) e)
  expect_true(inherits(cond, "vkr_input"))
  cond <- tryCatch(render_heightmap(tempfile(fileext = ".png"), tmp, 64L, -1L), error = function(e) e)
  expect_true(inherits(cond, "vkr_input"))
})
