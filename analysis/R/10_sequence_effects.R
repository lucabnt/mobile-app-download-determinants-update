# 10_sequence_effects.R ------------------------------------------------------
# Work plan task 2.1 — sequence and anchoring effects.
#
# QUESTION. Does the intention to download an app depend on WHICH apps the
# respondent saw before it, and not merely on whether they saw any?
#
# WHY IT MATTERS. The thesis asked a version of this with Model 2, but only on
# the 143-196 observations of the third screen. Every respondent saw three
# screens, and the level shown on each was randomised independently, so the
# levels seen earlier are exogenous: they can be used as predictors without the
# usual worry that they reflect something about the respondent. In long format
# this uses all 982 observations with position > 1.
#
# TWO COMPETING PATTERNS.
#   contrast     - a strong app seen earlier makes the current one look worse
#                  (negative coefficient on what came before)
#   assimilation - a strong app seen earlier lifts the current one
#                  (positive coefficient)
#
# Output: analysis/outputs/tables/10_sequence_effects.csv
#         analysis/outputs/logs/10_sequence_effects.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4); library(lmerTest) })

con <- file(file.path(DIR_LOG, "10_sequence_effects.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal  <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$subj_f <- factor(long$subject)
long <- long[order(long$subject, long$pos_num), ]

# --- build the history variables --------------------------------------------
# prior_mean_x : average level (0/1) of the apps seen BEFORE this one
# prev_x       : level of the app seen immediately before
# prev_focal   : which cue was manipulated in the app seen immediately before
sp <- split(long, long$subject)
long <- do.call(rbind, lapply(sp, function(d) {
  d <- d[order(d$pos_num), ]
  d$prior_mean_x <- c(NA, cumsum(d$x)[-nrow(d)] / seq_len(nrow(d) - 1))
  d$prev_x       <- c(NA, head(d$x, -1))
  d$prev_focal   <- c(NA, as.character(head(d$focal, -1)))
  d
}))
long$prev_focal <- factor(long$prev_focal, levels = c("brand", "rep", "pop"))
later <- long[long$pos_num > 1, ]
later$position <- factor(later$pos_num, levels = 2:3, labels = c("second", "third"))

cat("=== SEQUENCE AND ANCHORING EFFECTS ===\n\n")
cat("observations with at least one app seen before:", nrow(later), "\n")
cat("distribution of prior_mean_x (average level seen earlier):\n")
print(round(prop.table(table(round(later$prior_mean_x, 2))), 3))
cat("\nCheck that the history is exogenous: it must be unrelated to who the\n")
cat("respondent is, because the levels were randomised. Correlation of\n")
cat("prior_mean_x with the three involvement measures:\n")
print(round(sapply(later[, c("inv_app", "inv_dl", "inv_cat")],
                   function(v) cor(v, later$prior_mean_x)), 4))

rows <- list()
tidy <- function(m, label, terms) {
  cf <- summary(m)$coefficients
  keep <- intersect(terms, rownames(cf))
  data.frame(model = label, term = keep, estimate = cf[keep, 1], se = cf[keep, 2],
             df = cf[keep, 3], p_value = cf[keep, 5], row.names = NULL)
}

cat("\n\n--- Model A: does the average level seen earlier shift the current ITD? ---\n")
cat("y ~ focal * x + position + prior_mean_x + involvement + (1 | subject)\n\n")
mA <- lmer(y ~ focal * x + position + prior_mean_x + inv_app + inv_dl + inv_cat +
             (1 | subj_f), data = later, REML = FALSE)
print(summary(mA)$coefficients)
mA0 <- lmer(y ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
            data = later, REML = FALSE)
cat("\nLikelihood-ratio test for adding the history term:\n")
print(anova(mA0, mA))
rows$A <- tidy(mA, "A: prior mean level", "prior_mean_x")

cat("\n\n--- Model B: does what came before change how much the current cue matters? ---\n")
cat("as model A, plus x * prior_mean_x\n\n")
mB <- lmer(y ~ focal * x + x * prior_mean_x + position + inv_app + inv_dl + inv_cat +
             (1 | subj_f), data = later, REML = FALSE)
print(summary(mB)$coefficients)
cat("\nLikelihood-ratio test for adding the interaction:\n")
print(anova(mA, mB))
rows$B <- tidy(mB, "B: interaction with history", c("prior_mean_x", "x:prior_mean_x"))

cat("\n\n--- Model C: only the app seen immediately before ---\n")
cat("y ~ focal * x + position + prev_x + prev_focal + involvement + (1 | subject)\n\n")
mC <- lmer(y ~ focal * x + position + prev_x + prev_focal + inv_app + inv_dl + inv_cat +
             (1 | subj_f), data = later, REML = FALSE)
print(summary(mC)$coefficients)
rows$C <- tidy(mC, "C: immediate predecessor", c("prev_x", "prev_focalrep", "prev_focalpop"))

out <- do.call(rbind, rows)
out$reading <- ifelse(out$term %in% c("prior_mean_x", "prev_x"),
                      ifelse(out$estimate < 0, "contrast", "assimilation"), "-")
cat("\n\n=== SUMMARY ===\n")
print(out, digits = 3, row.names = FALSE)
write.csv(out, file.path(DIR_TAB, "10_sequence_effects.csv"), row.names = FALSE)

cat("\nA negative coefficient on prior_mean_x or prev_x means CONTRAST: apps shown\n")
cat("after strong ones are rated lower. A positive one means ASSIMILATION.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/10_sequence_effects.log\n")
