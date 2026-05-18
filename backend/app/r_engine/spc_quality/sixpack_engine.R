# backend/app/r_engine/spc_quality/sixpack_engine.R

#' Calculate Statistical Process Control and Capability Sixpack Metrics
#'
#' This function implements the exact Minitab statistical formulas as specified in the playbook.
#' It calculates process capability (Cp, Cpk, Pp, Ppk), control limits,
#' and checks for Nelson/Western Electric rules.
#'
#' @param x Numeric vector of raw data
#' @param usl Upper Specification Limit (optional)
#' @param lsl Lower Specification Limit (optional)
#' @param n Subgroup size (default = 1)
#' @return A flat, named list containing raw data, control limits, capability indices, and test violations.
calculate_capability_sixpack <- function(x, usl = NA, lsl = NA, n = 1) {
  
  # Vorabprüfung und Typkonvertierung gemäß Minitab RAG Knowledge Base
  tryCatch({
    x <- as.numeric(as.character(x))
  }, warning = function(w) {
    stop("Input x contains non-numeric values that cannot be converted.")
  })
  
  # Remove NAs for calculation
  x_valid <- x[!is.na(x)]
  total_n <- length(x_valid)
  
  if (total_n < 2) {
    stop("Ungenügende Datenmenge für Within-Sigma-Schätzung. Minimum 2 Datenpunkte erforderlich.")
  }
  
  x_bar <- mean(x_valid)
  
  # --- 1. Overall Performance ---
  # Schätzung über die empirische Standardabweichung mit Freiheitsgrad n-1
  sigma_overall <- sd(x_valid)
  
  # --- 2. Potential Capability ---
  if (n == 1) {
    # n = 1: Moving Range von 2 aufeinanderfolgenden Werten
    mr <- abs(diff(x_valid))
    mr_bar <- mean(mr)
    d2 <- 1.128
    sigma_within <- mr_bar / d2
    
    # Control Limits for Individual Chart
    ucl <- x_bar + 3 * sigma_within
    lcl <- x_bar - 3 * sigma_within
    
  } else {
    # n > 1: Pooled Standard Deviation
    k <- floor(total_n / n)
    if (k < 1) {
      stop("Not enough data for the specified subgroup size.")
    }
    
    x_matrix <- matrix(x_valid[1:(k * n)], nrow = n)
    group_vars <- apply(x_matrix, 2, var)
    
    s_p <- sqrt(mean(group_vars))
    df_total <- k * (n - 1)
    
    # Approximation of c4 based on degrees of freedom (d+1)
    c4 <- function(df) {
      if (df > 100) return(1)
      sqrt(2 / df) * exp(lgamma((df + 1) / 2) - lgamma(df / 2))
    }
    
    sigma_within <- s_p / c4(df_total)
    
    # Control Limits for X-bar Chart
    ucl <- x_bar + 3 * (sigma_within / sqrt(n))
    lcl <- x_bar - 3 * (sigma_within / sqrt(n))
  }
  
  # --- 3. Capability Indices (Cp, Cpk, Pp, Ppk) ---
  cp <- NA
  cpk <- NA
  pp <- NA
  ppk <- NA
  
  if (!is.na(usl) && !is.na(lsl)) {
    cp <- (usl - lsl) / (6 * sigma_within)
    pp <- (usl - lsl) / (6 * sigma_overall)
  }
  
  cpk_u <- if(!is.na(usl)) (usl - x_bar) / (3 * sigma_within) else NA
  cpk_l <- if(!is.na(lsl)) (x_bar - lsl) / (3 * sigma_within) else NA
  if (!is.na(usl) || !is.na(lsl)) {
    cpk <- min(cpk_u, cpk_l, na.rm = TRUE)
  }
  
  ppk_u <- if(!is.na(usl)) (usl - x_bar) / (3 * sigma_overall) else NA
  ppk_l <- if(!is.na(lsl)) (x_bar - lsl) / (3 * sigma_overall) else NA
  if (!is.na(usl) || !is.na(lsl)) {
    ppk <- min(ppk_u, ppk_l, na.rm = TRUE)
  }
  
  # --- 4. Regelkarten & Stabilitäts-Tests (Nelson / Western Electric Rules) ---
  
  # Test 1: Ein Punkt liegt weiter als 3 Standardabweichungen von der Mittellinie entfernt (> UCL oder < LCL)
  test1_violations <- which(x_valid > ucl | x_valid < lcl)
  
  # Test 2: 9 aufeinanderfolgende Punkte liegen auf derselben Seite der Mittellinie.
  test2_violations <- c()
  runs_greater <- rle(sign(x_valid - x_bar))
  e_idx <- cumsum(runs_greater$lengths)
  s_idx <- c(1, e_idx[-length(e_idx)] + 1)
  
  for (i in seq_along(runs_greater$lengths)) {
    if (runs_greater$values[i] != 0 && runs_greater$lengths[i] >= 9) {
      test2_violations <- c(test2_violations, (s_idx[i] + 8):e_idx[i])
    }
  }
  
  # Test 3: 6 aufeinanderfolgende Punkte steigen oder fallen kontinuierlich.
  test3_violations <- c()
  runs_t3 <- rle(sign(diff(x_valid)))
  e_idx_diff <- cumsum(runs_t3$lengths)
  s_idx_diff <- c(1, e_idx_diff[-length(e_idx_diff)] + 1)
  
  for (i in seq_along(runs_t3$lengths)) {
    if (runs_t3$values[i] != 0 && runs_t3$lengths[i] >= 5) { # 5 steps (differences) = 6 points
      test3_violations <- c(test3_violations, (s_idx_diff[i] + 5):(e_idx_diff[i] + 1))
    }
  }
  
  # --- 5. Anderson-Darling P-Werte ---
  ad_pvalue <- NA
  test_used <- "None"
  
  if (sigma_overall > 0) {
    if (total_n > 7) {
      if (requireNamespace("nortest", quietly = TRUE)) {
        tryCatch({
          ad_test <- nortest::ad.test(x_valid)
          ad_pvalue <- ad_test$p.value
          test_used <- "Anderson-Darling"
        }, error = function(e) {
          ad_pvalue <- NA
        })
      }
    } else {
      # Fallback auf Shapiro-Wilk bei n <= 7, da AD Test n > 7 benötigt
      tryCatch({
        sw_test <- shapiro.test(x_valid)
        ad_pvalue <- sw_test$p.value
        test_used <- "Shapiro-Wilk (n <= 7 fallback)"
      }, error = function(e) {
        ad_pvalue <- NA
      })
    }
  }
  
  # --- Return structured flat list ---
  return(list(
    raw_data = x,
    center_line = x_bar,
    ucl = ucl,
    lcl = lcl,
    sigma_within = sigma_within,
    sigma_overall = sigma_overall,
    cp = cp,
    cpk = cpk,
    pp = pp,
    ppk = ppk,
    test1_violations = as.integer(test1_violations),
    test2_violations = as.integer(test2_violations),
    test3_violations = as.integer(test3_violations),
    anderson_darling_pvalue = ad_pvalue,
    normality_test_used = test_used
  ))
}
