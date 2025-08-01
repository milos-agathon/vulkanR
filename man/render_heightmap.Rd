% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api.R, R/extendr-wrappers.R
\name{render_heightmap}
\alias{render_heightmap}
\title{Render Heightmap to PNG}
\usage{
render_heightmap(path, z, width, height, scale_z, fov_deg, sun_dir)

render_heightmap(path, z, width, height, scale_z, fov_deg, sun_dir)
}
\arguments{
\item{path}{Character string. Output PNG file path.}

\item{z}{Numeric matrix. Height values in column-major order.}

\item{width}{Integer. Output image width in pixels (default: 64L).}

\item{height}{Integer. Output image height in pixels (default: 64L).}

\item{scale_z}{Numeric. Vertical scaling factor for heights (default: 1.0).}

\item{fov_deg}{Numeric. Field of view in degrees (default: 35).}

\item{sun_dir}{Numeric vector of length 3. Sun direction for lighting (default: c(0.6, 0.7, 0.4)).}
}
\value{
Invisibly returns TRUE on success.
}
\description{
Renders a heightmap as a 3D mesh to a PNG file using GPU acceleration.
}
\examples{
\dontrun{
# Create a simple heightmap
z <- outer(0:31, 0:31, function(i, j) sin(i / 6) + cos(j / 7))

# Render to PNG
render_heightmap("heightmap.png", z,
  width = 64L, height = 64L,
  scale_z = 1.0, fov_deg = 35,
  sun_dir = c(0.6, 0.7, 0.4)
)
}
}
