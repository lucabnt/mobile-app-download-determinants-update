# 17_centering_check.R -------------------------------------------------------
# Evaluates one choice of the 2023 work that the review had recorded but never
# assessed: the **mean-centred ITD** (`y_i_mc`).
#
# Why it deserves its own script. The thesis carries two centrings, and they are
# not the same kind of decision:
#
#   * the three involvement measures are centred on the overall mean. That is
#     standard practice in a model with interactions: it makes the main effect
#     of x readable as "the effect at average involvement" instead of "the
#     effect at involvement zero", a value no respondent has;
#   * the outcome, ITD, is centred **within focal variable** (`y_i_mc`), and is
#     used only to draw Figure 3.1 of the thesis.
#
# Three questions, in order:
#   1. What exactly does the centring subtract?
#   2. Would any estimate have changed if the models had used it? (Shift
#      invariance says no for slopes; this verifies it rather than asserting it,
#      and shows where the design's imbalance makes it not exactly zero.)
#   3. What does the centred scale cost the reader of the figure?
# And a fourth, which is the substantive one: in a repeated-measures design the
# centring that carries information is **by respondent**, not by cue. §5 shows
# what it does.
#
# Output: analysis/outputs/tables/17_*.csv, analysis/outputs/logs/17_*.log
#         analysis/outputs/figures/fig_14_centring.png
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4)
  library(emmeans)
  library(car)
})

con <- file(file.path(DIR_LOG, "17_centering_check.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))

cat("=== 1. WHAT THE CENTRING SUBTRACTS ===\n\n")
cat("Claim to verify: y_i_mc = y_i - mean(y_i within focal variable).\n\n")

ctr <- tapply(long$y, long$focal, mean)
chk <- data.frame(
  focal      = levels(long$focal),
  n          = as.integer(table(long$focal)),
  mean_raw   = as.numeric(ctr),
  mean_centred = as.numeric(tapply(long$y_mc, long$focal, mean)),
  max_dev    = NA_real_
)
for (i in seq_len(nrow(chk))) {
  s <- long[long$focal == chk$focal[i], ]
  chk$max_dev[i] <- max(abs(s$y - mean(s$y) - s$y_mc))
}
print(chk, digits = 6)
cat("\nOverall mean of y_i:", sprintf("%.6f", mean(long$y)), "\n")
cat("Largest deviation from the within-focal rule:", sprintf("%.2e", max(chk$max_dev)), "\n")
cat("\nSo the constant subtracted is different for each cue: it is not one\n")
cat("centring but three. The three cues are moved to a common zero, which is\n")
cat("exactly what makes the levels no longer comparable (see §4).\n")

write.csv(chk, file.path(DIR_TAB, "17_centring_constants.csv"), row.names = FALSE)

cat("\n\n=== 2. WHERE THE THESIS USES IT ===\n\n")
cat("`y_i_mc` appears in the 2023 script only inside the four interaction.plot\n")
cat("calls that produce Figure 3.1 (lines 118-138 of thesis_analysis_2023.R).\n")
cat("Every regression uses the raw outcome: the nine lm() calls take y_rep_*,\n")
cat("y_pop_*, y_brand_*, and the repeated-measures ANOVA takes y_i. The\n")
cat("centred outcome therefore carries no estimate in the thesis; it carries a\n")
cat("figure, and one sentence of the Discussion that reads the figure.\n")

cat("\n\n=== 3. WOULD ANY ESTIMATE HAVE CHANGED? ===\n\n")
cat("Subtracting a constant per cue cannot change a slope within that cue, so\n")
cat("in principle only the main effect of `focal` moves. Two things can break\n")
cat("that in practice: an unbalanced design, and terms that mix cues.\n")

cat("\n--- 3.1 Balance of the design ---\n")
print(ftable(xtabs(~ focal + x_f + position, data = long)))
bal <- as.data.frame(xtabs(~ focal + x_f + position, data = long))
cat(sprintf("\ncell sizes: min %d, max %d, mean %.1f\n",
            min(bal$Freq), max(bal$Freq), mean(bal$Freq)))
cat("The Latin square is near-balanced but not exactly balanced (random\n")
cat("assignment, not a fixed rotation), so the orthogonality is approximate.\n")

cat("\n--- 3.2 Same mixed model, raw outcome vs centred outcome ---\n")
f_raw <- y    ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f)
f_ctr <- y_mc ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f)
m_raw <- lmer(f_raw, data = long, REML = FALSE)
m_ctr <- lmer(f_ctr, data = long, REML = FALSE)

cmp <- data.frame(
  term        = names(fixef(m_raw)),
  raw         = as.numeric(fixef(m_raw)),
  centred     = as.numeric(fixef(m_ctr)),
  se_raw      = sqrt(diag(vcov(m_raw))),
  se_centred  = sqrt(diag(vcov(m_ctr))),
  row.names   = NULL
)
cmp$difference <- cmp$centred - cmp$raw
print(cmp, digits = 5)
write.csv(cmp, file.path(DIR_TAB, "17_raw_vs_centred_coefficients.csv"), row.names = FALSE)

shift <- c(brand = 0, rep = ctr[["rep"]] - ctr[["brand"]], pop = ctr[["pop"]] - ctr[["brand"]])
cat("\nExpected shift if centring only moves the cue intercepts:\n")
cat(sprintf("  focalrep  %+.6f   (observed %+.6f)\n", -shift[["rep"]],
            cmp$difference[cmp$term == "focalrep"]))
cat(sprintf("  focalpop  %+.6f   (observed %+.6f)\n", -shift[["pop"]],
            cmp$difference[cmp$term == "focalpop"]))
oth <- cmp[!cmp$term %in% c("focalrep", "focalpop", "(Intercept)"), ]
cat(sprintf("\nEvery other coefficient: largest absolute change %.2e\n",
            max(abs(oth$difference))))
cat(sprintf("Standard errors: largest absolute change %.2e\n",
            max(abs(cmp$se_centred - cmp$se_raw))))
cat(sprintf("Variance components identical to %.2e\n",
            max(abs(as.data.frame(VarCorr(m_raw))$vcov -
                    as.data.frame(VarCorr(m_ctr))$vcov))))

cat("\n--- 3.3 The manipulation effect by cue, both scales ---\n")
e_raw <- summary(contrast(emmeans(m_raw, ~ x_f | focal), "revpairwise"), infer = c(TRUE, TRUE))
e_ctr <- summary(contrast(emmeans(m_ctr, ~ x_f | focal), "revpairwise"), infer = c(TRUE, TRUE))
eff <- data.frame(focal = e_raw$focal,
                  effect_raw = e_raw$estimate, p_raw = e_raw$p.value,
                  effect_centred = e_ctr$estimate, p_centred = e_ctr$p.value)
print(eff, digits = 6)
cat(sprintf("\nLargest difference in the effects that carry the thesis's ranking: %.2e\n",
            max(abs(eff$effect_raw - eff$effect_centred))))

cat("\n--- 3.4 The repeated-measures ANOVA, both scales ---\n")
a_raw <- aov(y    ~ focal * x_f * position + Error(subj_f), data = long)
a_ctr <- aov(y_mc ~ focal * x_f * position + Error(subj_f), data = long)
cat("\nRaw outcome:\n");     print(summary(a_raw))
cat("\nCentred outcome:\n"); print(summary(a_ctr))
cat("\nOnly the `focal` line moves, and it moves to nothing: centring within\n")
cat("cue deletes the between-cue main effect by construction. Every test the\n")
cat("thesis actually interprets -- x, focal:x, and the three-way term -- is\n")
cat("unchanged. Had the ANOVA been run on y_i_mc, the conclusions would have\n")
cat("been the same, minus one effect that would have been structurally zero.\n")

cat("\n\n=== 4. WHAT THE CENTRED SCALE COSTS THE READER ===\n\n")
cat("Figure 3.1 plots the centred outcome for each cue in the same panel. Since\n")
cat("each cue was shifted by its own constant, the vertical position of a line\n")
cat("is not a level of intention to download: it is a level relative to that\n")
cat("cue's own average. Ordering of the lines is therefore not interpretable,\n")
cat("while their slopes are.\n\n")

cells <- aggregate(cbind(y, y_mc) ~ focal + position + x_f, data = long, FUN = mean)
cells <- cells[order(cells$position, cells$x_f, cells$focal), ]
names(cells) <- c("focal", "position", "x", "mean_raw", "mean_centred")
print(cells, digits = 4, row.names = FALSE)
write.csv(cells, file.path(DIR_TAB, "17_cell_means_raw_vs_centred.csv"), row.names = FALSE)

cat("\nOrdering of the three cues within each panel of the figure:\n")
for (p in levels(long$position)) {
  for (xx in levels(long$x_f)) {
    s <- cells[cells$position == p & cells$x == xx, ]
    o_raw <- paste(s$focal[order(-s$mean_raw)], collapse = " > ")
    o_ctr <- paste(s$focal[order(-s$mean_centred)], collapse = " > ")
    cat(sprintf("  %-6s x=%-4s   raw: %-22s centred: %-22s %s\n", p, xx, o_raw, o_ctr,
                ifelse(o_raw == o_ctr, "same", "DIFFERENT")))
  }
}
cat("\nWhere the two orderings disagree, the figure shows an ordering that the\n")
cat("data does not have on its own scale. The thesis reads one thing from the\n")
cat("figure -- the parallel between n=1 and n=3 -- and that reading is safe,\n")
cat("because it is about slopes. A reader comparing heights would be misled.\n")

# --- fig 14: the same cell means on both scales ------------------------------
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  PAL <- c(brand = "#1f4e79", rep = "#c0504d", pop = "#7f7f7f")
  LAB <- c(brand = "Developer brand", rep = "Reputation (rating)",
           pop = "Popularity (downloads)")
  d14 <- rbind(
    data.frame(cells[c("focal", "position", "x")], value = cells$mean_raw,
               scale = "raw ITD (1-7)"),
    data.frame(cells[c("focal", "position", "x")], value = cells$mean_centred,
               scale = "mean-centred ITD"))
  d14$scale    <- factor(d14$scale, levels = c("raw ITD (1-7)", "mean-centred ITD"))
  d14$position <- factor(d14$position, levels = c("first", "second", "third"),
                         labels = c("n = 1", "n = 2", "n = 3"))
  d14$focal    <- factor(d14$focal, levels = c("brand", "rep", "pop"))

  p14 <- ggplot(d14, aes(x, value, colour = focal, group = focal)) +
    geom_line(linewidth = 0.7) + geom_point(size = 2.2) +
    facet_grid(scale ~ position, scales = "free_y", switch = "y") +
    scale_colour_manual(values = PAL, labels = LAB, name = NULL) +
    labs(title = "What the mean-centred scale keeps, and what it hides",
         subtitle = paste("Same cell means, two scales. Every slope is identical;",
                          "the height of each line is not."),
         x = "manipulated cue: low vs high", y = NULL,
         caption = paste("The lower row is the scale of Figure 3.1 of the thesis: each cue is",
                         "shifted by its own mean, so a line can be read for slope\nbut not",
                         "for level. In 4 of the 6 low/high panels the three cues come out in",
                         "a different order than they do on the 1-7 scale.")) +
    theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(), legend.position = "top",
          strip.placement = "outside",
          plot.title = element_text(face = "bold", size = 12),
          plot.subtitle = element_text(colour = "grey30", size = 9),
          plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
  ggsave(file.path(DIR_FIG, "fig_14_centring.png"), p14, width = 7.4, height = 5.2, dpi = 200)
  cat("\n  written: fig_14_centring.png\n")
}

cat("\n\n=== 5. WHY THE CUE CENTRING IS HARMLESS, AND WHEN CENTRING IS NOT ===\n\n")
cat("The general rule: subtracting a constant per group from the outcome is\n")
cat("harmless if and only if the model already contains that group as a term,\n")
cat("because the constants are then absorbed by the group intercepts. The nine\n")
cat("regressions of the thesis are estimated one cue at a time -- the cue is\n")
cat("the sample -- and the pooled models of this review carry `focal` as a\n")
cat("factor. Either way a per-cue constant is absorbed, which is what §3\n")
cat("observed rather than assumed.\n\n")
cat("The rule also says where the same operation would have done damage. In a\n")
cat("repeated-measures design the tempting centring is by respondent, and 41%\n")
cat("of the variance in ITD is between respondents (ICC, script 04). Doing it\n")
cat("to the outcome alone, with no respondent term in the model, is not a\n")
cat("neutral rescaling: each respondent's mean contains their own treated\n")
cat("observation, so part of the effect is subtracted from itself.\n\n")

cat("Variance removed by each centring:\n")
long$y_sc <- long$y - tapply(long$y, long$subj_f, mean)[as.character(long$subj_f)]
cat(sprintf("  by cue        var(y) = %.4f -> var(y_mc) = %.4f  (%.1f%% removed)\n",
            var(long$y), var(long$y_mc), 100 * (1 - var(long$y_mc) / var(long$y))))
cat(sprintf("  by respondent var(y) = %.4f -> var(y_sc) = %.4f  (%.1f%% removed)\n\n",
            var(long$y), var(long$y_sc), 100 * (1 - var(long$y_sc) / var(long$y))))

# The three cue effects read straight off the coefficients, so that the same
# contrast is computed the same way for models with and without 491 dummies.
eff_by_cue <- function(b, V, label) {
  out <- NULL
  for (f in c("brand", "rep", "pop")) {
    k <- setNames(rep(0, length(b)), names(b))
    k["x_fhigh"] <- 1
    if (f != "brand") k[paste0("focal", f, ":x_fhigh")] <- 1
    out <- rbind(out, data.frame(
      estimator = label, focal = f,
      estimate  = sum(k * b),
      se        = sqrt(as.numeric(t(k) %*% V %*% k))))
  }
  out
}
drop_subj <- function(m) {
  b <- coef(m); V <- vcov(m)
  keep <- !grepl("^subj_f", names(b))
  list(b = b[keep], V = V[keep, keep, drop = FALSE])
}

fx     <- y ~ focal * x_f + position
m_ols  <- lm(fx, data = long)
m_fe   <- lm(update(fx, . ~ . + subj_f), data = long)          # exact within estimator
m_mm   <- lmer(update(fx, . ~ . + (1 | subj_f)), data = long, REML = FALSE)
m_bad  <- lm(update(fx, y_sc ~ .), data = long)                # outcome centred, no subject term
fe     <- drop_subj(m_fe)

est <- rbind(
  eff_by_cue(coef(m_ols), vcov(m_ols),              "OLS, no subject term"),
  eff_by_cue(fixef(m_mm), as.matrix(vcov(m_mm)),    "mixed model (random intercept)"),
  eff_by_cue(fe$b, fe$V,                            "subject fixed effects (within)"),
  eff_by_cue(coef(m_bad), vcov(m_bad),              "outcome centred by respondent only"))
print(est[order(est$focal), ], digits = 4, row.names = FALSE)
write.csv(est, file.path(DIR_TAB, "17_estimators_compared.csv"), row.names = FALSE)

a <- est[est$estimator == "subject fixed effects (within)", "estimate"]
b <- est[est$estimator == "outcome centred by respondent only", "estimate"]
cat("\nThe three legitimate estimators bracket each other: the mixed model sits\n")
cat("between pooled OLS and the within estimator, as it should. Centring the\n")
cat("outcome alone attenuates every effect instead, against the within\n")
cat(sprintf("estimate: brand -%.0f%%, reputation -%.0f%%, popularity -%.0f%%.\n",
            100 * (1 - b[1] / a[1]), 100 * (1 - b[2] / a[2]), 100 * (1 - b[3] / a[3])))
cat("That is the trap the thesis did not fall into -- because it centred on the\n")
cat("cue, which its models already control for, and not on the respondent.\n")

cat("\n\n=== 6. VERDICT ===\n\n")
cat("The mean-centred ITD is a defensible plotting device and a harmless one\n")
cat("for inference: no estimate in the thesis depends on it, and had every\n")
cat("model used it, only the between-cue main effect would have changed --\n")
cat("to zero, by construction.\n\n")
cat("Two qualifications stand:\n")
cat("  (a) the label. 'Mean-centered ITD' suggests one centring on the overall\n")
cat("      mean. It is three centrings, one per cue, so heights in Figure 3.1\n")
cat("      are within-cue deviations and not comparable across cues.\n")
cat("  (b) the dimension left untouched. The variance that needed handling in\n")
cat("      this design is between respondents, and no centring can do it: it\n")
cat("      needs a respondent term in the model, which is what the integer\n")
cat("      Error(lfdn) failed to provide and what the mixed model of script 04\n")
cat("      finally provides. Centring the outcome by respondent instead would\n")
cat("      have shrunk every effect by about a third (§5).\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/17_centering_check.log\n")
