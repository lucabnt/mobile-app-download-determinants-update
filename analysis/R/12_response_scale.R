# 12_response_scale.R --------------------------------------------------------
# Work plan task 2.7 — is the 1-7 answer scale used as if it were a ruler?
#
# QUESTION. Every model in the thesis treats the intention scale as if the step
# from 1 to 2 meant the same as the step from 6 to 7. Respondents may not use it
# that way: people often avoid the extremes and crowd around the middle.
#
# WHY IT MATTERS. If the middle of the scale is compressed, ordinary regression
# distorts SMALL effects most - and the smallest effect in this study is exactly
# the one the whole popularity argument turns on.
#
# METHOD, IN PLAIN TERMS. An ordinal model does not assume the spacing. It
# imagines one continuous "intention" behind the answers and estimates six
# CUTPOINTS on it: below the first cutpoint a respondent answers 1, between the
# first and the second they answer 2, and so on. If the scale were a ruler, the
# cutpoints would be equally spaced. Measuring how unequal they are tells us how
# far the ruler assumption is from the data; re-estimating the effects on a
# scale that does not depend on the spacing tells us whether it matters.
#
# Output: analysis/outputs/tables/12_scale_thresholds.csv
#         analysis/outputs/tables/12_scale_effects.csv
#         analysis/outputs/logs/12_response_scale.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4); library(ordinal) })

con <- file(file.path(DIR_LOG, "12_response_scale.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$y_ord    <- factor(long$y, levels = 1:7, ordered = TRUE)

cat("=== HOW RESPONDENTS USE THE 1-7 SCALE ===\n\n")
cat("observed distribution of answers:\n")
print(table(long$y))
cat("\nshare of answers at the two extremes (1 or 7):",
    sprintf("%.1f%%", 100 * mean(long$y %in% c(1, 7))),
    "| at the midpoint (4):", sprintf("%.1f%%", 100 * mean(long$y == 4)), "\n")

# --- 1. the cutpoints --------------------------------------------------------
m_ord <- clmm(y_ord ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, link = "logit")
th   <- m_ord$Theta
if (is.matrix(th)) th <- as.numeric(th[1, ]) else th <- as.numeric(th)
names(th) <- paste0(1:6, "|", 2:7)
se_th <- coef(summary(m_ord))[names(th), 2]

widths <- diff(th)
equal  <- rep(mean(widths), length(widths))
tab <- data.frame(boundary = names(th), threshold = th, se = se_th,
                  width_to_next = c(widths, NA), equal_width = c(equal, NA),
                  ratio_to_equal = c(widths / mean(widths), NA), row.names = NULL)
cat("\n--- Estimated cutpoints of the latent intention scale ---\n")
print(tab, digits = 3, row.names = FALSE)
write.csv(tab, file.path(DIR_TAB, "12_scale_thresholds.csv"), row.names = FALSE)

cat(sprintf("\nWidest category is %.2f times the narrowest (%s vs %s).\n",
            max(widths) / min(widths),
            names(widths)[which.max(widths)], names(widths)[which.min(widths)]))
cat("A perfect ruler would give a ratio of 1. The wider a category, the more\n")
cat("underlying intention has to change before the answer moves by one point.\n")

# --- 2. does the spacing change the conclusions? -----------------------------
# Two ways of asking "how much does the manipulation move intention", one that
# assumes equal spacing and one that does not, put on a common footing: the
# effect on the probability of answering 5 or more (a "would probably download"
# answer), for an average respondent.
cat("\n\n--- Effect on the probability of answering 5 or more ---\n")
cat("Linear model: the manipulation effect on a 0/1 indicator (y >= 5), which is\n")
cat("constant by construction.\n")
cat("Ordinal model: the same quantity implied by the cutpoints, computed for each\n")
cat("observation at that respondent's own characteristics and then averaged.\n\n")

long$top <- as.integer(long$y >= 5)
m_lin <- lmer(top ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = FALSE)
cl <- summary(m_lin)$coefficients
lin_eff <- c(brand = cl["x", 1],
             rep   = cl["x", 1] + cl["focalrep:x", 1],
             pop   = cl["x", 1] + cl["focalpop:x", 1])

# Average marginal effect. For EVERY observation we compute the probability of
# answering 5 or more with the cue low and with it high, holding that
# respondent's own characteristics fixed, and then average the difference.
# Evaluating a single "reference respondent" instead would place each cue at a
# different point of the S-shaped probability curve, where the same shift in
# underlying intention produces a different change in the answer - which would
# make the three cues incomparable for reasons that have nothing to do with the
# scale.
cf    <- coef(summary(m_ord))
g     <- function(nm) if (nm %in% rownames(cf)) cf[nm, 1] else 0
u     <- ranef(m_ord)$subj_f[[1]]
names(u) <- rownames(ranef(m_ord)$subj_f)
eta0 <- with(long,
  g("focalrep") * (focal == "rep") + g("focalpop") * (focal == "pop") +
  g("positionsecond") * (position == "second") + g("positionthird") * (position == "third") +
  g("inv_app") * inv_app + g("inv_dl") * inv_dl + g("inv_cat") * inv_cat +
  u[as.character(subject)])
cue <- with(long, g("x") + g("focalrep:x") * (focal == "rep") + g("focalpop:x") * (focal == "pop"))
cut45   <- th["4|5"]
p_low   <- 1 - plogis(cut45 - eta0)
p_high  <- 1 - plogis(cut45 - (eta0 + cue))
ord_eff <- tapply(p_high - p_low, long$focal, mean)[c("brand", "rep", "pop")]

eff <- data.frame(focal = names(lin_eff),
                  linear_pp = 100 * lin_eff,
                  ordinal_pp = 100 * ord_eff,
                  difference_pp = 100 * (ord_eff - lin_eff))
print(eff, digits = 3, row.names = FALSE)
write.csv(eff, file.path(DIR_TAB, "12_scale_effects.csv"), row.names = FALSE)
cat("\nBoth columns are percentage points. If they agree, the equal-spacing\n")
cat("assumption is not driving any conclusion of this review.\n")

# --- 3. response style -------------------------------------------------------
cat("\n\n--- Do some respondents simply prefer the extremes? ---\n")
ext <- tapply(long$y %in% c(1, 2, 6, 7), long$subject, mean)
long$extremeness <- as.numeric(ext[as.character(long$subject)])
cat("share of respondents using no extreme answer at all:",
    sprintf("%.1f%%", 100 * mean(ext == 0)),
    "| all three extreme:", sprintf("%.1f%%", 100 * mean(ext == 1)), "\n\n")
m_sty <- lmer(y ~ focal * x + x * extremeness + position + inv_app + inv_dl + inv_cat +
                (1 | subj_f), data = long, REML = FALSE)
print(summary(m_sty)$coefficients[c("x", "extremeness", "x:extremeness"), ])
cat("\nLIMIT. With three answers per respondent, 'extremeness' is measured from\n")
cat("three points and is itself partly a consequence of the treatment, so this\n")
cat("is a description, not a clean test.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/12_response_scale.log\n")
