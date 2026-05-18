# backend/app/r_engine/linear_models/anova_regression.R

#' Calculate Descriptive Statistics
#'
#' @param x Numeric vector
#' @return List of descriptive statistics
calculate_descriptive_stats <- function(x) {
  if (!requireNamespace("e1071", quietly = TRUE)) {
    stop("Package 'e1071' is required but not installed.")
  }
  
  # Listwise deletion for NA values
  x_clean <- as.numeric(na.omit(x))
  
  if (length(x_clean) == 0) {
    stop("Input vector contains no non-NA values.")
  }
  
  res <- list(
    mean = mean(x_clean),
    median = median(x_clean),
    variance = var(x_clean),
    sd = sd(x_clean),
    q1 = unname(quantile(x_clean, probs = 0.25, type = 6, na.rm = TRUE)),
    q3 = unname(quantile(x_clean, probs = 0.75, type = 6, na.rm = TRUE)),
    skewness = e1071::skewness(x_clean, type = 2),
    kurtosis = e1071::kurtosis(x_clean, type = 2)
  )
  
  return(res)
}

#' Execute GLM ANOVA
#'
#' @param formula Formula object
#' @param data Data frame
#' @return ANOVA table
execute_glm_anova <- function(formula, data) {
  if (!requireNamespace("car", quietly = TRUE)) {
    stop("Package 'car' is required but not installed.")
  }
  
  # Listwise deletion for NA values
  data_clean <- na.omit(data[, all.vars(formula), drop = FALSE])
  
  if (nrow(data_clean) == 0) {
    stop("Data contains no complete cases.")
  }
  
  # Ensure Minitab alignment for contrasts
  old_options <- options(contrasts = c("contr.sum", "contr.poly"))
  on.exit(options(old_options))
  
  model <- lm(formula, data = data_clean)
  anova_res <- car::Anova(model, type = "III")
  
  return(anova_res)
}

#' Execute Stepwise Regression
#'
#' @param formula Formula object
#' @param data Data frame
#' @param direction Character: "both", "backward", or "forward"
#' @param alpha_enter Numeric: Alpha to enter (Default: 0.15)
#' @param alpha_remove Numeric: Alpha to remove (Default: 0.15)
#' @return Stepwise regression model
execute_stepwise_regression <- function(formula, data, direction = "both", alpha_enter = 0.15, alpha_remove = 0.15) {
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Package 'MASS' is required but not installed.")
  }
  
  # Listwise deletion for NA values
  data_clean <- na.omit(data[, all.vars(formula), drop = FALSE])
  
  if (nrow(data_clean) == 0) {
    stop("Data contains no complete cases.")
  }
  
  full_model <- lm(formula, data = data_clean)
  null_model <- lm(update(formula, . ~ 1), data = data_clean)
  
  current_model <- if (direction == "forward") null_model else full_model
  
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    
    if (direction %in% c("both", "backward") && length(attr(terms(current_model), "term.labels")) > 0) {
      drop_tests <- drop1(current_model, test = "F")
      p_vals <- drop_tests$`Pr(>F)`[-1]
      terms_to_drop <- rownames(drop_tests)[-1]
      
      if (length(p_vals) > 0) {
        max_p <- max(p_vals, na.rm = TRUE)
        if (max_p > alpha_remove) {
          term_to_remove <- terms_to_drop[which.max(p_vals)]
          current_model <- update(current_model, paste(". ~ . -", term_to_remove))
          changed <- TRUE
          next
        }
      }
    }
    
    if (direction %in% c("both", "forward")) {
      add_tests <- add1(current_model, scope = full_model, test = "F")
      p_vals <- add_tests$`Pr(>F)`[-1]
      terms_to_add <- rownames(add_tests)[-1]
      
      if (length(p_vals) > 0) {
        min_p <- min(p_vals, na.rm = TRUE)
        if (min_p < alpha_enter) {
          term_to_add <- terms_to_add[which.min(p_vals)]
          current_model <- update(current_model, paste(". ~ . +", term_to_add))
          changed <- TRUE
          next
        }
      }
    }
  }
  
  return(current_model)
}

#' Execute Hypotheses Tests
#'
#' @param x Numeric vector (Group 1 or Data)
#' @param y Numeric vector (Group 2, optional)
#' @param test_type Character: "t", "F", "levene", "bartlett", "wilcoxon", "mann-whitney", "kruskal-wallis"
#' @param group Factor vector for multi-group tests
#' @return Test results
execute_hypotheses_tests <- function(x, y = NULL, test_type = "t", group = NULL) {
  if (!requireNamespace("car", quietly = TRUE)) {
    stop("Package 'car' is required but not installed.")
  }
  
  # Listwise deletion
  if (!is.null(y)) {
    if (length(x) == length(y)) {
      valid_idx <- complete.cases(x, y)
      x <- x[valid_idx]
      y <- y[valid_idx]
    } else {
      x <- na.omit(x)
      y <- na.omit(y)
    }
  } else if (!is.null(group)) {
    valid_idx <- complete.cases(x, group)
    x <- x[valid_idx]
    group <- group[valid_idx]
  } else {
    x <- na.omit(x)
  }
  
  if (length(x) == 0) {
    stop("No complete cases remaining after NA removal.")
  }
  
  res <- list()
  
  if (test_type == "t") {
    if (is.null(y)) {
      res <- t.test(x)
    } else {
      res <- t.test(x, y)
    }
  } else if (test_type == "F") {
    if (is.null(y)) {
      stop("F-test requires two samples.")
    }
    res <- var.test(x, y)
  } else if (test_type == "levene") {
    if (is.null(group)) {
      stop("Levene's test requires a grouping variable.")
    }
    res <- car::leveneTest(y = x, group = as.factor(group))
  } else if (test_type == "bartlett") {
    if (is.null(group)) {
      stop("Bartlett's test requires a grouping variable.")
    }
    res <- bartlett.test(x, as.factor(group))
  } else if (test_type == "wilcoxon") {
    if (is.null(y)) {
      res <- wilcox.test(x)
    } else {
      res <- wilcox.test(x, y, paired = TRUE)
    }
  } else if (test_type == "mann-whitney") {
    if (is.null(y)) {
      stop("Mann-Whitney test requires two samples.")
    }
    res <- wilcox.test(x, y, paired = FALSE)
  } else if (test_type == "kruskal-wallis") {
    if (is.null(group)) {
      stop("Kruskal-Wallis test requires a grouping variable.")
    }
    res <- kruskal.test(x, as.factor(group))
  } else {
    stop("Unknown test type specified.")
  }
  
  return(res)
}
