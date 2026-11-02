# Direct comparisons of the original M1 coefficients; base R only.
# Run from the repository root. No pooled model or saved estimates required.
source("analysis/R/00_setup.R")

con <- file(file.path(DIR_LOG, "20_m1_direct_contrasts.log"), "wt")
sink(con, split = TRUE)

cues <- c("brand", "rep", "pop")
datasets <- setNames(lapply(cues, function(f) read_orig(paste0("M1_", f, ".csv"))), cues)
pairs <- combn(cues, 2, simplify = FALSE)
for (d in datasets) stopifnot(!anyNA(d$lfdn), !anyDuplicated(d$lfdn))
for (p in pairs) stopifnot(length(intersect(datasets[[p[1]]]$lfdn,
                                           datasets[[p[2]]]$lfdn)) == 0L)

models <- setNames(lapply(cues, function(f) {
  form <- as.formula(paste0("y_", f, "_1 ~ x_", f,
                           " * (inv_app_mc + inv_dl_mc + inv_cat_mc)"))
  lm(form, data = datasets[[f]], na.action = na.fail)
}), cues)

out <- do.call(rbind, lapply(pairs, function(p) {
  a <- coef(summary(models[[p[1]]]))[paste0("x_", p[1]), ]
  b <- coef(summary(models[[p[2]]]))[paste0("x_", p[2]), ]
  v1 <- unname(a[2]^2); v2 <- unname(b[2]^2)
  se <- sqrt(v1 + v2)
  estimate <- unname(a[1] - b[1])
  # Independent estimates: covariance = 0. Welch-Satterthwaite approximation
  # using each regression's residual df; retains the original OLS assumptions.
  df <- (v1 + v2)^2 / (v1^2 / df.residual(models[[p[1]]]) +
                        v2^2 / df.residual(models[[p[2]]]))
  data.frame(contrast = paste(p, collapse = " - "), estimate = estimate,
             se = se, df = df, statistic = estimate / se,
             ci95_unadjusted_low = estimate - qt(.975, df) * se,
             ci95_unadjusted_high = estimate + qt(.975, df) * se,
             p_value = 2 * pt(-abs(estimate / se), df))
}))
out$p_holm <- p.adjust(out$p_value, method = "holm")

cat("=== DIRECT CONTRASTS BETWEEN THE ORIGINAL M1 REGRESSIONS ===\n")
cat("All three respondent samples are disjoint; no missing model values.\n")
cat("Estimand: difference between high-minus-low cue effects at zero on all\n")
cat("three centred involvement covariates (the original reference values).\n")
cat("These are conditional effects, not automatically population-average effects.\n")
cat("Two-sided tests; Welch-Satterthwaite df; Holm across all three pairs.\n")
cat("95% intervals are pointwise, NOT multiplicity-adjusted.\n\n")
print(out, digits = 6, row.names = FALSE)
cat("\nA missing test, not an impossible comparison: separate M1 models suffice.\n")
cat("Do not apply the independence formula to M3: its samples overlap.\n")
cat("Pooled models remain useful, but impose different sharing assumptions.\n")
write.csv(out, file.path(DIR_TAB, "20_m1_direct_contrasts.csv"), row.names = FALSE)
sink(); close(con)
