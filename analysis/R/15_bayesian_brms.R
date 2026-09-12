# 15_bayesian_brms.R ---------------------------------------------------------
# Work plan task 2.6, done properly — a full Bayesian model rather than the
# normal approximation of `14_posterior_probabilities.R`.
#
# WHY THIS EXISTS. Script 14 approximated the posterior with a bell-shaped cloud
# around the maximum-likelihood estimates, because no Stan model could be
# compiled on the machine this was written on. This script fits the real thing
# whenever the environment allows it, and checks first rather than assuming.
# Script 14 is kept either way: the two sets of numbers are compared below, and
# agreement is itself informative — it tells us the approximation was safe.
#
# WHAT A BAYESIAN MODEL DOES DIFFERENTLY. Instead of one best estimate per
# coefficient plus a standard error, it produces a whole distribution of
# plausible values for each one, given the data and a mild prior expectation
# about their size. Statements such as "brand beats reputation" are then simply
# counted across those draws.
#
# PRIORS. Deliberately weak: a normal(0, 2) on every effect, on a 1-7 answer
# scale where the largest observed effect is about 1.5. This says only that
# effects of five or six scale points are implausible, and leaves everything the
# data might plausibly show untouched.
#
# Output: analysis/outputs/tables/15_bayesian_probabilities.csv
#         analysis/outputs/tables/15_bayesian_vs_approximation.csv
#         analysis/outputs/figures/fig_13_posterior.png
#         analysis/outputs/logs/15_bayesian_brms.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({ library(brms); library(ggplot2) })

BAND <- c(0.26, 0.33)
SEED <- 20260912

# NOTE ON LOGGING. rstan calls sink() itself while it compiles the model, so an
# open sink here breaks the compilation with "invalid connection". The models are
# therefore fitted BEFORE the log is opened, and the log is opened only once the
# fitting is done.

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$comp_f   <- factor(long$comp, levels = c(0, 1), labels = c("shown_first", "after_others"))

message("Fitting two Bayesian models with Stan. This compiles C++ first and takes a few minutes.")

# Pick a backend that can actually compile, by trying a trivial model rather than
# assuming. cmdstanr carries its own CmdStan and bypasses rstan entirely; rstan
# is the fallback. On the machine this was written on rstan fails for reasons
# that are NOT a missing toolchain: see section 2.6 of docs/02-work-plan.md.
TINY <- "parameters { real y; } model { y ~ std_normal(); }"
BACKEND <- NULL

if (requireNamespace("cmdstanr", quietly = TRUE) &&
    !is.null(cmdstanr::cmdstan_version(error_on_NA = FALSE))) {
  probe <- try(cmdstanr::cmdstan_model(cmdstanr::write_stan_file(TINY)), silent = TRUE)
  if (!inherits(probe, "try-error")) BACKEND <- "cmdstanr"
}
if (is.null(BACKEND) && requireNamespace("rstan", quietly = TRUE)) {
  probe <- try(rstan::stan_model(model_code = TINY, verbose = FALSE), silent = TRUE)
  if (!inherits(probe, "try-error")) BACKEND <- "rstan"
}
if (is.null(BACKEND)) {
  message("No Stan backend on this machine can compile a model, so this script stops here.")
  message("The Bayesian results in the documents come from the normal approximation in")
  message("analysis/R/14_posterior_probabilities.R, which is the authorised fallback.")
  quit(save = "no", status = 0)
}
message("Stan backend in use: ", BACKEND)

pri <- c(prior(normal(0, 2), class = "b"),
         prior(normal(4, 2), class = "Intercept"),
         prior(student_t(3, 0, 2), class = "sd"),
         prior(student_t(3, 0, 2), class = "sigma"))

fit1 <- brm(y ~ focal * x + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
            data = long, prior = pri, seed = SEED, chains = 4, iter = 2000,
            refresh = 0, silent = 2, backend = BACKEND)
fit2 <- brm(y ~ focal * x * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
            data = long, prior = pri, seed = SEED, chains = 4, iter = 2000,
            refresh = 0, silent = 2, backend = BACKEND)

# Only now is it safe to open the log: the compilation is over.
con <- file(file.path(DIR_LOG, "15_bayesian_brms.log"), open = "wt")
sink(con, split = TRUE)

cat("=== FULL BAYESIAN ESTIMATION ===\n")
cat("brms", as.character(utils::packageVersion("brms")),
    "| backend", BACKEND,
    if (BACKEND == "cmdstanr") paste("| CmdStan", cmdstanr::cmdstan_version()) else
      paste("| rstan", as.character(utils::packageVersion("rstan"))),
    "| 4 chains x 2000 iterations\n\n")

cat("--- convergence ---\n")
for (nm in c("fit1", "fit2")) {
  f <- get(nm)
  s <- summary(f)$fixed
  cat(sprintf("  %s: max Rhat = %.4f | min bulk ESS = %.0f | divergent transitions = %d\n",
              nm, max(s$Rhat), min(s$Bulk_ESS), sum(subset(nuts_params(f), Parameter == "divergent__")$Value)))
}
cat("  Rhat near 1.00 and a large effective sample size mean the sampler explored\n")
cat("  the posterior properly; divergent transitions should be zero.\n\n")

d1 <- as_draws_df(fit1)
brand <- d1$b_x
rep_  <- d1$b_x + d1$`b_focalrep:x`
pop   <- d1$b_x + d1$`b_focalpop:x`

d2 <- as_draws_df(fit2)
gg <- function(nm) if (nm %in% names(d2)) d2[[nm]] else 0
brand_first <- gg("b_x")
rep_first   <- gg("b_x") + gg("b_focalrep:x")
pop_first   <- gg("b_x") + gg("b_focalpop:x")
shift       <- gg("b_x:comp_fafter_others")
brand_after <- brand_first + shift
rep_after   <- rep_first   + shift + gg("b_focalrep:x:comp_fafter_others")
pop_after   <- pop_first   + shift + gg("b_focalpop:x:comp_fafter_others")

rows <- list()
add <- function(q, p) rows[[length(rows) + 1]] <<- data.frame(question = q, probability = mean(p))
add("brand effect is positive", brand > 0)
add("reputation effect is positive", rep_ > 0)
add("popularity effect is positive", pop > 0)
add("brand is ahead of reputation", brand > rep_)
add("brand is ahead of popularity", brand > pop)
add("reputation is ahead of popularity", rep_ > pop)
add("the full ranking brand > reputation > popularity holds", brand > rep_ & rep_ > pop)
add("brand and reputation are within 0.26 points of each other", abs(brand - rep_) < BAND[1])
add("brand and reputation are within 0.33 points of each other", abs(brand - rep_) < BAND[2])
add("the popularity effect is smaller than 0.26 points", abs(pop) < BAND[1])
add("the popularity effect is smaller than 0.33 points", abs(pop) < BAND[2])
add("brand is ahead of reputation BEFORE any comparison", brand_first > rep_first)
add("brand is ahead of reputation AFTER other apps were seen", brand_after > rep_after)
add("the brand-reputation gap shrinks once other apps are seen",
    (brand_first - rep_first) > (brand_after - rep_after))
add("the popularity effect is positive BEFORE any comparison", pop_first > 0)
add("the popularity effect is smaller than 0.26 points AFTER comparison", abs(pop_after) < BAND[1])

out <- do.call(rbind, rows)
out$probability_pct <- sprintf("%.1f%%", 100 * out$probability)
cat("--- posterior probabilities ---\n")
print(out[, c("question", "probability_pct")], right = FALSE, row.names = FALSE)
write.csv(out, file.path(DIR_TAB, "15_bayesian_probabilities.csv"), row.names = FALSE)

cat("\n--- posterior summaries of the three effects (Likert points) ---\n")
summ <- data.frame(
  cue = c("brand", "reputation", "popularity"),
  median = c(median(brand), median(rep_), median(pop)),
  lower95 = c(quantile(brand, .025), quantile(rep_, .025), quantile(pop, .025)),
  upper95 = c(quantile(brand, .975), quantile(rep_, .975), quantile(pop, .975)))
print(summ, digits = 3, row.names = FALSE)

# --- does the full model agree with the approximation of script 14? ----------
appx_file <- file.path(DIR_TAB, "14_posterior_probabilities.csv")
if (file.exists(appx_file)) {
  ap <- read.csv(appx_file)
  cmp <- merge(ap[, c("question", "probability")], out[, c("question", "probability")],
               by = "question", suffixes = c("_approximation", "_full"))
  cmp$difference_pp <- 100 * (cmp$probability_full - cmp$probability_approximation)
  cmp <- cmp[order(-abs(cmp$difference_pp)), ]
  cat("\n--- full Bayesian model vs the normal approximation ---\n")
  print(cmp, digits = 3, row.names = FALSE)
  cat(sprintf("\nlargest disagreement: %.1f percentage points\n", max(abs(cmp$difference_pp))))
  write.csv(cmp, file.path(DIR_TAB, "15_bayesian_vs_approximation.csv"), row.names = FALSE)
}

# --- figure: the posteriors themselves --------------------------------------
pal <- c(brand = "#1f4e79", reputation = "#c0504d", popularity = "#7f7f7f")
dens <- rbind(data.frame(cue = "brand", value = brand),
              data.frame(cue = "reputation", value = rep_),
              data.frame(cue = "popularity", value = pop))
dens$cue <- factor(dens$cue, levels = c("brand", "reputation", "popularity"))
p <- ggplot(dens, aes(value, fill = cue, colour = cue)) +
  geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_density(alpha = 0.35, linewidth = 0.6) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_colour_manual(values = pal, name = NULL) +
  labs(title = "How large is each cue's effect? The full posterior",
       subtitle = sprintf("Bayesian mixed model, weak priors. Brand is ahead of reputation with probability %.0f%%",
                          100 * mean(brand > rep_)),
       x = "Effect on intention to download (1-7 scale)", y = NULL,
       caption = paste("Each curve shows every value of the effect that is plausible given the data, not a single estimate.",
                       "Overlap between two curves is what 'not distinguishable' looks like.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "top",
        axis.text.y = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey30", size = 9),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
ggsave(file.path(DIR_FIG, "fig_13_posterior.png"), p, width = 7.4, height = 4.6, dpi = 200)

sink(); close(con)
cat("Done. Log in analysis/outputs/logs/15_bayesian_brms.log\n")
