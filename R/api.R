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
  res <- tryCatch(
    .Call("wrap__gpu_info", PACKAGE = "vulkanR"),
    error = .handle_extendr_err
  )
  if (inherits(res, "extendr_result")) {
    if (!is.null(res$err)) .handle_extendr_err(simpleError(res$err))
    return(res$ok)
  }
  res
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
#'
#' @return Invisibly returns TRUE on success.
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
render_heightmap <- function(path, z, width = 64L, height = 64L,
                             scale_z = 1.0, fov_deg = 35,
                             sun_dir = c(0.6, 0.7, 0.4)) {
  # Input validation - path validation must come first and include exact phrase expected by tests
  if (!is.character(path) || length(path) != 1) {
    .vkr_stop("`path` must be a single character string", "vkr_input")
  }
  if (!(is.matrix(z) && is.numeric(z))) {
    .vkr_stop("z must be a numeric matrix", "vkr_input")
  }
  if (any(!is.finite(z))) .vkr_stop("z contains non-finite values (Inf/NA/NaN)", "vkr_input")
  if (nrow(z) < 2 || ncol(z) < 2) .vkr_stop("z must be at least 2x2", "vkr_input")
  width  <- as.integer(width)
  if (length(width) != 1L || is.na(width) || width <= 0L) {
    .vkr_stop("width must be a positive integer", "vkr_input")
  }
  height <- as.integer(height)
  if (length(height) != 1L || is.na(height) || height <= 0L) {
    .vkr_stop("height must be a positive integer", "vkr_input")
  }
  if (!is.numeric(scale_z) || length(scale_z) != 1 || scale_z <= 0) {
    .vkr_stop("scale_z must be a positive number", "vkr_input")
  }
  if (!is.numeric(fov_deg) || length(fov_deg) != 1 || fov_deg <= 0 || fov_deg >= 180) {
    .vkr_stop("fov_deg must be between 0 and 180", "vkr_input")
  }
  if (!is.numeric(sun_dir) || length(sun_dir) != 3) {
    .vkr_stop("sun_dir must be a numeric vector of length 3", "vkr_input")
  }

  # Call the native symbol directly. The Rust function signature expects 7 args.
  res <- tryCatch(
    .Call("wrap__render_heightmap",
          path, z, width, height, as.numeric(scale_z),
          as.numeric(fov_deg), as.numeric(sun_dir),
          PACKAGE = "vulkanR"),
    error = .handle_extendr_err
  )

  if (inherits(res, "extendr_result") && !is.null(res$err)) {
    .handle_extendr_err(simpleError(res$err))
  }
  invisible(TRUE)
}