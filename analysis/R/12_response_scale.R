# 12_response_scale.R --------------------------------------------------------
# Work plan task 2.7 — is the 1-7 answer scale used as if it were a ruler?
#
# Compare flexible and equidistant thresholds within the same proportional-odds
# random-intercept model. This tests a latent threshold restriction, not every
# assumption of OLS on scores 1-7. Separately retain the binary-outcome check.
# Practical sensitivity is measured on P(y >= 5), averaged over the observed
# covariates and integrated over each model's fitted random-intercept distribution.
# These are descriptive point-estimate differences, not equivalence tests.
# Documentation: https://search.r-project.org/CRAN/refmans/ordinal/html/clmm.html
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
              data = long, link = "logit", threshold = "flexible", nAGQ = 7, Hess = TRUE,
              control = clmm.control(gradTol = 1e-7, rel.tol = 1e-11, iter.max = 500, eval.max = 1000))
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

# widths[k] is the distance between cutpoints k|k+1 and k+1|k+2, i.e. the span
# of latent intention over which the answer is k+1. Labelled by that answer: the
# earlier label printed the upper cutpoint's name, which read as a category one
# step off.
cat(sprintf("\nWidest answer category is %.2f times the narrowest (answer %d vs answer %d).\n",
            max(widths) / min(widths), which.max(widths) + 1L, which.min(widths) + 1L))
cat("Equidistant latent thresholds give a ratio of 1. The wider a category, the more\n")
cat("underlying intention has to change before the answer moves by one point.\n")

# --- 2. Binary-outcome check, retained separately ----------------------------
# This is NOT a test of equal spacing: dichotomising y already discards it.
# The ordinal estimates here condition on fitted respondent modes for continuity
# with the earlier report. The threshold comparison below integrates them out.
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
                  binary_linear_pp = 100 * lin_eff,
                  ordinal_conditional_pp = 100 * ord_eff,
                  difference_pp = 100 * (ord_eff - lin_eff))
print(eff, digits = 3, row.names = FALSE)
write.csv(eff, file.path(DIR_TAB, "12_scale_effects.csv"), row.names = FALSE)
cat("\nBinary linear vs conditional ordinal estimates, in percentage points.\n")
cat("This comparison does not test equal spacing of the original 1-7 scale.\n")

# --- 2b. Direct test of equidistant thresholds -------------------------------
m_equal <- update(m_ord, threshold = "equidistant")
thresholds <- function(m) {
  z <- as.numeric(m$Theta)
  stopifnot(length(z) == 6L, all(is.finite(z)), all(diff(z) > 0))
  z
}
fits <- list(flexible = m_ord, equidistant = m_equal)
diag <- do.call(rbind, lapply(names(fits), function(nm) {
  m <- fits[[nm]]
  grad <- max(abs(m$gradient))
  eig <- eigen(m$Hessian, symmetric = TRUE, only.values = TRUE)$values
  code <- m$optRes$convergence
  stopifnot(length(code) == 1L, code == 0L, is.finite(grad), grad < 1e-3,
            all(is.finite(eig)), min(eig) > 0)
  data.frame(model = nm, n = nobs(m), parameters = attr(logLik(m), "df"),
             logLik = as.numeric(logLik(m)), AIC = AIC(m),
             convergence = code, max_gradient = grad, min_hessian_eigenvalue = min(eig))
}))
stopifnot(nobs(m_ord) == nobs(m_equal), nobs(m_ord) == nrow(long),
          identical(rownames(model.frame(m_ord)), rownames(model.frame(m_equal))),
          max(abs(diff(thresholds(m_equal)) - mean(diff(thresholds(m_equal))))) < 1e-8)
lrt <- 2 * (as.numeric(logLik(m_ord)) - as.numeric(logLik(m_equal)))
df_lrt <- attr(logLik(m_ord), "df") - attr(logLik(m_equal), "df")
stopifnot(lrt >= 0, df_lrt == 4)
test <- data.frame(chisq = lrt, df = df_lrt, p_value = pchisq(lrt, df_lrt, lower.tail = FALSE),
                   AIC_flexible = AIC(m_ord), AIC_equidistant = AIC(m_equal),
                   nAGQ = 7)
cat("\n=== FLEXIBLE VS EQUIDISTANT LATENT THRESHOLDS ===\n")
print(diag, digits = 6, row.names = FALSE)
print(test, digits = 6, row.names = FALSE)
write.csv(diag, file.path(DIR_TAB, "12_threshold_diagnostics.csv"), row.names = FALSE)
write.csv(test, file.path(DIR_TAB, "12_threshold_comparison.csv"), row.names = FALSE)
write.csv(data.frame(boundary = names(th), flexible = thresholds(m_ord),
                     equidistant = thresholds(m_equal)),
          file.path(DIR_TAB, "12_thresholds_compared.csv"), row.names = FALSE)

# Standardise over the same observed rows for each cue. Integrate a N(0, sd^2)
# intercept rather than inserting outcome-informed respondent predictions.
marginal_top <- function(m, dat, level, tol = 1e-8) {
  dat$x <- level
  X <- model.matrix(~ focal * x + position + inv_app + inv_dl + inv_cat, dat)
  eta <- drop(X[, names(m$beta), drop = FALSE] %*% m$beta)
  cut <- thresholds(m)[4]
  sd_u <- as.numeric(m$ST[[1]][1, 1])
  integrate(function(z) vapply(z, function(u)
    mean(plogis(eta + sd_u * u - cut)) * dnorm(u), numeric(1)),
    lower = -Inf, upper = Inf, rel.tol = tol, abs.tol = tol)$value
}
practical <- do.call(rbind, lapply(levels(long$focal), function(f) {
  dat <- long[long$focal == f, ]
  probs <- lapply(fits, function(m) vapply(0:1, function(x) marginal_top(m, dat, x), numeric(1)))
  stopifnot(all(unlist(probs) >= 0), all(unlist(probs) <= 1))
  data.frame(focal = f, flexible_low = probs$flexible[1], flexible_high = probs$flexible[2],
             equidistant_low = probs$equidistant[1], equidistant_high = probs$equidistant[2],
             flexible_pp = 100 * diff(probs$flexible),
             equidistant_pp = 100 * diff(probs$equidistant),
             difference_pp = 100 * (diff(probs$flexible) - diff(probs$equidistant)))
}))
cat("\nMarginal P(y >= 5) effects: same covariates, random intercept integrated out.\n")
print(practical, digits = 5, row.names = FALSE)
cat("Differences are descriptive, not confidence intervals or evidence of equivalence.\n")
cat("This comparison does not validate all OLS findings or prove a ranking between cues.\n")
write.csv(practical, file.path(DIR_TAB, "12_threshold_effects.csv"), row.names = FALSE)

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
