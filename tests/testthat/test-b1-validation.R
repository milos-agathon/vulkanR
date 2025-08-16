test_that("input validation rejects bad shapes and values", {
  z <- matrix(runif(4L*3L), 4L, 3L)
  expect_error(
    render_heightmap(tempfile(fileext=".png"), z, width=4L, height=3L),
    class = "vkr_input"
  )
  z_bad <- z; z_bad[1,1] <- NA_real_
  expect_error(render_heightmap(tempfile(fileext=".png"), z_bad, width=3L, height=4L),
               class = "vkr_input")
  expect_error(render_heightmap(tempfile(fileext=".png"), z, width=0L, height=4L),
               class = "vkr_input")
  expect_error(render_heightmap(tempfile(fileext=".png"), z, width=3L, height=4L, sun_dir=c(1,2)),
               class = "vkr_input")
})

test_that("capability limit and VRAM budget are enforced", {
  # This test assumes caps are typical (e.g., 4096 or 8192). Probe via gpu_info() string.
  info <- gpu_info()
  mt <- as.integer(sub(".*max_tex_2d: ([0-9]+).*", "\\1", info))
  big <- mt + 1L
  z <- matrix(runif(big * big), big, big)

  expect_error(
    render_heightmap(tempfile(fileext=".png"), z, width=big, height=big),
    class = "vkr_caps"
  )

  # Budget test: force a tiny budget so even moderate sizes fail
  withr::with_envvar(c(VULKANR_VRAM_BUDGET_MB="1"), {
    w <- 2048L; h <- 2048L
    z2 <- matrix(runif(w*h), h, w)
    expect_error(
      render_heightmap(tempfile(fileext=".png"), z2, width=w, height=h),
      class = "vkr_oom"
    )
  })
})
