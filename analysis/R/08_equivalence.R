# 08_equivalence.R -----------------------------------------------------------
# Step 2A, claim 2: how solid is the popularity null, and the other null results
# the thesis reports?
#
# Equivalence rule, fixed on 2026-09-12 BEFORE running this script (work plan,
# "Next step — Step 2A"). A single SESOI cannot settle the question: every
# defensible anchor lands between 0.26 and 0.33 Likert points (0.166-0.210 s.d.
# of the popularity outcome). So each estimate is judged on its FLIP POINT — the
# smallest symmetric bound at which the 90% CI still fits inside:
#   flip below the band  -> equivalent to zero under every defensible threshold
#   flip above the band  -> inconclusive under every defensible threshold
#   flip inside the band -> at the boundary
# If the 95% CI excludes zero the estimate is labelled "effect present" instead.
#
# Also runs the reporting test (task 2.4, point 1): is what a respondent says
# they looked at on slide 6 itself affected by the manipulation?
#
# Output: analysis/outputs/tables/08_equivalence.csv
#         analysis/outputs/tables/08_reporting_test.csv
#         analysis/outputs/logs/08_equivalence.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4); library(emmeans) })

con <- file(file.path(DIR_LOG, "08_equivalence.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

BAND_POINTS <- c(0.26, 0.33)   # defensible band for the popularity outcome

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
long$comp_f   <- factor(long$comp, levels = c(0, 1), labels = c("shown_first", "after_others"))

sd_y   <- tapply(long$y, long$focal, sd)
BAND   <- BAND_POINTS / sd_y[["pop"]]            # the band in s.d. units
cat("=== EQUIVALENCE RULE (fixed before running) ===\n")
cat(sprintf("band: %.2f-%.2f Likert points on the popularity outcome (s.d. = %.4f)\n",
            BAND_POINTS[1], BAND_POINTS[2], sd_y[["pop"]]))
cat(sprintf("     = %.4f-%.4f s.d., applied in s.d. units to every other outcome\n\n", BAND[1], BAND[2]))

verdict <- function(label, est, se, df, focal, unit = "points") {
  s  <- sd_y[[focal]]
  lo <- BAND[1] * s; hi <- BAND[2] * s
  t90 <- qt(0.95, df); t95 <- qt(0.975, df)
  flip <- max(abs(est - t90 * se), abs(est + t90 * se))
  sig  <- abs(est) - t95 * se > 0
  lab  <- if (sig) "effect present" else if (flip < lo) "equivalent to zero" else
          if (flip > hi) "inconclusive" else "at the boundary"
  data.frame(estimand = label, focal = focal, unit = unit,
             estimate = est, se = se, df = df,
             ci90_lo = est - t90 * se, ci90_hi = est + t90 * se,
             flip_point = flip, band_lo = lo, band_hi = hi,
             p_value = 2 * pt(abs(est / se), df, lower.tail = FALSE),
             verdict = lab, row.names = NULL)
}

res <- list()

# --- 1. The popularity effect, overall and by comparison ---------------------
m_pool <- lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
e1 <- as.data.frame(summary(contrast(emmeans(m_pool, ~ x_f | focal), "revpairwise")))
p1 <- e1[e1$focal == "pop", ]
res$pop_overall <- verdict("popularity effect, all observations", p1$estimate, p1$SE, p1$df, "pop")

m_comp <- lmer(y ~ focal * x_f * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
e2 <- as.data.frame(summary(contrast(emmeans(m_comp, ~ x_f | focal * comp_f), "revpairwise")))
for (cc in c("shown_first", "after_others")) {
  r <- e2[e2$focal == "pop" & e2$comp_f == cc, ]
  res[[paste0("pop_", cc)]] <- verdict(paste("popularity effect,", sub("_", " ", cc)),
                                       r$estimate, r$SE, r$df, "pop")
}

# --- 2. The six two-way interactions between focal variables (thesis M2) -----
cf  <- read.csv(file.path(DIR_TAB, "01_replication_coefficients.csv"))
fit <- read.csv(file.path(DIR_TAB, "01_replication_modelfit.csv"))
inter <- cf[grepl("^M2_", cf$model) & grepl("x_(rep|pop|brand):x_(rep|pop|brand)", cf$term), ]
for (i in seq_len(nrow(inter))) {
  f  <- sub("^M2_", "", inter$model[i])
  df <- fit$df2[fit$model == inter$model[i]]
  res[[paste0("m2_", i)]] <- verdict(paste0("M2 interaction ", inter$term[i], " (", inter$model[i], ")"),
                                     inter$estimate[i], inter$se[i], df, f)
}

# --- 3. The two involvement moderations that do not replicate ---------------
# Expressed as the change in the manipulation effect per +1 s.d. of the moderator,
# so that the band (defined on the ITD scale) applies.
m_inv <- lmer(y ~ focal * x_f * inv_app + focal * x_f * inv_dl + focal * x_f * inv_cat +
                position + (1 | subj_f), data = long, REML = FALSE)
sd_inv <- c(inv_app = sd(long$inv_app), inv_dl = sd(long$inv_dl), inv_cat = sd(long$inv_cat))
for (spec in list(c("inv_dl", "rep"), c("inv_cat", "brand"))) {
  v <- spec[1]; f <- spec[2]
  tr <- as.data.frame(summary(contrast(emtrends(m_inv, ~ x_f | focal, var = v), "revpairwise")))
  r  <- tr[tr$focal == f, ]
  res[[paste0("mod_", v, "_", f)]] <-
    verdict(sprintf("moderation %s on %s (per +1 s.d.)", v, f),
            r$estimate * sd_inv[[v]], r$SE * sd_inv[[v]], r$df, f)
}

out <- do.call(rbind, res)
print(out[, c("estimand", "estimate", "se", "ci90_lo", "ci90_hi", "flip_point",
              "band_lo", "band_hi", "p_value", "verdict")], digits = 3, row.names = FALSE)
write.csv(out, file.path(DIR_TAB, "08_equivalence.csv"), row.names = FALSE)

cat("\n=== VERDICT COUNTS ===\n"); print(table(out$verdict))

# --- 4. Reporting test (task 2.4, point 1) ----------------------------------
cat("\n\n=== REPORTING TEST: is slide 6 itself affected by the manipulation? ===\n")
cat("Logistic mixed model manip_ok ~ focal * x + (1|subject), all three focal variables.\n")
cat("The checks count 1, 2 and 3 boxes, so high-vs-low is compared WITHIN a focal\n")
cat("variable and never across them.\n\n")
m_rep <- glmer(manip_ok ~ focal * x_f + (1 | subj_f), data = long, family = binomial)
print(summary(m_rep)$coefficients)
rt <- as.data.frame(summary(contrast(emmeans(m_rep, ~ x_f | focal), "revpairwise"),
                            type = "response", infer = c(TRUE, TRUE)))
cat("\nOdds of ticking the matching box, high vs low:\n")
print(rt, digits = 3, row.names = FALSE)
write.csv(rt, file.path(DIR_TAB, "08_reporting_test.csv"), row.names = FALSE)
cat("\nIf the high level raises the odds of reporting the cue, the subgroup split in\n")
cat("section 3.3 of the review conditions on a variable the treatment moves, and must\n")
cat("be downgraded from 'fragile null' to illustration only.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/08_equivalence.log\n")
