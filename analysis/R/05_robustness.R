# 05_robustness.R ------------------------------------------------------------
# Robustness checks the 2023 work does not contain:
#   D.1 restricting to respondents who ticked the matching box on slide 6
#   D.2 ordinal logit model (the dependent variable is a 1-7 Likert)
#   D.3 multiplicity correction over the 9 original regressions
#   D.4 power analysis: what effect was detectable? (relevant to the claim
#       "no interaction between focal variables")
#   D.5 involvement moderation estimated on a single pooled model
#
# Output: analysis/outputs/tables/05_*.csv, analysis/outputs/logs/05_robustness.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4)
  library(emmeans)
  library(ordinal)
})

con <- file(file.path(DIR_LOG, "05_robustness.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
long$comp_f   <- factor(long$comp, levels = c(0, 1), labels = c("shown_first", "after_others"))

fit_pool <- function(d) {
  lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
       data = d, REML = FALSE)
}
eff_by_focal <- function(m, tag) {
  e <- as.data.frame(summary(contrast(emmeans(m, ~ x_f | focal), "revpairwise"),
                             infer = c(TRUE, TRUE)))
  e$sample <- tag
  e[, c("sample", "focal", "estimate", "SE", "lower.CL", "upper.CL", "p.value")]
}

cat("=== D.1 ROBUSTNESS TO THE SLIDE-6 CHECK ===\n\n")
cat("The thesis reports the tick rates in Table 3.2 but never uses them. For\n")
cat("popularity the rate is 60.5% overall and 55.9% in the M2 subsample, not\n")
cat("distinguishable from the 50% expected by chance (p = 0.18).\n")
cat("CAUTION: slide 6 is not a perception check. It is a single multiple-choice\n")
cat("question asked at the end about which cues the respondent SAYS they used, so\n")
cat("it is post-treatment and plausibly affected by the treatment itself.\n")
cat("What follows describes how fragile the popularity null is; it does not\n")
cat("overturn it. See docs/01-review-of-2023-work.md section 3.3.\n\n")

cat("Observations by check outcome:\n")
print(table(focal = long$focal, box_ticked = long$manip_ok))

m_all   <- fit_pool(long)
m_ok    <- fit_pool(long[long$manip_ok == 1, ])
subj_ok <- names(which(tapply(long$manip_ok, long$subject, sum) == 3))
m_ok3   <- fit_pool(long[long$subject %in% as.integer(subj_ok), ])

cat("\nSubjects ticking all three boxes:", length(subj_ok), "of 491\n\n")

rob <- rbind(
  eff_by_focal(m_all, "all observations (N=1473)"),
  eff_by_focal(m_ok,  sprintf("box ticked only (N=%d)", sum(long$manip_ok == 1))),
  eff_by_focal(m_ok3, sprintf("subjects ticking 3/3 (N=%d)", 3 * length(subj_ok)))
)
print(rob, digits = 4)
write.csv(rob, file.path(DIR_TAB, "05_manipulation_check_robustness.csv"), row.names = FALSE)

cat("\n\n=== D.2 MIXED-EFFECTS ORDINAL LOGIT ===\n\n")
cat("ITD is measured on a 1-7 Likert scale: OLS assumes equal intervals and\n")
cat("unbounded support. Here the same specification as a cumulative ordinal logit.\n\n")
long$y_ord <- factor(long$y, levels = 1:7, ordered = TRUE)
m_ord <- clmm(y_ord ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, link = "logit")
print(summary(m_ord))

cat("\nOdds ratios of the manipulation effect, by focal variable:\n")
cf <- coef(summary(m_ord))
b_brand <- cf["x_fhigh", "Estimate"]
for (f in c("brand", "rep", "pop")) {
  nm <- paste0("focal", f, ":x_fhigh")
  b  <- if (f == "brand") b_brand else b_brand + cf[nm, "Estimate"]
  cat(sprintf("  %-6s  log-odds = %+.4f   OR = %.3f\n", f, b, exp(b)))
}
cat("\nORs > 1 mean a higher probability of high ITD under the high level.\n")

cat("\n\n=== D.3 MULTIPLICITY CORRECTION OVER THE 9 ORIGINAL REGRESSIONS ===\n\n")
cf_orig <- read.csv(file.path(DIR_TAB, "01_replication_coefficients.csv"))
cf_orig <- cf_orig[cf_orig$term != "(Intercept)", ]
cf_orig$p_holm <- p.adjust(cf_orig$p_value, method = "holm")
cf_orig$p_bh   <- p.adjust(cf_orig$p_value, method = "BH")
cat("Estimated coefficients (intercepts excluded):", nrow(cf_orig), "\n")
cat("Significant at p<0.10 uncorrected:", sum(cf_orig$p_value < 0.10), "\n")
cat("Significant at p<0.05 uncorrected:", sum(cf_orig$p_value < 0.05), "\n")
cat("Surviving Holm (p<0.05):          ", sum(cf_orig$p_holm  < 0.05), "\n")
cat("Surviving Benjamini-Hochberg (FDR<0.05):", sum(cf_orig$p_bh < 0.05), "\n\n")
surv <- cf_orig[order(cf_orig$p_value), c("model", "term", "estimate", "se", "p_value", "p_holm", "p_bh")]
cat("Top 15 coefficients by raw p-value:\n")
print(head(surv, 15), digits = 4, row.names = FALSE)
write.csv(surv, file.path(DIR_TAB, "05_multiplicity_adjusted.csv"), row.names = FALSE)

cat("\n\n=== D.4 POWER: WHAT EFFECT WAS DETECTABLE? ===\n\n")
cat("The thesis concludes there are no two-way interactions between the focal\n")
cat("variables. With the Model 2 samples we can compute the minimum detectable\n")
cat("effect (MDE) at 80% power and alpha 0.05: MDE = (t_crit + t_pow) * SE.\n\n")
inter <- cf_orig[grepl("^M2_", cf_orig$model) & grepl(":", cf_orig$term) &
                   grepl("x_(rep|pop|brand):x_(rep|pop|brand)", cf_orig$term), ]
sd_y <- c(brand = 1.5879, rep = 1.7095, pop = 1.5691)
inter$mde <- (qnorm(0.975) + qnorm(0.80)) * inter$se
inter$mde_sd <- inter$mde / sd_y[sub("^M2_", "", inter$model)]
print(inter[, c("model", "term", "estimate", "se", "p_value", "mde", "mde_sd")],
      digits = 3, row.names = FALSE)
cat("\nReading: the design could only detect interactions on the order of\n")
cat(sprintf("%.2f-%.2f Likert points (%.2f-%.2f standard deviations). Absence of\n",
            min(inter$mde), max(inter$mde), min(inter$mde_sd), max(inter$mde_sd)))
cat("evidence is not evidence of absence: these results are inconclusive, not null.\n")
write.csv(inter[, c("model", "term", "estimate", "se", "p_value", "mde", "mde_sd")],
          file.path(DIR_TAB, "05_power_m2_interactions.csv"), row.names = FALSE)

cat("\n\n=== D.5 INVOLVEMENT MODERATION, POOLED MODEL ===\n\n")
cat("The thesis reads the moderations off 9 separate regressions. Here they are\n")
cat("estimated in a single model with the repeated-measures structure.\n\n")
m_inv <- lmer(y ~ focal * x_f * inv_app + focal * x_f * inv_dl + focal * x_f * inv_cat +
                position + (1 | subj_f), data = long, REML = FALSE)
print(car::Anova(m_inv, type = "III"))

cat("\nSlope of the manipulation effect against each involvement measure\n")
cat("(change in the high-vs-low effect per +1 s.d. of involvement):\n")
for (v in c("inv_app", "inv_dl", "inv_cat")) {
  tr <- emtrends(m_inv, ~ x_f | focal, var = v)
  ct <- as.data.frame(summary(contrast(tr, "revpairwise"), infer = c(TRUE, TRUE)))
  ct$moderator <- v
  print(ct[, c("moderator", "focal", "estimate", "SE", "lower.CL", "upper.CL", "p.value")],
        digits = 3, row.names = FALSE)
  cat("\n")
}

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/05_robustness.log\n")
