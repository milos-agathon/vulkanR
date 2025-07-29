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
  if (!is.character(path) || length(path) != 1) stop("`path` must be a single character string", call. = FALSE)
  if (!is.matrix(z) || !is.numeric(z)) stop("z must be a numeric matrix", call. = FALSE)
  if (any(!is.finite(z))) stop("z contains non-finite values (Inf/NA/NaN)", call. = FALSE)
  if (nrow(z) < 2 || ncol(z) < 2) stop("z must be at least 2x2", call. = FALSE)
  width  <- as.integer(width);  if (length(width) != 1L || is.na(width)  || width  <= 0L) stop("width must be a positive integer",  call. = FALSE)
  height <- as.integer(height); if (length(height) != 1L || is.na(height) || height <= 0L) stop("height must be a positive integer", call. = FALSE)
  if (!is.numeric(scale_z) || length(scale_z) != 1 || scale_z <= 0) stop("scale_z must be a positive number", call. = FALSE)
  if (!is.numeric(fov_deg) || length(fov_deg) != 1 || fov_deg <= 0 || fov_deg >= 180) stop("fov_deg must be between 0 and 180", call. = FALSE)
  if (!is.numeric(sun_dir) || length(sun_dir) != 3) stop("sun_dir must be a numeric vector of length 3", call. = FALSE)

  # Call the native symbol directly. The Rust function signature expects 7 args.
  res <- .Call("wrap__render_heightmap",
               path, z, width, height, as.numeric(scale_z),
               as.numeric(fov_deg), as.numeric(sun_dir),
               PACKAGE = "vulkanR")

  if (inherits(res, "extendr_result") && !is.null(res$err)) {
    stop("Render failed: ", res$err, call. = FALSE)
  }
  invisible(TRUE)
}