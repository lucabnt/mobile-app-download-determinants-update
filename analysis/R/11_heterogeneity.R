# 11_heterogeneity.R ---------------------------------------------------------
# Work plan task 2.2 — is the reaction to the cues the same for everyone?
#
# QUESTION. Every model so far estimates one average effect per cue. That
# average could describe everybody, or it could hide two groups: people who
# react strongly to brand and people who ignore it entirely.
#
# WHY IT MATTERS. The ICC of 0.41 says respondents differ a lot in HOW HIGH they
# rate apps in general. It says nothing about whether they differ in HOW MUCH
# the cues move them, and only the second question has practical consequences:
# if half the sample ignores ratings, the average understates the effect for the
# other half.
#
# METHOD, IN PLAIN TERMS. A random-INTERCEPT model gives each respondent their
# own baseline: some people are simply more enthusiastic about apps. A random-
# SLOPE model additionally gives each respondent their own sensitivity to the
# manipulation. If sensitivities genuinely differ, the second model fits better
# than chance would allow, and a likelihood-ratio test detects it.
#
# LIMIT STATED IN ADVANCE. Each respondent contributes three observations, one
# per cue. A negative result is therefore a result about the design, not about
# people, and is reported as such rather than chased with ever simpler
# specifications until something turns significant.
#
# Output: analysis/outputs/tables/11_heterogeneity.csv
#         analysis/outputs/logs/11_heterogeneity.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4) })

con <- file(file.path(DIR_LOG, "11_heterogeneity.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)

n_obs  <- nrow(long)
n_subj <- nlevels(long$subj_f)
cat("=== BETWEEN-RESPONDENT HETEROGENEITY ===\n\n")
cat("observations:", n_obs, "| respondents:", n_subj,
    "| observations per respondent:", n_obs / n_subj, "\n")

fit <- function(re) lmer(as.formula(paste("y ~ focal * x + position + inv_app + inv_dl + inv_cat +",
                                          re)), data = long, REML = FALSE)

# A model is only estimable if each respondent supplies more observations than
# the model asks them to support. Count the random effects per respondent first,
# then let lme4 confirm it.
specs <- list(
  list(re = "(1 | subj_f)",       label = "random intercept only",                 k = 1),
  list(re = "(1 + x | subj_f)",   label = "+ own sensitivity to the manipulation",  k = 2),
  list(re = "(1 + focal | subj_f)", label = "+ own level for each cue",             k = 3))

cat("\n--- What each specification asks of a single respondent ---\n")
for (s in specs) {
  cat(sprintf("  %-42s %d random effect(s) per respondent, %d observations each -> %s\n",
              s$label, s$k, n_obs / n_subj,
              ifelse(s$k < n_obs / n_subj, "estimable", "saturated, not estimable")))
}

models <- list()
for (s in specs) {
  res <- tryCatch(list(m = fit(s$re), err = NA_character_),
                  error = function(e) list(m = NULL, err = conditionMessage(e)))
  models[[s$label]] <- res
  cat("\n---", s$label, "---\n")
  if (is.null(res$m)) {
    cat("NOT ESTIMABLE. lme4 reports:\n  ", res$err, "\n")
  } else {
    vc <- as.data.frame(VarCorr(res$m))
    print(vc[, c("grp", "var1", "var2", "vcov", "sdcor")], digits = 4, row.names = FALSE)
    cat("singular fit (a variance estimated at exactly zero):", isSingular(res$m), "\n")
  }
}

m0 <- models[[specs[[1]]$label]]$m
cat("\n\n=== DOES ALLOWING INDIVIDUAL SENSITIVITY IMPROVE THE FIT? ===\n")
cat("Likelihood-ratio test against the random-intercept model. The p-value is\n")
cat("conservative here, because testing a variance at its lower boundary of zero\n")
cat("makes the standard test too strict: a non-significant result is genuinely\n")
cat("non-significant.\n")

rows <- list()
for (s in specs) {
  r <- models[[s$label]]
  if (is.null(r$m)) {
    rows[[s$label]] <- data.frame(model = s$label, estimable = FALSE, singular = NA,
                                  n_parameters = NA, logLik = NA, AIC = NA,
                                  lrt_chisq = NA, lrt_df = NA, lrt_p = NA)
    next
  }
  a <- if (identical(s$label, specs[[1]]$label)) NULL else anova(m0, r$m)
  if (!is.null(a)) { cat("\n", s$label, ":\n", sep = ""); print(a) }
  rows[[s$label]] <- data.frame(
    model = s$label, estimable = TRUE, singular = isSingular(r$m),
    n_parameters = attr(logLik(r$m), "df"), logLik = as.numeric(logLik(r$m)), AIC = AIC(r$m),
    lrt_chisq = if (is.null(a)) NA else a$Chisq[2],
    lrt_df    = if (is.null(a)) NA else a$Df[2],
    lrt_p     = if (is.null(a)) NA else a$`Pr(>Chisq)`[2])
}
out <- do.call(rbind, rows)

vc0 <- as.data.frame(VarCorr(m0))
cat(sprintf("\n=== HOW MUCH VARIANCE SITS BETWEEN RESPONDENTS? ===\n  ICC = %.4f\n",
            vc0$vcov[1] / sum(vc0$vcov)))

cat("\n=== SUMMARY ===\n")
print(out, digits = 4, row.names = FALSE)
write.csv(out, file.path(DIR_TAB, "11_heterogeneity.csv"), row.names = FALSE)

# The reading follows the test instead of preceding it. Until 2026-09-18 this
# block was fixed text written before the model was run, predicting that the
# sensitivity question could not be answered; the log then printed that
# prediction directly under a significant test. The prediction is kept, in
# docs/02-work-plan.md task 2.2, as a record of what was expected.
slope_p <- out$lrt_p[out$model == "+ own sensitivity to the manipulation"]
cat("\n=== HOW TO READ THIS ===\n")
cat("Respondents clearly differ in their baseline enthusiasm.\n")
if (isTRUE(slope_p < 0.05)) {
  cat(sprintf("They also differ in their SENSITIVITY to the cues: letting each respondent\n"))
  cat(sprintf("have their own effect of the manipulation improves the fit (p = %.4f,\n", slope_p))
  cat("conservative at the boundary). That answers the question for sensitivity\n")
  cat("to the manipulation in general, not cue by cue.\n")
} else {
  cat(sprintf("Individual sensitivity to the cues is not established (p = %.3f).\n", slope_p))
}
cat("The cue-by-cue version cannot be estimated at all: the third specification\n")
cat("is saturated by construction - each person sees each cue exactly once, so a\n")
cat("per-person level for each cue would need as many parameters as there are\n")
cat("observations. Answering it needs several apps per cue per respondent.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/11_heterogeneity.log\n")
