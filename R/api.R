#' Get GPU Information
#'
#' Returns information about the available GPU backend and device.
#'
#' @return A character string containing GPU backend and device information.
#' @export
#' @examples
#' \dontrun{
#' gpu_info()
#' }
gpu_info <- function() {
  out <- .Call("wrap__gpu_info", PACKAGE = "vulkanR")
  if (inherits(out, "extendr_result")) {
    if (!is.null(out$err)) stop("GPU info failed: ", out$err, call. = FALSE)
    return(out$ok)
  }
  out
}

#' Render Heightmap to PNG
#'
#' Renders a heightmap as a 3D mesh to a PNG file using GPU acceleration.
#'
#' @param path Character string. Output PNG file path.
#' @param z Numeric matrix. Height values in column-major order.
#' @param width Integer. Output image width in pixels (default: 64L).
#' @param height Integer. Output image height in pixels (default: 64L).
#' @param scale_z Numeric. Vertical scaling factor for heights (default: 1.0).
#' @param fov_deg Numeric. Field of view in degrees (default: 35).
#' @param sun_dir Numeric vector of length 3. Sun direction for lighting (default: c(0.6, 0.7, 0.4)).
#' @param colormap Character string. The colormap to use. One of "gray", "terrain", "viridis", "turbo".
#' @param color_range Numeric vector of length 2. The range of z values to map to the colormap. If NULL, the range is computed from the data.
#'
#' @return Invisibly returns a `vulkanr_result` object on success.
#' @export
#' @examples
#' \dontrun{
#' # Create a simple heightmap
#' z <- outer(0:31, 0:31, function(i, j) sin(i / 6) + cos(j / 7))
#'
#' # Render to PNG
#' render_heightmap("heightmap.png", z,
#'   width = 64L, height = 64L,
#'   scale_z = 1.0, fov_deg = 35,
#'   sun_dir = c(0.6, 0.7, 0.4)
#' )
#' }
.validate_inputs <- function(z, width, height, sun_dir, color_range) {
  if (!(is.matrix(z) && is.numeric(z))) {
    .vkr_stop("`z` must be a numeric matrix", "vkr_input")
  }
  if (any(!is.finite(z))) {
    .vkr_stop("`z` contains NA/Inf; please clean input", "vkr_input")
  }
  # width/height: positive integers
  if (length(width) != 1L || length(height) != 1L ||
      !is.finite(width) || !is.finite(height) ||
      width <= 0 || height <= 0 ||
      width != as.integer(width) || height != as.integer(height)) {
    .vkr_stop("`width`/`height` must be positive integers", "vkr_input")
  }
  # MVP: require dims to match; no resampling yet
  if (nrow(z) != height || ncol(z) != width) {
    .vkr_stop(sprintf("`z` dims %dx%d must match width=%d height=%d (no resampling in MVP)",
                      nrow(z), ncol(z), width, height), "vkr_input")
  }
  # sun_dir: length-3 finite numeric
  if (!(is.numeric(sun_dir) && length(sun_dir) == 3L && all(is.finite(sun_dir)))) {
    .vkr_stop("`sun_dir` must be numeric length-3 (finite)", "vkr_input")
  }
  # color_range: NULL or length-2 ascending numeric
  if (!is.null(color_range)) {
    if (!(is.numeric(color_range) && length(color_range) == 2L &&
          all(is.finite(color_range)) && color_range[1] < color_range[2])) {
      .vkr_stop("`color_range` must be length-2 ascending numeric if provided", "vkr_input")
    }
  }
  invisible(TRUE)
}

render_heightmap <- function(path, z,
                             width = 64L, height = 64L,
                             scale_z = 1.0, fov_deg = 35,
                             sun_dir = c(0.6, 0.7, 0.4),
                             colormap = c("gray","terrain","viridis","turbo")[1],
                             color_range = NULL) {
  .validate_inputs(z, width, height, sun_dir, color_range)

  # call into FFI with tryCatch -> map extendr_error to classed errors
  tryCatch(
    .Call("wrap__render_heightmap", path, z, as.integer(width), as.integer(height),
          as.numeric(scale_z), as.numeric(fov_deg), as.numeric(sun_dir),
          PACKAGE = "vulkanR"),
    error = function(e) {
      if (inherits(e, "extendr_error")) .handle_extendr_err(e) else stop(e)
    }
  )
  invisible(structure(list(path = normalizePath(path, mustWork=TRUE),
                           width = width, height = height),
                      class = "vulkanr_result"))
}