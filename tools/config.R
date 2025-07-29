# Note: Any variables prefixed with `.` are used for text
# replacement in the Makevars.in and Makevars.win.in

# check the packages MSRV first
source("tools/msrv.R")

# check DEBUG and NOT_CRAN environment variables
env_debug <- Sys.getenv("DEBUG")
env_not_cran <- Sys.getenv("NOT_CRAN")

# check if the vendored zip file exists
vendor_exists <- file.exists("src/rust/vendor.tar.xz")

is_not_cran <- env_not_cran != ""
is_debug <- env_debug != ""

if (is_debug) {
  # if we have DEBUG then we set not cran to true
  # CRAN is always release build
  is_not_cran <- TRUE
  message("Creating DEBUG build.")
}

if (!is_not_cran) {
  message("Building for CRAN.")
}

# we set cran flags only if NOT_CRAN is empty and if
# the vendored crates are present.
.cran_flags <- ifelse(
  !is_not_cran && vendor_exists,
  "-j 2 --offline",
  ""
)

# when DEBUG env var is present we use `--debug` build
.profile <- ifelse(is_debug, "", "--release")
.clean_targets <- ifelse(is_debug, "", "$(TARGET_DIR)")

# We specify this target when building for webR
webr_target <- "wasm32-unknown-emscripten"

# here we check if the platform we are building for is webr
is_wasm <- identical(R.version$platform, webr_target)

# print to terminal to inform we are building for webr
if (is_wasm) {
  message("Building for WebR")
}

# we check if we are making a debug build or not
# if so, the LIBDIR environment variable becomes:
# LIBDIR = $(TARGET_DIR)/{wasm32-unknown-emscripten}/debug
# this will be used to fill out the LIBDIR env var for Makevars.in
target_libpath <- if (is_wasm) "wasm32-unknown-emscripten" else NULL
cfg <- if (is_debug) "debug" else "release"

# used to replace @LIBDIR@
.libdir <- paste(c(target_libpath, cfg), collapse = "/")

# use this to replace @TARGET@
# we specify the target _only_ on webR
# there may be use cases later where this can be adapted or expanded
.target <- ifelse(is_wasm, paste0("--target=", webr_target), "")

# read in the Makevars.in file checking
is_windows <- .Platform[["OS.type"]] == "windows"

# if windows we replace in the Makevars.win.in
mv_fp <- ifelse(
  is_windows,
  "src/Makevars.win.in",
  "src/Makevars.in"
)

# set the output file
mv_ofp <- ifelse(
  is_windows,
  "src/Makevars.win",
  "src/Makevars"
)

# delete the existing Makevars{.win}
if (file.exists(mv_ofp)) {
  message("Cleaning previous `", mv_ofp, "`.")
  invisible(file.remove(mv_ofp))
}

# read as a single string
mv_txt <- readLines(mv_fp)

# replace placeholder values
new_txt <- gsub("@CRAN_FLAGS@", .cran_flags, mv_txt) |>
  gsub("@PROFILE@", .profile, x = _) |>
  gsub("@CLEAN_TARGET@", .clean_targets, x = _) |>
  gsub("@LIBDIR@", .libdir, x = _) |>
  gsub("@TARGET@", .target, x = _)

message("Writing `", mv_ofp, "`.")
con <- file(mv_ofp, open = "wb")
writeLines(new_txt, con, sep = "\n")
close(con)

# Patch Makevars.win to ensure GL/GDI libraries are linked
# This fixes WGL undefined symbol errors from wgpu-hal GL backend
patch_makevars_win <- function(path) {
  if (!file.exists(path)) return(invisible())

  lines <- readLines(path, warn = FALSE)

  has_opengl <- any(grepl("\\-lopengl32\\b", lines))
  has_gdi32  <- any(grepl("\\-lgdi32\\b", lines))

  # Only patch if both libraries are missing
  if (has_opengl && has_gdi32) return(invisible())

  # Find PKG_LIBS line to patch
  idx <- grep("^\\s*PKG_LIBS\\s*=", lines)
  if (length(idx) == 0L) {
    # No PKG_LIBS yet — add one that appends to itself to be safe in future merges
    lines <- c(lines, 'PKG_LIBS = $(PKG_LIBS) -lgdi32 -lopengl32')
  } else {
    # Patch the existing line to include missing libs exactly once
    lib_line <- lines[idx[1]]
    if (!has_gdi32)  lib_line <- paste(lib_line, "-lgdi32")
    if (!has_opengl) lib_line <- paste(lib_line, "-lopengl32")
    # Clean up whitespace
    lib_line <- gsub("\\s+", " ", lib_line)
    lines[idx[1]] <- lib_line
  }

  writeLines(lines, path, useBytes = TRUE)
  message("Patched `", path, "` to include GL/GDI libraries for WGL symbols.")
}

# Apply patch to the Makevars.win we just wrote
if (is_windows) {
  patch_makevars_win(mv_ofp)
}

message("`tools/config.R` has finished.")
