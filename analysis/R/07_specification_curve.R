# 07_specification_curve.R ---------------------------------------------------
# Step 2A, claims 1 and 3: how much do the two headline comparisons depend on
# analytic choices?
#
# The grid was fixed in the work plan ("Next step - Step 2A") before running:
#
#   main curve, 24 specifications
#     sample "all"  (1473 obs, clustered) x models CR2-OLS / linear mixed /
#                    ordinal mixed x involvement on-off x position on-off   = 12
#     samples "position 1|2|3 only" (491 obs, independent, one row per
#                    subject) x models OLS / ordinal x involvement on-off    = 12
#   separate panel, 24 specifications
#     samples "box ticked" and "subjects ticking 3 of 3" x the same 12 cells
#     as the clustered case. These filter on a post-treatment self-report and
#     are therefore NOT part of the main curve (review section 3.3).
#
# Naive OLS on the full sample is excluded (its SEs ignore an ICC of 0.41); a
# mixed model on a single-position sample is degenerate (one row per subject).
#
# Estimand 1 (claim 1): brand effect minus reputation effect = -b[focalrep:x].
# Estimand 2 (claim 3): reduction of that gap once other apps have been seen
#                       = b[focalrep:x:comp]; estimable only on the full sample.
#
# Output: analysis/outputs/tables/07_specification_curve.csv
#         analysis/outputs/figures/fig_04_specification_curve.png
#         analysis/outputs/logs/07_specification_curve.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4); library(ordinal); library(clubSandwich); library(ggplot2)
})
has_lmerTest <- requireNamespace("lmerTest", quietly = TRUE)

con <- file(file.path(DIR_LOG, "07_specification_curve.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal  <- factor(long$focal, levels = c("brand", "rep", "pop"))
long$subj_f <- factor(long$subject)
long$y_ord  <- factor(long$y, levels = 1:7, ordered = TRUE)
long$comp   <- as.integer(long$pos_num > 1)
ticked3     <- names(which(tapply(long$manip_ok, long$subject, sum) == 3))

samples <- list(
  all   = list(data = long, clustered = TRUE),
  pos1  = list(data = long[long$pos_num == 1, ], clustered = FALSE),
  pos2  = list(data = long[long$pos_num == 2, ], clustered = FALSE),
  pos3  = list(data = long[long$pos_num == 3, ], clustered = FALSE),
  ticked = list(data = long[long$manip_ok == 1, ], clustered = TRUE, panel = TRUE),
  all3   = list(data = long[long$subject %in% as.integer(ticked3), ], clustered = TRUE, panel = TRUE))

rhs <- function(inv, pos, three_way = FALSE) {
  core <- if (three_way) "focal * x * comp" else "focal * x"
  paste0(core,
         if (inv) " + inv_app + inv_dl + inv_cat" else "",
         if (pos) " + factor(pos_num)" else "")
}

# Pull one coefficient (estimate, se, df, p) plus a convergence flag out of any
# of the model types. An ordinal fit can land on a near-singular Hessian: the
# estimate stays sensible while the standard error collapses by two orders of
# magnitude. Such a fit is flagged and dropped rather than reported.
grab <- function(model, type, term, d) {
  if (type == "cr2") {
    ct <- coef_test(model, vcov = "CR2", cluster = d$subject, test = "Satterthwaite")
    r  <- ct[rownames(ct) == term | ct$Coef == term, ][1, ]
    list(est = r$beta, se = r$SE, df = r$df_Satt, p = r$p_Satt, ok = TRUE, diag = NA_real_)
  } else if (type == "lmm") {
    cf <- summary(model)$coefficients
    est <- cf[term, 1]; se <- cf[term, 2]
    ok <- !lme4::isSingular(model)
    if (has_lmerTest && ncol(cf) >= 5)
      list(est = est, se = se, df = cf[term, 3], p = cf[term, 5], ok = ok, diag = NA_real_)
    else
      list(est = est, se = se, df = Inf,
           p = 2 * pnorm(abs(est / se), lower.tail = FALSE), ok = ok, diag = NA_real_)
  } else if (type == "ols") {
    cf <- coef(summary(model))
    list(est = cf[term, 1], se = cf[term, 2], df = df.residual(model), p = cf[term, 4],
         ok = TRUE, diag = NA_real_)
  } else {
    cf <- coef(summary(model))
    # `clmm` reports max.grad but not cond.H, and stores it as text, so coerce
    # anything that is not a single number to NA before testing it. The gradient
    # at the stopping point is what separates the two cases: healthy fits here
    # sit around 1e-3, the degenerate one at 7.2, so 1e-2 splits them with a
    # wide margin on both sides. The condition number of the Hessian does not
    # separate them (592 vs 5376) and is deliberately not used.
    num1  <- function(x) { x <- suppressWarnings(as.numeric(x))
                           if (length(x) == 1L) x else NA_real_ }
    grad  <- num1(model$info$max.grad)
    condH <- num1(model$info$cond.H)      # present for clm, absent for clmm
    ok <- isTRUE(cf[term, 2] > 1e-4) &&
          !isTRUE(grad > 1e-2) && !isTRUE(condH >= 1e10)
    list(est = cf[term, 1], se = cf[term, 2], df = Inf, p = cf[term, 4],
         ok = ok, diag = grad)
  }
}

fit_spec <- function(sm, type, inv, pos, three_way = FALSE) {
  d <- sm$data
  f <- rhs(inv, pos, three_way)
  term <- if (three_way) "focalrep:x:comp" else "focalrep:x"
  # One unstable fit must never take the other 59 specifications down with it.
  v <- tryCatch({
    m <- switch(type,
      cr2  = lm(as.formula(paste("y ~", f)), data = d),
      ols  = lm(as.formula(paste("y ~", f)), data = d),
      lmm  = if (has_lmerTest) lmerTest::lmer(as.formula(paste("y ~", f, "+ (1|subj_f)")), data = d, REML = TRUE)
             else lme4::lmer(as.formula(paste("y ~", f, "+ (1|subj_f)")), data = d, REML = TRUE),
      clmm = clmm(as.formula(paste("y_ord ~", f, "+ (1|subj_f)")), data = d, link = "logit"),
      clm  = clm(as.formula(paste("y_ord ~", f)), data = d, link = "logit"))
    suppressWarnings(grab(m, if (type == "cr2") "cr2" else if (type == "lmm") "lmm" else
                             if (type == "ols") "ols" else "ord", term, d))
  }, error = function(e) list(est = NA_real_, se = NA_real_, df = NA_real_,
                              p = NA_real_, ok = FALSE, diag = NA_real_))
  # the coefficient is rep minus brand; report brand minus rep, and for the
  # three-way term report the reduction of the gap, which keeps its sign
  sign <- if (three_way) 1 else -1
  data.frame(sample = NA, model = type, involvement = inv, position = pos,
             estimate = sign * v$est, se = v$se, df = v$df, p_value = v$p,
             converged = v$ok, max_grad = v$diag,
             scale = if (type %in% c("clmm", "clm")) "log-odds" else "Likert points",
             n = nrow(d), row.names = NULL)
}

cat("=== SPECIFICATION CURVE ===\n")
cat("lmerTest available:", has_lmerTest, "| R:", R.version.string, "\n\n")

rows <- list(); i <- 0
for (nm in names(samples)) {
  sm <- samples[[nm]]
  panel <- isTRUE(sm$panel)
  types <- if (sm$clustered) c("cr2", "lmm", "clmm") else c("ols", "clm")
  poss  <- if (sm$clustered) c(FALSE, TRUE) else FALSE
  for (type in types) for (inv in c(FALSE, TRUE)) for (pos in poss) {
    i <- i + 1
    r <- fit_spec(sm, type, inv, pos)
    r$sample <- nm; r$curve <- if (panel) "slide-6 panel" else "main"; r$estimand <- "brand - reputation"
    rows[[length(rows) + 1]] <- r
    cat(sprintf("  [%2d] %-6s %-4s inv=%-5s pos=%-5s  est=%+.3f (se %.3f) p=%.4f%s\n",
                i, nm, type, inv, pos, r$estimate, r$se, r$p_value,
                ifelse(r$converged, "", "   <- did not converge, dropped")))
  }
}
# claim 3: only on the full sample
for (type in c("cr2", "lmm", "clmm")) for (inv in c(FALSE, TRUE)) for (pos in c(FALSE, TRUE)) {
  i <- i + 1
  r <- fit_spec(samples$all, type, inv, pos, three_way = TRUE)
  r$sample <- "all"; r$curve <- "main"; r$estimand <- "gap reduction under comparison"
  rows[[length(rows) + 1]] <- r
  cat(sprintf("  [%2d] claim3 %-4s inv=%-5s pos=%-5s  est=%+.3f (se %.3f) p=%.4f%s\n",
              i, type, inv, pos, r$estimate, r$se, r$p_value,
              ifelse(r$converged, "", "   <- did not converge, dropped")))
}

sc <- do.call(rbind, rows)
sc$significant  <- !is.na(sc$p_value) & sc$p_value < 0.05
sc$favours      <- !is.na(sc$estimate) & sc$estimate > 0
write.csv(sc, file.path(DIR_TAB, "07_specification_curve.csv"), row.names = FALSE)

cat("\n=== CONVERGENCE ===\n")
cat(sprintf("  specifications fitted: %d | dropped for non-convergence: %d\n",
            nrow(sc), sum(!sc$converged)))
if (any(!sc$converged)) print(sc[!sc$converged, c("curve", "estimand", "sample", "model",
                                                  "involvement", "position", "estimate", "se", "max_grad")],
                             row.names = FALSE)
cat("  A dropped fit keeps a sensible estimate but its standard error collapses, so it\n")
cat("  would otherwise count as a spurious 'significant' specification.\n")
ok <- sc[sc$converged, ]

cat("\n=== CLAIM 1: brand above reputation, main curve ===\n")
c1 <- ok[ok$estimand == "brand - reputation" & ok$curve == "main", ]
share <- mean(c1$significant & c1$favours)
cat(sprintf("  specifications kept: %d of 24 | brand above reputation at p<0.05: %d (%.1f%%)\n",
            nrow(c1), sum(c1$significant & c1$favours), 100 * share))
cat(sprintf("  reputation above brand at p<0.05: %d\n", sum(c1$significant & !c1$favours)))
cat("  median estimate by sample:\n")
print(round(tapply(c1$estimate, c1$sample, median), 3))
verdict1 <- if (share < 0.25) "KEEP: brand and reputation are indistinguishable" else
            if (share <= 0.75) "SOFTEN: brand may lead, but it depends on analytic choices" else
            "REVISE: claim 1 is wrong; section 3.2 of the review must be rewritten"
cat("  pre-registered verdict ->", verdict1, "\n")

cat("\n=== CLAIM 3: does the gap shrink once other apps have been seen? ===\n")
c3 <- ok[ok$estimand == "gap reduction under comparison", ]
cat(sprintf("  specifications kept: %d of 12 | significant reduction: %d | positive sign: %d\n",
            nrow(c3), sum(c3$significant & c3$favours), sum(c3$favours)))
cat("  pre-registered rule: wording can strengthen only if at least 9 of 12 are significant ->",
    ifelse(sum(c3$significant & c3$favours) >= 9, "STRENGTHEN", "KEEP AS HYPOTHESIS"), "\n")

cat("\n=== slide-6 panel (not part of the main curve) ===\n")
cp <- ok[ok$curve == "slide-6 panel", ]
cat(sprintf("  specifications kept: %d | brand above reputation at p<0.05: %d (%.1f%%)\n",
            nrow(cp), sum(cp$significant & cp$favours), 100 * mean(cp$significant & cp$favours)))

# --- figure -----------------------------------------------------------------
pl <- ok[ok$estimand == "brand - reputation", ]
pl$crit <- ifelse(pl$df > 1000 | !is.finite(pl$df), qnorm(0.975), qt(0.975, pmax(pl$df, 1)))
pl$lo <- pl$estimate - pl$crit * pl$se; pl$hi <- pl$estimate + pl$crit * pl$se
pl <- do.call(rbind, lapply(split(pl, list(pl$curve, pl$scale), drop = TRUE), function(g) {
  g <- g[order(g$estimate), ]; g$rank <- seq_len(nrow(g)); g
}))
p <- ggplot(pl, aes(rank, estimate, colour = sample, shape = model)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, linewidth = 0.5, alpha = 0.7) +
  geom_point(size = 2.2) +
  facet_grid(scale ~ curve, scales = "free", switch = "y") +
  labs(title = "Does brand really beat reputation? Every defensible specification",
       subtitle = sprintf("Brand minus reputation effect. Brand ahead at p<0.05 in %.0f%% of the %d main specifications",
                          100 * share, nrow(c1)),
       x = "specifications, ordered by estimate", y = NULL, colour = NULL, shape = NULL,
       caption = paste("Positive = brand ahead. The slide-6 panel filters on a post-treatment self-report and is shown apart.",
                       "Ordinal specifications are on a log-odds scale and have their own row.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), legend.position = "top",
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey30", size = 9),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0))
ggsave(file.path(DIR_FIG, "fig_04_specification_curve.png"), p, width = 8, height = 5.6, dpi = 200)

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/07_specification_curve.log\n")
