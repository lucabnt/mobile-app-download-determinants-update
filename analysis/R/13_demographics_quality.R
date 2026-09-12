# 13_demographics_quality.R --------------------------------------------------
# Work plan tasks 3.1 and 3.3, unlocked by the raw questionnaire export.
#
# TASK 3.1 - does the effect of each cue differ by age, gender, education or
# occupation? The thesis describes its sample demographically but never uses
# those variables in a model; they are not even in the published datasets.
#
# TASK 3.3 - response quality. Some respondents answered very fast, and some
# gave the same answer to every item of a scale. Do the conclusions depend on
# keeping them?
#
# METHOD, IN PLAIN TERMS. For each background variable we compare two models:
# one where the cue effects are the same for everybody, and one where they are
# allowed to differ by group. A likelihood-ratio test asks whether the second
# fits better than chance would allow. Categories are collapsed first, because
# the original ones are too thin to estimate anything (69% of the sample are
# students, so "occupation" is really "student or not").
#
# The raw export holds personal data and is NOT in this repository: set
# RAW_EXPORT to a private copy. Without it the script exits cleanly.
#
# Output: analysis/outputs/tables/13_demographics.csv
#         analysis/outputs/tables/13_quality.csv
#         analysis/outputs/logs/13_demographics_quality.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4); library(emmeans) })

raw <- Sys.getenv("RAW_EXPORT")
if (raw == "" || !file.exists(raw)) {
  cat("RAW_EXPORT not set or file not found: skipping (the raw export is private).\n")
  quit(save = "no", status = 0)
}

con <- file(file.path(DIR_LOG, "13_demographics_quality.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

ex   <- read.csv(raw, sep = ";", quote = "\"", fileEncoding = "UTF-8", check.names = FALSE)
long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)

# --- background variables, collapsed ----------------------------------------
inv_items <- paste0("v_", 168:175)
sub <- data.frame(
  subject    = ex$lfdn,
  age        = factor(ifelse(ex$v_1 %in% 1:2, "under 25", "25 or older"),
                      levels = c("under 25", "25 or older")),
  gender     = factor(ifelse(ex$v_2 == 1, "female",
                      ifelse(ex$v_2 == 2, "male", "other or undisclosed")),
                      levels = c("female", "male", "other or undisclosed")),
  education  = factor(ifelse(ex$v_3 %in% 1:2, "high school or less",
                      ifelse(ex$v_3 == 3, "bachelor",
                      ifelse(ex$v_3 %in% 4:5, "master or above", "other"))),
                      levels = c("high school or less", "bachelor", "master or above", "other")),
  occupation = factor(ifelse(ex$v_4 == 1, "student",
                      ifelse(ex$v_4 %in% 2:4, "employed", "other")),
                      levels = c("student", "employed", "other")),
  duration   = ex$duration,
  flat_scale = apply(ex[, inv_items], 1, function(r) length(unique(r)) == 1))

d <- merge(long, sub, by = "subject")
stopifnot(nrow(d) == nrow(long))

cat("=== DEMOGRAPHICS AND RESPONSE QUALITY ===\n\n")
cat("respondents:", length(unique(d$subject)), "\n\n")
for (v in c("age", "gender", "education", "occupation")) {
  one <- d[!duplicated(d$subject), ]
  cat(sprintf("%-11s ", v)); print(table(one[[v]]))
}

# --- 3.1 does the cue effect differ by group? -------------------------------
cat("\n\n=== 3.1 DOES THE EFFECT OF A CUE DEPEND ON WHO IS LOOKING? ===\n")
cat("Each row compares a model where the cue effects are common to everybody with\n")
cat("one where they may differ by group. A small p-value would mean they differ.\n\n")

base_rhs <- "focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f)"
m_base <- lmer(as.formula(paste("y ~", base_rhs)), data = d, REML = FALSE)
rows <- list()
for (v in c("age", "gender", "education", "occupation")) {
  m_int <- lmer(as.formula(paste("y ~ focal * x *", v, "+ position + inv_app + inv_dl + inv_cat + (1 | subj_f)")),
                data = d, REML = FALSE)
  a <- anova(m_base, m_int)
  rows[[v]] <- data.frame(variable = v, chisq = a$Chisq[2], df = a$Df[2],
                          p_value = a$`Pr(>Chisq)`[2], aic_common = AIC(m_base),
                          aic_by_group = AIC(m_int))
  cat(sprintf("  %-11s chi2 = %6.2f on %2d df, p = %.4f\n", v, a$Chisq[2], a$Df[2], a$`Pr(>Chisq)`[2]))
}
dem <- do.call(rbind, rows)
write.csv(dem, file.path(DIR_TAB, "13_demographics.csv"), row.names = FALSE)

best <- dem$variable[which.min(dem$p_value)]
cat(sprintf("\nSmallest p-value: %s. Cue effects within its groups:\n", best))
m_best <- lmer(as.formula(paste("y ~ focal * x *", best,
                                "+ position + inv_app + inv_dl + inv_cat + (1 | subj_f)")),
               data = d, REML = FALSE)
print(summary(contrast(emmeans(m_best, as.formula(paste("~ x | focal *", best))), "revpairwise"),
              infer = c(TRUE, TRUE)), digits = 3)

# --- 3.3 response quality ----------------------------------------------------
cat("\n\n=== 3.3 RESPONSE QUALITY ===\n")
one <- d[!duplicated(d$subject), ]
fast_cut <- as.numeric(quantile(one$duration[one$duration > 0], 0.05))
cat(sprintf("completion time: median %.0f s, 5th percentile %.0f s, not recorded for %d respondents\n",
            median(one$duration[one$duration > 0]), fast_cut, sum(one$duration < 0)))
cat("respondents who gave the same answer to all eight items of the category scale:",
    sum(one$flat_scale), "\n")

d$low_quality <- (d$duration > 0 & d$duration < fast_cut) | d$flat_scale
cat("flagged as low quality (fast OR flat scale):", sum(!duplicated(d$subject) & d$low_quality),
    "respondents\n\n")

eff <- function(dat, tag) {
  m <- lmer(as.formula(paste("y ~", base_rhs)), data = dat, REML = FALSE)
  e <- as.data.frame(summary(contrast(emmeans(m, ~ x | focal), "revpairwise"),
                             infer = c(TRUE, TRUE)))
  data.frame(sample = tag, focal = e$focal, estimate = e$estimate, se = e$SE,
             ci_lo = e$lower.CL, ci_hi = e$upper.CL, p_value = e$p.value)
}
q <- rbind(eff(d, "all respondents"),
           eff(d[!d$low_quality, ], "low-quality respondents removed"))
print(q, digits = 3, row.names = FALSE)
write.csv(q, file.path(DIR_TAB, "13_quality.csv"), row.names = FALSE)
cat("\nIf the two blocks agree, the conclusions do not rest on the respondents who\n")
cat("rushed or answered flatly.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/13_demographics_quality.log\n")
