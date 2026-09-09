# 04_corrected_inference.R ---------------------------------------------------
# Fixes the two main inferential defects of the 2023 work:
#
#  (A) Repeated-measures ANOVA. In the original, `aov(... + Error(lfdn))` gets
#      lfdn as an integer: aov treats it as a continuous covariate, the
#      Error(lfdn) stratum collapses to 1 df with no residuals, and the
#      repeated-measures structure is NOT modelled. Here it is specified
#      correctly (subject as a factor), plus a mixed-effects model and an OLS
#      version with cluster-robust standard errors by subject.
#
#  (B) Formal test of the brand > reputation > popularity ranking. The thesis
#      infers the ranking by eyeballing coefficients estimated on disjoint
#      subsamples, with no test of the difference. Here a single pooled model on
#      all 1473 observations, with a focal x manipulation interaction, and
#      pairwise contrasts between the effects.
#
# Output: analysis/outputs/tables/04_*.csv, analysis/outputs/logs/04_*.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4)
  library(emmeans)
  library(clubSandwich)
  library(car)
})

con <- file(file.path(DIR_LOG, "04_corrected_inference.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))

cat("=== (A) REPEATED-MEASURES ANOVA ===\n\n")

cat("--- A.1 The thesis specification: Error(lfdn) with lfdn as an integer ---\n")
a_orig <- aov(y ~ focal * x_f * position + Error(subject), data = long)
print(summary(a_orig))
cat("\nNOTE: the 'Error: subject' stratum has 1 df and no residuals. The repeated-\n")
cat("measures structure is not modelled; the 'Within' tests are those of an ANOVA\n")
cat("over independent observations on 1454 residual df.\n")
cat("The thesis text instead reports df = 4 in the denominator.\n\n")

cat("--- A.2 Correct specification: subject as a factor ---\n")
a_corr <- aov(y ~ focal * x_f * position + Error(subj_f), data = long)
print(summary(a_corr))

cat("\n--- A.3 Linear mixed model, random intercept by subject ---\n")
m_mix <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = TRUE)
print(summary(m_mix))
cat("\nBetween-subject variance / total (ICC):\n")
vc <- as.data.frame(VarCorr(m_mix))
icc <- vc$vcov[1] / sum(vc$vcov)
cat(sprintf("  ICC = %.4f (subject var = %.4f, residual = %.4f)\n", icc, vc$vcov[1], vc$vcov[2]))

cat("\n--- A.4 Type II Anova on the mixed model (Wald chi-square) ---\n")
print(Anova(m_mix, type = "II"))

cat("\n--- A.5 OLS with cluster-robust standard errors by subject (CR2) ---\n")
m_ols <- lm(y ~ focal * x_f * position, data = long)
ct <- coef_test(m_ols, vcov = "CR2", cluster = long$subject, test = "Satterthwaite")
print(ct)

cat("\n\n=== (B) FORMAL TEST OF THE RANKING BETWEEN FOCAL VARIABLES ===\n\n")

cat("Pooled model: y ~ focal * x + position + involvement + (1|subject)\n")
cat("on all 1473 observations. The focal:x interaction quantifies how much the\n")
cat("manipulation effect differs across brand, reputation and popularity.\n\n")

m_pool <- lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
print(summary(m_pool))

cat("\n--- B.1 Is the focal x manipulation interaction needed? (LRT) ---\n")
m_pool0 <- lmer(y ~ focal + x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
                data = long, REML = FALSE)
print(anova(m_pool0, m_pool))

cat("\n--- B.2 Manipulation effect (high vs low) within each focal variable ---\n")
emm <- emmeans(m_pool, ~ x_f | focal)
eff <- contrast(emm, "revpairwise")
print(summary(eff, infer = c(TRUE, TRUE)))

cat("\n--- B.3 Pairwise comparison of the effects (Holm correction) ---\n")
cat("This is the test the thesis never runs: does brand really beat reputation?\n")
diffs <- contrast(emmeans(m_pool, ~ x_f * focal), interaction = c("revpairwise", "revpairwise"))
print(summary(diffs, adjust = "holm", infer = c(TRUE, TRUE)))

rank_tab <- as.data.frame(summary(eff, infer = c(TRUE, TRUE)))
write.csv(rank_tab, file.path(DIR_TAB, "04_effect_by_focal.csv"), row.names = FALSE)
write.csv(as.data.frame(summary(diffs, adjust = "holm", infer = c(TRUE, TRUE))),
          file.path(DIR_TAB, "04_pairwise_focal_contrasts.csv"), row.names = FALSE)

cat("\n--- B.4 Effect sizes in standard-deviation units ---\n")
sd_y <- tapply(long$y, long$focal, sd)
for (f in levels(long$focal)) {
  e <- rank_tab[rank_tab$focal == f, ]
  cat(sprintf("  %-6s  beta = %+.4f  (s.d. of y = %.4f)  d = %+.3f\n",
              f, e$estimate, sd_y[[f]], e$estimate / sd_y[[f]]))
}

cat("\n\n=== (C) EFFECT OF COMPARISON (POSITION) ON THE RANKING ===\n")
cat("Three-way focal x manipulation x comparison interaction, estimated on a\n")
cat("single model rather than on separate subsamples (the thesis M1 vs M2).\n\n")
long$comp_f <- factor(long$comp, levels = c(0, 1), labels = c("shown_first", "after_others"))
m_comp <- lmer(y ~ focal * x_f * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
print(Anova(m_comp, type = "III"))
cat("\nManipulation effect by focal variable and comparison position:\n")
emm_c <- emmeans(m_comp, ~ x_f | focal * comp_f)
print(summary(contrast(emm_c, "revpairwise"), infer = c(TRUE, TRUE)))
write.csv(as.data.frame(summary(contrast(emm_c, "revpairwise"), infer = c(TRUE, TRUE))),
          file.path(DIR_TAB, "04_effect_by_focal_and_comparison.csv"), row.names = FALSE)

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/04_corrected_inference.log\n")
