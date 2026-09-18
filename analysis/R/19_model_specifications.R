# 19_model_specifications.R --------------------------------------------------
# A second reading of the three model definitions of the 2023 thesis (§3.4),
# made after the author explained the estimand behind Model 1 (see
# 18_first_exposure.R). The first reading treated the nine regressions as one
# undifferentiated "fragmentation". They are not: each model has a stated
# purpose, and each purpose has to be judged on its own.
#
#   M1 : y_{i1} ~ x_{i1} + involvement + x_{i1} x involvement     (n = 1 only)
#   M2 : y_{i3} ~ x_{i3} + x_j + x_k + involvement
#                + x_{i3} x_j + x_{i3} x_k + x_{i3} x involvement (n = 3 only)
#   M3 : y_i    ~ x_i + comp_i + involvement
#                + x_i comp_i + x_i x involvement                 (all n)
#
# What this script checks, because the answers change the verdict:
#   1. how many observations each regression takes from each respondent;
#   2. whether M1 and M3 estimate the same quantity, and what M3 adds;
#   3. what pooling across cues adds that no per-cue model can have;
#   4. what M2's interaction terms actually mean, and on how much data;
#   5. what M3's two-level comp_i collapses.
#
# Output: analysis/outputs/tables/19_*.csv, analysis/outputs/logs/19_*.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4); library(emmeans)
})

con <- file(file.path(DIR_LOG, "19_model_specifications.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

cat("=== 1. HOW MANY ROWS PER RESPONDENT DOES EACH REGRESSION USE? ===\n\n")
cat("The review's headline defect (A) is that the repeated measures are not\n")
cat("modelled. That is true of the ANOVA. It is worth establishing, rather than\n")
cat("assuming, whether it is also true of the nine regressions.\n\n")

files <- c("M1_rep", "M1_pop", "M1_brand", "M2_rep", "M2_pop", "M2_brand",
           "M3_rep", "M3_pop", "M3_brand")
rows <- do.call(rbind, lapply(files, function(f) {
  d <- read_orig(paste0(f, ".csv"))
  data.frame(dataset = f, rows = nrow(d), respondents = length(unique(d$lfdn)),
             max_rows_per_respondent = max(table(d$lfdn)))
}))
anv <- read_orig("M ANOVA_RM.csv")
rows <- rbind(rows, data.frame(dataset = "M ANOVA_RM", rows = nrow(anv),
                               respondents = length(unique(anv$lfdn)),
                               max_rows_per_respondent = max(table(anv$lfdn))))
print(rows, row.names = FALSE)
write.csv(rows, file.path(DIR_TAB, "19_rows_per_respondent.csv"), row.names = FALSE)

cat("\nEvery regression takes **one** measurement per respondent: each person\n")
cat("contributes a single y for a given cue, so inside any one of the nine\n")
cat("regressions the observations are independent and ordinary least squares is\n")
cat("the right estimator with the right standard errors. The clustering problem\n")
cat("exists in exactly one place -- the ANOVA, the only analysis that stacks all\n")
cat("three measurements -- and that is the one where Error(lfdn) failed.\n")

cat("\n\n=== 2. DO M1 AND M3 ESTIMATE THE SAME QUANTITY? ===\n\n")
cat("M1 restricts to n = 1. M3 keeps every observation but carries comp_i and\n")
cat("x_i * comp_i, so its x_i coefficient is the effect at comp_i = 0 -- which is\n")
cat("n = 1 again. The two are routes to the same estimand.\n\n")

cf <- read.csv(file.path(DIR_TAB, "01_replication_coefficients.csv"))
pick <- function(model, term) {
  r <- cf[cf$model == model & cf$term == term, ]
  c(estimate = r$estimate[1], se = r$se[1])
}
est18 <- read.csv(file.path(DIR_TAB, "18_estimands.csv"))
cmp <- do.call(rbind, lapply(c("brand", "rep", "pop"), function(f) {
  m1 <- pick(paste0("M1_", f), paste0("x_", f))
  m3 <- pick(paste0("M3_", f), paste0("x_", f))
  p  <- est18[est18$focal == f, ]
  data.frame(cue = f,
             M1_estimate = m1[["estimate"]], M1_se = m1[["se"]],
             M3_estimate = m3[["estimate"]], M3_se = m3[["se"]],
             pooled_estimate = p$first_exposure, pooled_se = p$se_first)
}))
print(cmp, digits = 4, row.names = FALSE)
write.csv(cmp, file.path(DIR_TAB, "19_same_estimand_three_ways.csv"), row.names = FALSE)

cat("\nM1 and M3 agree to within a few hundredths, and their standard errors are\n")
cat("almost identical: M3 buys no precision on this quantity, because the\n")
cat("first-exposure effect is still identified by the same first-position\n")
cat("observations. What M3 adds is the moderation by comparison, which is a\n")
cat("second question rather than a better answer to the first.\n")
cat(sprintf("\nMean |M1 - M3| across the three cues: %.4f\n",
            mean(abs(cmp$M1_estimate - cmp$M3_estimate))))
cat(sprintf("Mean standard error: M1 %.4f, M3 %.4f, one pooled model %.4f\n",
            mean(cmp$M1_se), mean(cmp$M3_se), mean(cmp$pooled_se)))
cat("\nThe precision gain comes from pooling across CUES, not across positions:\n")
cat("one model shares the residual variance, the respondent variance and the\n")
cat("involvement coefficients across all 1,473 answers.\n")

cat("\n\n=== 3. WHAT ONLY A POOLED MODEL CAN DO ===\n\n")
cat("Nine regressions produce nine coefficient vectors with no covariance\n")
cat("between them. Any statement of the form 'cue A beats cue B' needs that\n")
cat("covariance. This is the whole of the gap, and it is not a matter of taste:\n")
cat("it is what makes the thesis's central claim untestable as written.\n\n")
long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
m_sat <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)
pw <- summary(contrast(emmeans(m_sat, ~ x_f * focal | position),
                       interaction = c("revpairwise", "pairwise")),
              by = "position", adjust = "holm")
pw <- as.data.frame(pw)
print(pw[pw$position == "first", c(2, 3, 4, 7, 8)], digits = 4, row.names = FALSE)
cat("\nSame quantity M1 targets, plus the comparison M1 cannot make.\n")

cat("\n\n=== 4. WHAT M2'S INTERACTIONS ACTUALLY ASK ===\n\n")
cat("x_j and x_k are not two more attributes of the app being judged. They are\n")
cat("attributes of the OTHER apps, seen on earlier slides. So 'interaction\n")
cat("between focal variables' here means: does the effect of this app's rating\n")
cat("depend on how strong the brand of a previous app was? That is a carryover\n")
cat("moderation, not a factorial interaction -- and a factorial interaction is\n")
cat("what the abstract's wording suggests to a reader.\n\n")

wide <- read.csv(file.path(DIR_DERIV, "wide_subjects.csv"))
cat("Respondents per combination of the two non-focal levels, for i = rep:\n")
print(table(x_brand = wide$x.brand, x_pop = wide$x.pop))
cat("\nThose cells carry the six interaction terms. With 143-196 observations and\n")
cat("11 predictors the minimum detectable interaction is 0.76-0.98 s.d.\n")
cat("(05_power_m2_interactions.csv): the question was asked on a sample that\n")
cat("could not answer it.\n\n")
cat(sprintf("Observations M2 leaves unused: %d of the 982 measurements that have\n",
            sum(long$position == "second")))
cat("at least one app before them -- every n = 2 answer. The same carryover\n")
cat("question on all 982 is 10_sequence_effects.R.\n")

cat("\n\n=== 5. WHAT comp_i COLLAPSES ===\n\n")
cat("M3 codes comparison as first (0) versus second-or-third (1). The effects by\n")
cat("position say the two halves of that second level are not alike:\n\n")
byp <- as.data.frame(summary(contrast(emmeans(m_sat, ~ x_f | focal * position),
                                      "revpairwise")))
print(byp[, c("focal", "position", "estimate", "SE", "p.value")], digits = 3,
      row.names = FALSE)
write.csv(byp, file.path(DIR_TAB, "19_effects_by_position.csv"), row.names = FALSE)
g <- function(f, p) byp$estimate[byp$focal == f & byp$position == p]
cat(sprintf("\nReputation is %.2f on the second app and %.2f on the third; popularity is\n",
            g("rep", "second"), g("rep", "third")))
cat(sprintf("%+.2f and %+.2f. Averaging them into one 'after comparison' number is not\n",
            g("pop", "second"), g("pop", "third")))
cat("wrong, but it describes a situation no respondent was ever in.\n")

cat("\n\n=== 6. VERDICT ON THE THREE SPECIFICATIONS ===\n\n")
cat("M1  Sound. Right estimand (uncontaminated first judgement), right\n")
cat("    estimator, valid standard errors, and the model the thesis says it\n")
cat("    relies on. Its limit is 149-189 observations by construction, which\n")
cat("    makes the involvement moderations underpowered.\n\n")
cat("M3  The most efficient use of the data among the three, and the one closest\n")
cat("    to what this review recommends: all 491 measurements of a cue, with\n")
cat("    comparison as a moderator. Two caveats: its x_i coefficient is the\n")
cat("    effect at comp_i = 0 and was read as an overall effect, and pooling\n")
cat("    positions 2 and 3 into one 'after comparison' level hides that the two\n")
cat("    differ for reputation.\n\n")
cat("M2  The weakest of the three. The question is legitimate and interesting,\n")
cat("    but it is asked on a third of the data, it collapses the order of the\n")
cat("    two earlier apps, and its power is an order of magnitude short of the\n")
cat("    effects it looks for. The null it produced carries no information.\n\n")
cat("ANOVA  The only analysis that needed the repeated-measures machinery, and\n")
cat("    the only one that got it wrong. Its stated role is preliminary -- 'may\n")
cat("    help in understanding if some effects exist' -- but its three-way\n")
cat("    interaction was then used as 'further foundations for subsequent\n")
cat("    analyses', which is more weight than a screening device can carry.\n\n")
cat("What none of the three can do, individually or together, is compare one cue\n")
cat("with another. That is the finding of this review, and it is a statement\n")
cat("about the SET of models, not about any one of them.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/19_model_specifications.log\n")
