# 14_posterior_probabilities.R -----------------------------------------------
# Work plan task 2.6 — answering the question a reader actually asks.
#
# QUESTION. "Is brand more effective than reputation?" A p-value cannot answer
# it. p = 0.22 does not mean a 22% chance the two are equal; it means that if
# they were exactly equal, data this extreme would appear 22% of the time. The
# question people want answered is the other way round: given these data, how
# likely is it that brand really is ahead?
#
# METHOD, IN PLAIN TERMS. That question needs a probability distribution over
# the effects themselves - a posterior. In large samples, and with no strong
# prior opinion, the posterior of a set of regression coefficients is very well
# approximated by a bell-shaped (multivariate normal) distribution centred on
# the estimates, with the spread and the correlations given by the model's own
# covariance matrix. We draw 200,000 values from that distribution and simply
# count how often each statement of interest is true.
#
# HONEST LABEL. This is the normal approximation to the posterior, not a full
# Bayesian model. It keeps the correlation between coefficients, which is what
# matters for comparing two effects, but it treats the variance components as
# fixed at their estimates and assumes flat priors. `brms` and `rstan` are
# installed on this machine, but Stan needs a C++ toolchain (RTools) that is
# not, so no model can be compiled here. The work plan (task 2.6) authorised
# this fallback in advance on condition that it be declared - this is the
# declaration.
#
# Output: analysis/outputs/tables/14_posterior_probabilities.csv
#         analysis/outputs/logs/14_posterior_probabilities.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(lme4); library(MASS) })

con <- file(file.path(DIR_LOG, "14_posterior_probabilities.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

set.seed(20260912)
NDRAW <- 200000
BAND  <- c(0.26, 0.33)      # the relevance band fixed in Step 2A, Likert points

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$comp_f   <- factor(long$comp, levels = c(0, 1), labels = c("shown_first", "after_others"))

cat("=== POSTERIOR PROBABILITIES (normal approximation) ===\n")
cat("draws:", NDRAW, "| relevance band:", BAND[1], "-", BAND[2], "Likert points\n\n")

draw <- function(m) {
  mu <- fixef(m)
  MASS::mvrnorm(NDRAW, mu = mu, Sigma = as.matrix(vcov(m)))
}
pr <- function(x) mean(x)

# --- model 1: the three cue effects -----------------------------------------
m_pool <- lmer(y ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
S <- draw(m_pool)
brand <- S[, "x"]
rep_  <- S[, "x"] + S[, "focalrep:x"]
pop   <- S[, "x"] + S[, "focalpop:x"]

cat("--- point estimates the draws are centred on ---\n")
cat(sprintf("  brand %+.3f | reputation %+.3f | popularity %+.3f\n\n",
            mean(brand), mean(rep_), mean(pop)))

rows <- list()
add <- function(question, p) rows[[length(rows) + 1]] <<-
  data.frame(question = question, probability = p)

add("brand effect is positive", pr(brand > 0))
add("reputation effect is positive", pr(rep_ > 0))
add("popularity effect is positive", pr(pop > 0))
add("brand is ahead of reputation", pr(brand > rep_))
add("brand is ahead of popularity", pr(brand > pop))
add("reputation is ahead of popularity", pr(rep_ > pop))
add("the full ranking brand > reputation > popularity holds", pr(brand > rep_ & rep_ > pop))
add("brand and reputation are within 0.26 points of each other", pr(abs(brand - rep_) < BAND[1]))
add("brand and reputation are within 0.33 points of each other", pr(abs(brand - rep_) < BAND[2]))
add("the popularity effect is smaller than 0.26 points", pr(abs(pop) < BAND[1]))
add("the popularity effect is smaller than 0.33 points", pr(abs(pop) < BAND[2]))

# --- model 2: before and after comparison ------------------------------------
m_comp <- lmer(y ~ focal * x * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
C <- draw(m_comp)
g <- function(nm) if (nm %in% colnames(C)) C[, nm] else 0
brand_first <- g("x")
rep_first   <- g("x") + g("focalrep:x")
pop_first   <- g("x") + g("focalpop:x")
brand_after <- brand_first + g("x:comp_fafter_others")
rep_after   <- rep_first   + g("x:comp_fafter_others") + g("focalrep:x:comp_fafter_others")
pop_after   <- pop_first   + g("x:comp_fafter_others") + g("focalpop:x:comp_fafter_others")

add("brand is ahead of reputation BEFORE any comparison", pr(brand_first > rep_first))
add("brand is ahead of reputation AFTER other apps were seen", pr(brand_after > rep_after))
add("the brand-reputation gap shrinks once other apps are seen",
    pr((brand_first - rep_first) > (brand_after - rep_after)))
add("the popularity effect is positive BEFORE any comparison", pr(pop_first > 0))
add("the popularity effect is smaller than 0.26 points AFTER comparison", pr(abs(pop_after) < BAND[1]))

out <- do.call(rbind, rows)
out$probability_pct <- sprintf("%.1f%%", 100 * out$probability)
cat("--- probabilities ---\n")
print(out[, c("question", "probability_pct")], right = FALSE, row.names = FALSE)
write.csv(out, file.path(DIR_TAB, "14_posterior_probabilities.csv"), row.names = FALSE)

cat("\n=== HOW TO READ THIS ===\n")
cat("These are statements about the effects given the data, not about hypothetical\n")
cat("repetitions of the experiment. A probability near 50% means the data are\n")
cat("silent on the question; one near 100% means they settle it. They are read\n")
cat("alongside the frequentist results, not instead of them: both come from the\n")
cat("same model and the same data, so they cannot disagree about the evidence,\n")
cat("only about how it is phrased.\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/14_posterior_probabilities.log\n")
