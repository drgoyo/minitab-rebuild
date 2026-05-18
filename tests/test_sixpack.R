# tests/test_sixpack.R

if (!require("testthat", quietly = TRUE)) {
  stop("Package 'testthat' is missing. Please install it to run unit tests.")
}

if (!require("nortest", quietly = TRUE)) {
  stop("Package 'nortest' is missing. Please install it as it is required by the engine.")
}

source("backend/app/r_engine/spc_quality/sixpack_engine.R")

test_that("Deterministic alignment of SPC Capability Sixpack with Minitab reference data", {
  
  x_ref <- c(22.4, 22.7, 22.5, 22.8, 22.6, 22.4, 22.3, 22.6, 22.5, 22.7)
  lsl_ref <- 22.0
  usl_ref <- 23.0
  
  result <- calculate_capability_sixpack(x = x_ref, usl = usl_ref, lsl = lsl_ref, n = 1)
  
  expect_equal(result$center_line, 22.55, tolerance = 0.005)
  expect_equal(result$sigma_overall, 0.1581139, tolerance = 0.005)
  expect_equal(result$sigma_within, 0.1772955, tolerance = 0.005)
  expect_equal(result$cp, 0.9399833, tolerance = 0.005)
  expect_equal(result$pp, 1.054093, tolerance = 0.005)
  
})
