#' Compute mean absolute difference between two PNG images
#' @param img1_path Path to first PNG image
#' @param img2_path Path to second PNG image  
#' @return Mean absolute difference across all channels, or Inf if images differ in dimensions
compute_image_diff <- function(img1_path, img2_path) {
  if (!file.exists(img1_path) || !file.exists(img2_path)) {
    return(Inf)
  }
  
  img1 <- png::readPNG(img1_path)
  img2 <- png::readPNG(img2_path)
  
  # Check dimensions
  if (!identical(dim(img1), dim(img2))) {
    return(Inf)
  }
  
  # Compute mean absolute difference
  diff <- abs(img1 - img2)
  mean(diff) * 255  # Scale to 0-255 range
}

#' Write reference PNG from embedded base64 if file doesn't exist
#' @param png_path Path where PNG should be written
#' @param base64_data Base64 encoded PNG data
write_reference_png_if_missing <- function(png_path, base64_data) {
  if (!file.exists(png_path)) {
    png_data <- base64enc::base64decode(base64_data)
    writeBin(png_data, png_path)
  }
}