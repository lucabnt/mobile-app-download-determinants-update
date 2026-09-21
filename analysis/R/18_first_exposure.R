# 18_first_exposure.R --------------------------------------------------------
# Re-examines the 2023 decision to estimate each cue's effect on the FIRST app
# shown only (n = 1), which this review had criticised as "fragmentation".
#
# The author's reason, recorded 2026-09-15: a respondent's judgement of the
# first app is the only one not conditioned by the apps seen before it. The
# restriction was not a sampling accident, it was an attempt to protect the
# estimand.
#
# That reason is sound, and it changes what the criticism can be. This script
# separates three questions that the review had allowed to blur:
#
#   1. Which quantity is being estimated? "The effect of a cue on an
#      unconditioned first judgement" and "the average effect of a cue over
#      three successive judgements" are different quantities, not two estimates
#      of the same one.
#   2. Is the first-exposure quantity the one the thesis's ranking claim needs?
#      If so, does the ranking hold on it?
#   3. Was the *fragmentation* -- nine separate regressions on disjoint
#      subsamples -- required in order to estimate it? (No: one model on all
#      1,473 answers, interacted with position, returns the same quantity and
#      can also test it.)
#
# Output: analysis/outputs/tables/18_*.csv, analysis/outputs/logs/18_*.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4); library(lmerTest); library(emmeans)
  library(clubSandwich); library(ordinal)
})

con <- file(file.path(DIR_LOG, "18_first_exposure.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
long$comp_f   <- factor(long$comp, levels = c(0, 1),
                        labels = c("shown_first", "after_others"))
first <- long[long$position == "first", ]

cat("=== 1. IS THE CONTAMINATION THE RESTRICTION PROTECTS AGAINST REAL? ===\n\n")
cat("The design worry: by the second and third app, the judgement may be made\n")
cat("against what came before rather than in isolation. Script 10 tested it on\n")
cat("the 982 later measurements. Summary of what it found:\n\n")
seq10 <- read.csv(file.path(DIR_TAB, "10_sequence_effects.csv"))
print(seq10[, c("model", "term", "estimate", "se", "p_value")], digits = 3, row.names = FALSE)
sA <- seq10[seq10$model == "A: prior mean level" & seq10$term == "prior_mean_x", ]
sB <- seq10[seq10$model == "B: interaction with history" & seq10$term == "prior_mean_x", ]
cat("\nReading: the average level seen earlier pulls the current rating DOWN\n")
cat(sprintf("(a contrast effect), by %.2f on its own (p = %.2f) and %.2f once the\n",
            sA$estimate, sA$p_value, sB$estimate))
cat(sprintf("interaction with the current cue is in the model (p = %.3f). Direction as\n",
            sB$p_value))
cat("the design feared, magnitude not firmly established.\n")
cat("A design choice does not need a significant threat to be justified: it\n")
cat("needs a plausible one, and removing it costs only precision. This one is\n")
cat("plausible and partly visible in the data.\n")

cat("\n\n=== 2. THREE DIFFERENT QUANTITIES ===\n\n")
cat("Same data, three estimands. The first is the thesis's target.\n\n")

m_sat <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)
m_avg <- lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)

e_first <- summary(contrast(emmeans(m_sat, ~ x_f | focal * position), "revpairwise"),
                   infer = c(TRUE, TRUE))
e_first <- e_first[e_first$position == "first", ]
e_avg   <- summary(contrast(emmeans(m_avg, ~ x_f | focal), "revpairwise"),
                   infer = c(TRUE, TRUE))

est <- data.frame(
  focal              = e_avg$focal,
  first_exposure     = e_first$estimate[match(e_avg$focal, e_first$focal)],
  se_first           = e_first$SE[match(e_avg$focal, e_first$focal)],
  average_all_three  = e_avg$estimate,
  se_average         = e_avg$SE)
print(est, digits = 4, row.names = FALSE)
write.csv(est, file.path(DIR_TAB, "18_estimands.csv"), row.names = FALSE)
cat("\nThe two columns answer different questions. Neither is a correction of\n")
cat("the other: the second averages over judgements the first deliberately\n")
cat("excludes.\n")

cat("\n\n=== 3. DOES THE RANKING HOLD AT FIRST EXPOSURE? ===\n\n")
cat("The test the thesis never ran, run on the quantity the thesis targeted.\n")
cat("One model, all 1,473 answers, cue x manipulation x position, contrasts\n")
cat("between cues within each position, Holm-corrected across the three\n")
cat("comparisons made at that position.\n")

# `pairwise` on the focal dimension gives brand - rep, brand - pop, rep - pop:
# a positive number means the first cue has the larger manipulation effect.
pw <- contrast(emmeans(m_sat, ~ x_f * focal | position),
               interaction = c("revpairwise", "pairwise"))
pw_tab <- summary(pw, by = "position", adjust = "holm", infer = c(TRUE, TRUE))
print(pw_tab, digits = 4)
write.csv(as.data.frame(pw_tab), file.path(DIR_TAB, "18_contrasts_by_position.csv"),
          row.names = FALSE)

cat("\n--- 3.1 The same contrast from the thesis's own sample (n = 1 only) ---\n")
cat("OLS on the 491 first measurements (one row per respondent, so there is\n")
cat("nothing left to cluster), and the ordinal version. This is the thesis's M1\n")
cat("design, with the contrast between cues finally tested.\n\n")
m_p1 <- lm(y ~ focal * x_f + inv_app + inv_dl + inv_cat, data = first)
ct   <- contrast(emmeans(m_p1, ~ x_f * focal), interaction = c("revpairwise", "pairwise"))
print(summary(ct, adjust = "holm", infer = c(TRUE, TRUE)), digits = 4)

# In a cumulative-logit model emmeans reports the latent predictor with the
# opposite orientation (a higher value means more probability mass in the LOWER
# categories), so the sign is flipped back here, as in 07_specification_curve.R.
m_o1 <- clm(factor(y) ~ focal * x_f + inv_app + inv_dl + inv_cat, data = first)
co   <- summary(contrast(emmeans(m_o1, ~ x_f * focal, mode = "linear.predictor"),
                         interaction = c("revpairwise", "pairwise")),
                adjust = "holm", infer = c(TRUE, TRUE))
co_t <- as.data.frame(co)
co_t$estimate <- -co_t$estimate
names(co_t)[names(co_t) == "estimate"] <- "estimate_log_odds"
cat("\nOrdinal (cumulative logit), same contrasts, sign oriented as above:\n")
print(co_t[, c(2, 3, 4, ncol(co_t) - 1, ncol(co_t))], digits = 4, row.names = FALSE)

cat("\n--- 3.2 What the restriction costs in precision ---\n")
bp <- as.data.frame(pw_tab)
bp <- bp[bp$position == "first" & bp[[2]] == "brand - rep", ]
cs <- as.data.frame(summary(ct))
cs <- cs[cs[[2]] == "brand - rep", ]
cat(sprintf("  brand - reputation at first exposure\n"))
cat(sprintf("    pooled model, position-specific : %+.4f  (SE %.4f)\n",
            bp$estimate[1], bp$SE[1]))
cat(sprintf("    n = 1 subsample only            : %+.4f  (SE %.4f)\n",
            cs$estimate[1], cs$SE[1]))
cat("  Same quantity, two ways of getting it. The pooled model borrows the\n")
cat("  residual and person variance from all 1,473 answers; the subsample fit\n")
cat("  estimates them from 491. The point estimates are close, so the\n")
cat("  restriction was not biasing anything -- it was simply leaving the test\n")
cat("  unavailable, because nine separate regressions share no parameters.\n")

cat("\n\n=== 4. IS THE GAP REALLY DIFFERENT AT FIRST EXPOSURE? ===\n\n")
cat("The point estimates say the brand lead shrinks and reverses with position.\n")
cat("Whether that pattern is established is a separate question: it is the\n")
cat("three-way cue x manipulation x position interaction.\n\n")
m_no3 <- lmer(y ~ focal * x_f + focal * position + x_f * position +
                inv_app + inv_dl + inv_cat + (1 | subj_f), data = long, REML = FALSE)
print(anova(m_no3, m_sat))
cat("\nAlso as the two-level version (first vs after others):\n")
m_c   <- lmer(y ~ focal * x_f * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)
m_c0  <- lmer(y ~ focal * x_f + focal * comp_f + x_f * comp_f +
                inv_app + inv_dl + inv_cat + (1 | subj_f), data = long, REML = FALSE)
print(anova(m_c0, m_c))

cat("\nSo: the first-exposure ranking is established (§3); the claim that the\n")
cat("ranking CHANGES with position is not. Both statements are needed, and the\n")
cat("2023 work made the second one -- the M1-to-M2 'reversal' -- on the\n")
cat("strength of point estimates from disjoint samples.\n")

cat("\n--- 4.1 A correction to how this review reported the same term ---\n")
cat("The review quoted the three-way interaction as 'F = 0.64, p = 0.63'. That\n")
cat("is one of two numbers, not the test. Because the level of the cue is\n")
cat("assigned between respondents, aov() with Error(subject) splits the term\n")
cat("across the two strata, and prints it twice:\n\n")
a_corr <- aov(y ~ focal * x_f * position + Error(subj_f), data = long)
sa <- summary(a_corr)
print(sa)
strat <- function(s) {
  t <- s[[1]]; r <- trimws(rownames(t)) == "focal:x_f:position"
  c(F = t[r, "F value"], p = t[r, "Pr(>F)"])
}
b3 <- strat(sa[["Error: subj_f"]]); w3 <- strat(sa[["Error: Within"]])
l3 <- anova(m_no3, m_sat)
cat(sprintf("\n  between-subject stratum : F = %.3f, p = %.4f\n", b3[["F"]], b3[["p"]]))
cat(sprintf("  within-subject stratum  : F = %.3f, p = %.4f\n", w3[["F"]], w3[["p"]]))
cat(sprintf("  combined (mixed model)  : LRT chi-square = %.2f, 4 df, p = %.3f\n",
            l3$Chisq[2], l3$`Pr(>Chisq)`[2]))
cat("  (04_corrected_inference.R reports the Wald version of the same test.)\n\n")
cat("The conclusion does not change -- the interaction is not significant, and\n")
cat("the 2023 claim that it was remains withdrawn -- but the honest number is\n")
cat("the combined one. Quoting 0.63 alone reports the half of the term that\n")
cat("vanishes and omits the half that does not.\n")

avg <- as.data.frame(summary(contrast(emmeans(m_avg, ~ x_f * focal),
                     interaction = c("revpairwise", "pairwise")), adjust = "holm"))
avg <- avg[avg[[2]] == "brand - rep", ]
co1 <- co_t[co_t[[2]] == "brand - rep", ]
cs1 <- as.data.frame(summary(ct, adjust = "holm"))
cs1 <- cs1[cs1[[2]] == "brand - rep", ]

cat("\n\n=== 5. VERDICT ===\n\n")
cat("What the 2023 design got right:\n")
cat("  * the first judgement is the only uncontaminated one, and the threat it\n")
cat("    protects against is visible in the data (§1);\n")
cat("  * on that quantity the ranking brand > reputation holds under every\n")
cat(sprintf("    specification tried: %+.2f points (p = %.4f, Holm) from the pooled model,\n",
            bp$estimate[1], bp$p.value[1]))
cat(sprintf("    %+.2f (p = %.4f) and %+.2f log-odds (p = %.4f) in the thesis's own\n",
            cs1$estimate, cs1$p.value, co1$estimate_log_odds, co1$p.value))
cat("    sample of first measurements (§3);\n")
cat("  * Model 3's comp_i interaction was the right instinct: it says the\n")
cat("    effect depends on whether comparison has happened.\n\n")
cat("What remains wrong, and is a smaller and more specific charge than the\n")
cat("review first made:\n")
cat("  * nine regressions on disjoint subsamples cannot test a difference\n")
cat("    between cues, and none was tested. The estimand did not require the\n")
cat("    fragmentation: one model with a position interaction delivers it and\n")
cat("    the test together (§3.2);\n")
cat("  * the scope was stated -- the abstract says brand loses its edge under\n")
cat("    comparison -- but neither half was tested. The first-app ranking holds;\n")
cat("    averaged over the three judgements brand and reputation are\n")
cat(sprintf("    indistinguishable (%+.2f, p = %.2f);\n", avg$estimate, avg$p.value))
cat("  * M3's x_brand = 1.5028 was read as the effect 'independently from n'.\n")
cat("    With comp_i and its interaction in the model, that coefficient is the\n")
cat("    effect at comp_i = 0, i.e. first exposure again -- not an overall\n")
cat("    effect;\n")
cat("  * the M1-to-M2 'reversal' is not established: the interaction that would\n")
cat("    license it is not significant (§4).\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/18_first_exposure.log\n")
