# 16_figures_extended.R ------------------------------------------------------
# Every figure that helps explain a result, beyond the four already produced by
# `06_figures.R` and `07_specification_curve.R`.
#
#   fig_05_pooling_gain.png   the same effects three ways: thesis subsamples,
#                             one model on the first app, one model on all three
#   fig_06_by_position.png    each cue's effect at each presentation position
#   fig_07_equivalence.png    null results against the relevance band
#   fig_08_heterogeneity.png  people differ, and how their baseline relates to it
#   fig_09_scale_cutpoints.png the 1-7 scale is not a ruler
#   fig_10_sequence.png       contrast effects from the apps seen earlier
#   fig_11_quality.png        robustness to rushed and careless answers
#   fig_12_demographics.png   cue effects by occupation (needs RAW_EXPORT)
#
# Output: analysis/outputs/figures/
#         analysis/outputs/logs/16_figures_extended.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4); library(lmerTest); library(emmeans); library(ggplot2)
})

con <- file(file.path(DIR_LOG, "16_figures_extended.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

PAL <- c(brand = "#1f4e79", rep = "#c0504d", pop = "#7f7f7f",
         reputation = "#c0504d", popularity = "#7f7f7f")
LAB <- c(brand = "Developer brand", rep = "Reputation (rating)", pop = "Popularity (downloads)")

base_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "top",
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey30", size = 9),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
save_fig <- function(p, file, w = 7.4, h = 4.8) {
  ggsave(file.path(DIR_FIG, file), p, width = w, height = h, dpi = 200)
  cat("  written:", file, "\n")
}

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
# Factor version of the manipulation, needed wherever a high-vs-low contrast is
# requested: on a numeric 0/1 predictor there are no levels to contrast. The
# numeric version is kept for the random-slope model, where the slope itself is
# the effect.
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))

cat("=== EXTENDED FIGURES ===\n\n")

# --- fig 05: what the split sample cost -------------------------------------
cf   <- read.csv(file.path(DIR_TAB, "01_replication_coefficients.csv"))
fit  <- read.csv(file.path(DIR_TAB, "01_replication_modelfit.csv"))
pool <- read.csv(file.path(DIR_TAB, "04_effect_by_focal.csv"))

m1 <- cf[cf$model %in% c("M1_rep", "M1_pop", "M1_brand") &
           cf$term %in% c("x_rep", "x_pop", "x_brand"), ]
m1$focal <- sub("^M1_", "", m1$model)
m1$n     <- fit$n_used[match(m1$model, fit$model)]
a <- data.frame(focal = m1$focal, estimate = m1$estimate, se = m1$se, n = m1$n,
                approach = "thesis: one regression per cue")
b <- data.frame(focal = pool$focal, estimate = pool$estimate, se = pool$SE, n = 1473,
                approach = "one model, all three judgements")

# The middle series: the SAME quantity the thesis aimed at -- the first app
# seen, judged before any comparison -- estimated from one model on all the
# data. Without it the figure would charge to the split sample a gap that is
# partly a change of estimand. See 18_first_exposure.R.
m_sat5 <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
e5 <- summary(contrast(emmeans(m_sat5, ~ x_f | focal * position), "revpairwise"))
e5 <- e5[e5$position == "first", ]
m <- data.frame(focal = as.character(e5$focal), estimate = e5$estimate, se = e5$SE,
                n = 1473, approach = "one model, first app seen")
d5 <- rbind(a, m, b)
d5$focal <- factor(d5$focal, levels = c("brand", "rep", "pop"))
d5$approach <- factor(d5$approach, levels = unique(d5$approach))
d5$lo <- d5$estimate - 1.96 * d5$se; d5$hi <- d5$estimate + 1.96 * d5$se

p5 <- ggplot(d5, aes(estimate, focal, colour = focal, shape = approach)) +
  geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.6,
                 position = position_dodge(width = 0.5)) +
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  geom_text(aes(label = ifelse(n == 1473, "", paste0("n=", n))),
            position = position_dodge(width = 0.5),
            hjust = -0.25, vjust = 1.7, size = 2.8, show.legend = FALSE) +
  scale_y_discrete(labels = LAB, limits = rev(levels(d5$focal))) +
  scale_colour_manual(values = PAL, guide = "none") +
  scale_shape_manual(values = c(1, 17, 16), name = NULL) +
  labs(title = "What the split sample cost, and what it changed",
       subtitle = "The same three effects, estimated three ways",
       x = "Effect on intention to download (1-7 scale), 95% CI", y = NULL,
       caption = paste("Hollow: the thesis - one regression per cue, on its own subsample of first-app answers.",
                       "Triangle: the same quantity from one model on all 1,473 answers. Same question, more precision.",
                       "Solid: the average over all three judgements. A different question - and the one where brand and reputation meet.",
                       sep = "\n")) +
  base_theme
save_fig(p5, "fig_05_pooling_gain.png")

# --- fig 06: effect by presentation position --------------------------------
m_pos <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)
e6 <- as.data.frame(summary(contrast(emmeans(m_pos, ~ x_f | focal * position), "revpairwise"),
                            infer = c(TRUE, TRUE)))
e6$focal <- factor(e6$focal, levels = c("brand", "rep", "pop"))
p6 <- ggplot(e6, aes(position, estimate, colour = focal, group = focal)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.08, linewidth = 0.6) +
  geom_point(size = 3) +
  scale_colour_manual(values = PAL, name = NULL, labels = LAB) +
  scale_x_discrete(labels = c(first = "1st app seen", second = "2nd", third = "3rd")) +
  labs(title = "Each cue's effect at each point in the sequence",
       subtitle = "Effect of moving each cue from its weak to its strong version, by position",
       x = NULL, y = "Effect on intention to download (1-7 scale), 95% CI",
       caption = paste("Brand is strongest on the first app seen, reputation on the third, and popularity moves only on the first.",
                       "No difference between positions survives correction for the three comparisons - for any cue (08_equivalence.R).",
                       "Read this as the shape of a pattern, not as an established ranking by position.", sep = "\n")) +
  base_theme
save_fig(p6, "fig_06_by_position.png")

# --- fig 07: equivalence ------------------------------------------------------
eq <- read.csv(file.path(DIR_TAB, "08_equivalence.csv"))
eq$label <- sub(" \\(M2_.*\\)", "", eq$estimand)
eq$label <- factor(eq$label, levels = rev(eq$label))
eq$verdict <- factor(eq$verdict,
                     levels = c("effect present", "at the boundary", "inconclusive", "equivalent to zero"))
vpal <- c("effect present" = "#1f4e79", "at the boundary" = "#d9932c",
          "inconclusive" = "#8c8c8c", "equivalent to zero" = "#2e7d32")
p7 <- ggplot(eq, aes(estimate, label, colour = verdict)) +
  annotate("rect", xmin = -0.33, xmax = 0.33, ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
  annotate("rect", xmin = -0.26, xmax = 0.26, ymin = -Inf, ymax = Inf, fill = "grey75", alpha = 0.5) +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = ci90_lo, xmax = ci90_hi), height = 0, linewidth = 0.6) +
  geom_point(size = 2.6) +
  scale_colour_manual(values = vpal, name = NULL, drop = FALSE) +
  labs(title = "Which null results are really null?",
       subtitle = "90% intervals against the relevance band fixed before the tests were run",
       x = "Effect on intention to download (1-7 scale)", y = NULL,
       caption = paste("Shaded: the 0.26-0.33 band below which an effect has no practical meaning.",
                       "An interval inside the band means 'nothing here'; one stretching far beyond it means 'we cannot tell'.",
                       sep = "\n")) +
  base_theme + theme(axis.text.y = element_text(size = 8))
save_fig(p7, "fig_07_equivalence.png", h = 5.4)

# --- fig 08: heterogeneity ----------------------------------------------------
m_slope <- lmer(y ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 + x | subj_f),
                data = long, REML = FALSE)
re <- ranef(m_slope)$subj_f
d8 <- data.frame(baseline = re[, "(Intercept)"], sensitivity = re[, "x"])
# Report the correlation the MODEL estimates, not the correlation of the plotted
# points. Predicted individual values are shrunk towards zero by amounts that
# depend on how much each respondent's data says, which makes their apparent
# association stronger than the one being estimated (-0.83 against -0.61 here).
vc8    <- as.data.frame(VarCorr(m_slope))
r8     <- vc8$sdcor[vc8$grp == "subj_f" & !is.na(vc8$var2)][1]
r_blup <- cor(d8$baseline, d8$sensitivity)
cat(sprintf("  fig 08: model correlation = %.2f | correlation of the plotted points = %.2f\n",
            r8, r_blup))
p8 <- ggplot(d8, aes(baseline, sensitivity)) +
  geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.3) +
  geom_point(alpha = 0.45, size = 1.6, colour = "#1f4e79") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#c0504d", linewidth = 0.8) +
  labs(title = "The cues work on the undecided",
       subtitle = sprintf("Each dot is one respondent: their baseline enthusiasm against how much the cues move them (r = %.2f)", r8),
       x = "Baseline: how highly this person rates apps in general",
       y = "Sensitivity: how much\nthe cues move them",
       caption = paste("Estimated from a model that gives every respondent their own baseline and their own sensitivity.",
                       "People already inclined to download anything are moved least by what the listing shows.",
                       "Each dot is a shrunken prediction, so the cloud is tighter than the real spread of people.",
                       sep = "\n")) +
  base_theme
save_fig(p8, "fig_08_heterogeneity.png")

# --- fig 09: the answer scale -------------------------------------------------
th <- read.csv(file.path(DIR_TAB, "12_scale_thresholds.csv"))
eqsp <- seq(min(th$threshold), max(th$threshold), length.out = nrow(th))
d9 <- rbind(data.frame(boundary = th$boundary, value = th$threshold, kind = "estimated from the data"),
            data.frame(boundary = th$boundary, value = eqsp, kind = "if the scale were a ruler"))
p9 <- ggplot(d9, aes(value, kind, colour = kind)) +
  geom_line(aes(group = kind), colour = "grey70", linewidth = 0.5) +
  geom_point(size = 3) +
  geom_text(aes(label = boundary), vjust = -1.4, size = 3, show.legend = FALSE) +
  scale_colour_manual(values = c("estimated from the data" = "#1f4e79",
                                 "if the scale were a ruler" = "#8c8c8c"), guide = "none") +
  labs(title = "The 1-7 scale is not a ruler",
       subtitle = "Where each answer boundary sits on the underlying intention scale",
       x = "Underlying intention (log-odds)", y = NULL,
       caption = paste("The step into the top category is nearly twice the step into category 3:",
                       "respondents avoid the ends. Correcting for it changes the effects by under 3 percentage points.",
                       sep = "\n")) +
  base_theme + theme(axis.text.y = element_text(size = 9))
save_fig(p9, "fig_09_scale_cutpoints.png", h = 3.8)

# --- fig 10: sequence effects -------------------------------------------------
sq <- read.csv(file.path(DIR_TAB, "10_sequence_effects.csv"))
sq <- sq[sq$term %in% c("prior_mean_x", "prev_x"), ]
# Spell out what each specification measures: two of them use the same predictor
# but mean different things, and identical labels on different numbers would read
# as an error rather than as a distinction.
sq$label <- ifelse(sq$model == "A: prior mean level",
                   "average strength of the apps seen earlier",
            ifelse(sq$model == "B: interaction with history",
                   "the same, but only when the current app is weak",
                   "strength of the app seen immediately before"))
sq$label <- factor(sq$label, levels = rev(c(
  "average strength of the apps seen earlier",
  "the same, but only when the current app is weak",
  "strength of the app seen immediately before")))
sq$lo <- sq$estimate - 1.96 * sq$se; sq$hi <- sq$estimate + 1.96 * sq$se
p10 <- ggplot(sq, aes(estimate, label)) +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.6, colour = "#1f4e79") +
  geom_point(size = 2.8, colour = "#1f4e79") +
  labs(title = "Does a strong app make the next one look worse?",
       subtitle = "Every estimate points the same way; none of them settles the question",
       x = "Effect on intention to download (1-7 scale), 95% CI", y = NULL,
       caption = paste("Left of zero means contrast: apps shown after strong ones are rated lower.",
                       "Consistent in direction across all three specifications, significant in none that stands on its own.",
                       sep = "\n")) +
  base_theme + theme(axis.text.y = element_text(size = 8))
save_fig(p10, "fig_10_sequence.png", h = 3.6)

# --- fig 11: response quality -------------------------------------------------
qf <- file.path(DIR_TAB, "13_quality.csv")
if (file.exists(qf)) {
  q <- read.csv(qf)
  q$focal <- factor(q$focal, levels = c("brand", "rep", "pop"))
  p11 <- ggplot(q, aes(estimate, focal, colour = focal, shape = sample)) +
    geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
    geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0, linewidth = 0.6,
                   position = position_dodge(width = 0.5)) +
    geom_point(size = 3, position = position_dodge(width = 0.5)) +
    scale_y_discrete(labels = LAB, limits = rev(levels(q$focal))) +
    scale_colour_manual(values = PAL, guide = "none") +
    scale_shape_manual(values = c(16, 1), name = NULL) +
    labs(title = "Rushed and careless answers change nothing",
         subtitle = "33 respondents removed: the fastest 5%, and those giving one answer to a whole scale",
         x = "Effect on intention to download (1-7 scale), 95% CI", y = NULL,
         caption = "Every effect moves slightly up, as expected when noise is removed, and none moves enough to matter.") +
    base_theme
  save_fig(p11, "fig_11_quality.png", h = 4.2)
} else cat("  skipped fig_11: run 13_demographics_quality.R first\n")

# --- fig 12: demographics ------------------------------------------------------
raw <- Sys.getenv("RAW_EXPORT")
if (raw != "" && file.exists(raw)) {
  ex <- read.csv(raw, sep = ";", quote = "\"", fileEncoding = "UTF-8", check.names = FALSE)
  sub <- data.frame(subject = ex$lfdn,
                    occupation = factor(ifelse(ex$v_4 == 1, "student",
                                        ifelse(ex$v_4 %in% 2:4, "employed", "other")),
                                        levels = c("student", "employed", "other")))
  d <- merge(long, sub, by = "subject")
  m <- lmer(y ~ focal * x_f * occupation + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
            data = d, REML = FALSE)
  e12 <- as.data.frame(summary(contrast(emmeans(m, ~ x_f | focal * occupation), "revpairwise"),
                               infer = c(TRUE, TRUE)))
  e12$focal <- factor(e12$focal, levels = c("brand", "rep", "pop"))
  p12 <- ggplot(e12, aes(estimate, focal, colour = focal)) +
    geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
    geom_errorbarh(aes(xmin = lower.CL, xmax = upper.CL), height = 0, linewidth = 0.6) +
    geom_point(size = 2.8) +
    facet_wrap(~ occupation, ncol = 3) +
    scale_y_discrete(labels = LAB, limits = rev(levels(e12$focal))) +
    scale_colour_manual(values = PAL, guide = "none") +
    labs(title = "Does it depend on who is looking? Not measurably",
         subtitle = "Cue effects by occupation. The difference between groups is not significant (p = 0.09)",
         x = "Effect on intention to download (1-7 scale), 95% CI", y = NULL,
         caption = paste("Students respond to reputation about twice as strongly as employed respondents, and are the",
                         "only group for whom popularity registers - a tidy story that does not pass its own test.",
                         sep = "\n")) +
    base_theme
  save_fig(p12, "fig_12_demographics.png", h = 4.2)
} else cat("  skipped fig_12: RAW_EXPORT not set\n")

cat("\nfigures now in", DIR_FIG, ":\n")
print(list.files(DIR_FIG))

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/16_figures_extended.log\n")
