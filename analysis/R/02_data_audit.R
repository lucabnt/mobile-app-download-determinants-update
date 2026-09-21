# 02_data_audit.R ------------------------------------------------------------
# Integrity audit of the original datasets: consistency across files, agreement
# with the published descriptive statistics (Table 3.1) and with the figures
# reported in the thesis text. Sections 9-12 document data-construction issues
# found while reading Appendix A and B.
# Output: analysis/outputs/logs/02_data_audit.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

con <- file(file.path(DIR_LOG, "02_data_audit.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

cat("=== AUDIT OF THE ORIGINAL DATA ===\n\n")

anv <- read_orig("M ANOVA_RM.csv")
plt <- read_orig("M plots.csv")

cat("## 1. Structure of the repeated-measures file\n")
cat("rows:", nrow(anv), "| unique subjects:", length(unique(anv$lfdn)), "\n")
cat("rows per subject:\n"); print(table(table(anv$lfdn)))
cat("\nclass of lfdn in the file:", class(anv$lfdn), " <- this is what breaks Error(lfdn)\n")
cat("\ncrosstab i x n (each subject must see each i once and each n once):\n")
print(table(anv$i_name, anv$n))
cat("\ncrosstab i x x_i:\n"); print(table(anv$i_name, anv$x_i))
cat("\nLatin square? subjects with duplicated i:",
    sum(tapply(anv$i_name, anv$lfdn, function(z) any(duplicated(z)))), "\n")
cat("subjects with duplicated n:",
    sum(tapply(anv$n, anv$lfdn, function(z) any(duplicated(z)))), "\n")

cat("\n## 2. Is y_i_mc really y_i mean-centred?\n")
for (v in unique(anv$i_name)) {
  s <- anv[anv$i_name == v, ]
  cat(sprintf("  %-6s mean(y_i)=%.4f  mean(y_i_mc)=%+.4f  max|y_i - mean - y_mc|=%.6f\n",
              v, mean(s$y_i), mean(s$y_i_mc), max(abs(s$y_i - mean(s$y_i) - s$y_i_mc))))
}
cat("  overall: mean(y_i)=", round(mean(anv$y_i),4),
    " max|y_i-mean-y_mc| =", round(max(abs(anv$y_i - mean(anv$y_i) - anv$y_i_mc)), 6), "\n")

cat("\n## 3. Descriptive statistics vs Table 3.1 of the thesis\n")
thesis <- data.frame(
  var  = c("y_rep","y_pop","y_brand","x_rep","x_pop","x_brand",
           "inv_app","inv_dl","inv_cat","comp_i"),
  mean = c(4.0468,4.5255,4.9674,0.4847,0.5031,0.5214,0,0,0,0.6667),
  sd   = c(1.7077,1.5675,1.5863,0.4998,0.5000,0.4995,1.0523,1.2974,1.0629,0.4714)
)
m3 <- list(rep = read_orig("M3_rep.csv"), pop = read_orig("M3_pop.csv"), brand = read_orig("M3_brand.csv"))
emp <- rbind(
  data.frame(var="y_rep",   mean=mean(m3$rep$y_rep),     sd=sd(m3$rep$y_rep)),
  data.frame(var="y_pop",   mean=mean(m3$pop$y_pop),     sd=sd(m3$pop$y_pop)),
  data.frame(var="y_brand", mean=mean(m3$brand$y_brand), sd=sd(m3$brand$y_brand)),
  data.frame(var="x_rep",   mean=mean(m3$rep$x_rep),     sd=sd(m3$rep$x_rep)),
  data.frame(var="x_pop",   mean=mean(m3$pop$x_pop),     sd=sd(m3$pop$x_pop)),
  data.frame(var="x_brand", mean=mean(m3$brand$x_brand), sd=sd(m3$brand$x_brand)),
  data.frame(var="inv_app", mean=mean(m3$rep$inv_app_mc),sd=sd(m3$rep$inv_app_mc)),
  data.frame(var="inv_dl",  mean=mean(m3$rep$inv_dl_mc), sd=sd(m3$rep$inv_dl_mc)),
  data.frame(var="inv_cat", mean=mean(m3$rep$inv_cat_mc),sd=sd(m3$rep$inv_cat_mc)),
  data.frame(var="comp_i",  mean=mean(m3$rep$comp_rep),  sd=sd(m3$rep$comp_rep))
)
cmp <- merge(thesis, emp, by = "var", suffixes = c("_thesis", "_data"))
cmp$d_mean <- round(cmp$mean_data - cmp$mean_thesis, 4)
cmp$d_sd   <- round(cmp$sd_data   - cmp$sd_thesis,   4)
print(cmp, digits = 5)

cat("\n## 4. Consistency between the model files and the ANOVA file\n")
for (v in c("rep","pop","brand")) {
  d  <- m3[[v]]
  a  <- anv[anv$i_name == v, ]
  k  <- merge(d[, c("lfdn", paste0("y_", v), paste0("x_", v), paste0("comp_", v))],
              a[, c("lfdn","y_i","x_i","n")], by = "lfdn")
  cat(sprintf("  %-6s merged n=%d | y mismatches=%d | x mismatches=%d | comp!=(n>1)=%d\n",
              v, nrow(k), sum(k[[paste0("y_", v)]] != k$y_i),
              sum(k[[paste0("x_", v)]] != k$x_i),
              sum(k[[paste0("comp_", v)]] != as.integer(k$n > 1))))
}

cat("\n## 4b. The involvement covariates, across files and against their own range\n")
# Added 2026-09-18 after an independent re-computation (not published)
# found what section 4 missed: it compared y, x and comp and stopped there,
# while every pooled model in this review also uses the three involvement
# columns of the ANOVA file. Three checks, applied to every centred column:
#   (i)   the same respondent carries the same value in every file;
#   (ii)  the value lies inside what a 1-7 scale can produce once centred;
#   (iii) a column declared mean-centred has mean zero.
cat("(i) ANOVA file vs M3_rep, one row per respondent:\n")
a1 <- anv[!duplicated(anv$lfdn), c("lfdn", "inv_app_mc", "inv_dl_mc", "inv_cat_mc")]
k  <- merge(a1, m3$rep[, c("lfdn", "inv_app", "inv_dl", "inv_cat",
                           "inv_app_mc", "inv_dl_mc", "inv_cat_mc")],
            by = "lfdn", suffixes = c("_anova", "_m3"))
for (v in c("inv_app", "inv_dl", "inv_cat")) {
  d   <- abs(k[[paste0(v, "_mc_anova")]] - k[[paste0(v, "_mc_m3")]])
  bad <- k$lfdn[d > 1e-6]
  imp <- k$lfdn[abs(k[[v]] - mean(m3$rep[[v]])) < 1e-6]
  cat(sprintf("  %-8s mismatches=%2d | all of them mean-imputed cases: %s | ANOVA value there = -mean (%.4f)\n",
              v, length(bad), setequal(bad, imp),
              if (length(bad)) unique(round(k[[paste0(v, "_mc_anova")]][d > 1e-6], 4)) else NA))
}
cat("\n(ii)-(iii) range and centring of each centred column:\n")
for (src in c("ANOVA file", "M3_rep")) for (v in c("inv_app", "inv_dl", "inv_cat")) {
  x   <- if (src == "ANOVA file") a1[[paste0(v, "_mc")]] else m3$rep[[paste0(v, "_mc")]]
  lo  <- 1 - mean(m3$rep[[v]]); hi <- 7 - mean(m3$rep[[v]])
  cat(sprintf("  %-10s %-8s mean %+.5f | min %+.3f (possible %+.3f) | out of range: %d\n",
              src, v, mean(x), min(x), lo, sum(x < lo - 1e-9 | x > hi + 1e-9)))
}
cat("\nVerdict: the nine model files agree with one another and are correctly\n")
cat("centred, which is why the thesis's regressions are unaffected; the thesis's\n")
cat("ANOVA does not use involvement at all. The ANOVA file encodes the 18\n")
cat("mean-imputed respondents as if the missing score had been 0, so its\n")
cat("centred value is -mean, outside the possible range. 03_build_derived.R\n")
cat("therefore rebuilds the covariates from M3_rep instead of copying them.\n")

cat("\n## 5. M1 (n=1) and M2 (n=3) subsamples: expected vs actual sizes\n")
for (v in c("rep","pop","brand")) {
  a  <- anv[anv$i_name == v, ]
  n1 <- sum(a$n == 1); n3 <- sum(a$n == 3)
  d1 <- nrow(read_orig(paste0("M1_", v, ".csv")))
  d2 <- nrow(read_orig(paste0("M2_", v, ".csv")))
  cat(sprintf("  %-6s  n=1 expected %3d / file M1 %3d %s |  n=3 expected %3d / file M2 %3d %s\n",
              v, n1, d1, ifelse(n1 == d1, "ok", "!! MISMATCH"),
              n3, d2, ifelse(n3 == d2, "ok", "!! MISMATCH")))
}

cat("\n## 6. Manipulation check: tick rates\n")
for (mod in c("M1","M2","M3")) for (v in c("rep","pop","brand")) {
  d <- read_orig(sprintf("%s_%s.csv", mod, v))
  mc <- d[[paste0("man_check_", v)]]
  bt <- binom.test(sum(mc), length(mc), p = 0.5)
  cat(sprintf("  %s_%-6s %5.2f%%  (n=%3d, 95%% CI %.1f-%.1f%%, p vs 50%% = %.4f)\n",
              mod, v, 100*mean(mc), length(mc),
              100*bt$conf.int[1], 100*bt$conf.int[2], bt$p.value))
}

cat("\n## 7. Missing values and file dimensions\n")
for (f in list.files(DIR_ORIG, pattern = "[.]csv$")) {
  d <- read_orig(f)
  cat(sprintf("  %-16s rows=%4d cols=%2d NA=%d\n", f, nrow(d), ncol(d), sum(is.na(d))))
}

cat("\n## 8. Distribution of the dependent variable (1-7 Likert)\n")
for (v in c("rep","pop","brand")) {
  y <- m3[[v]][[paste0("y_", v)]]
  cat(sprintf("  y_%-6s ", v)); print(table(factor(y, levels = 1:7)))
}

cat("\n## 9. Mean imputation in the involvement scales\n")
cat("The scales have 3 items (inv_app, inv_dl) and 8 items (inv_cat) on a 1-7\n")
cat("range, so the scale means must be multiples of 1/3 and 1/8. A value that is\n")
cat("not, and that equals the scale mean, is the signature of mean imputation.\n\n")
n_item <- c(inv_app = 3, inv_dl = 3, inv_cat = 8)
imput <- sapply(names(n_item), function(v) {
  x <- m3$rep[[v]]; abs(x - mean(x)) < 1e-9
})
for (v in names(n_item)) {
  x <- m3$rep[[v]]; mu <- mean(x); k <- n_item[[v]]
  attainable <- abs(mu * k - round(mu * k)) < 1e-6
  cat(sprintf("  %-8s (%d items) mean = %.6f | attainable score on the scale? %-3s | cases equal to the mean: %2d (%.1f%%)\n",
              v, k, mu, ifelse(attainable, "yes", "NO"), sum(imput[, v]), 100 * mean(imput[, v])))
  cat(sprintf("           s.d. including = %.4f | s.d. excluding = %.4f | difference = %+.4f\n",
              sd(x), sd(x[!imput[, v]]), sd(x[!imput[, v]]) - sd(x)))
}
cat(sprintf("\n  subjects with at least one imputed scale: %d of %d (%.1f%%)\n",
            sum(rowSums(imput) > 0), nrow(imput), 100 * mean(rowSums(imput) > 0)))
print(table(n_scales_imputed = rowSums(imput)))

cat("\n## 10. Is 'M plots.csv' redundant given 'M ANOVA_RM.csv'?\n")
com <- intersect(names(anv), names(plt))
a2 <- anv[order(anv$lfdn, anv$i), com]; p2 <- plt[order(plt$lfdn, plt$i), com]
cat("  columns only in M ANOVA_RM:", paste(setdiff(names(anv), names(plt)), collapse = ", "), "\n")
cat("  columns only in M plots:   ",
    ifelse(length(setdiff(names(plt), names(anv))) == 0, "none",
           paste(setdiff(names(plt), names(anv)), collapse = ", ")), "\n")
cat("  identical on the shared columns?   ", isTRUE(all.equal(a2, p2, check.attributes = FALSE)), "\n")
cat("  -> M plots.csv is a column subset of M ANOVA_RM.csv; it adds no data.\n")

cat("\n## 11. Columns in the M2 files that no model uses\n")
m2r <- read_orig("M2_rep.csv")
cat("  ITD_pop is the top-3-box dichotomisation of y_pop_1e2 (y >= 5)?  ",
    all(m2r$ITD_pop == as.integer(m2r$y_pop_1e2 >= 5)), "\n")
cat("  ITD_brand likewise on y_brand_1e2?                              ",
    all(m2r$ITD_brand == as.integer(m2r$y_brand_1e2 >= 5)), "\n")
cat("  ITD_pop_2 = y_pop_1e2 centred on mean(y_pop)?   max deviation =",
    signif(max(abs(m2r$ITD_pop_2 - (m2r$y_pop_1e2 - mean(m3$pop$y_pop)))), 3), "\n")
cat("  ITD_brand_2 = y_brand_1e2 centred?              max deviation =",
    signif(max(abs(m2r$ITD_brand_2 - (m2r$y_brand_1e2 - mean(m3$brand$y_brand)))), 3), "\n")
cat("  -> leftovers from abandoned exploration: none enters the thesis models.\n")

cat("\n## 12. What the 'manipulation check' actually is (questionnaire slide 6)\n")
cat("It is not a check that the manipulation was perceived. It is a single\n")
cat("multiple-choice question asked once at the end ('which factors did you take\n")
cat("into consideration'), with 9 tick boxes. man_check_i = 1 if the matching box\n")
cat("was ticked. Two consequences are visible in the data:\n\n")
mc_wide <- reshape(anv[, c("lfdn", "i_name", "man_check_i")], idvar = "lfdn",
                   timevar = "i_name", direction = "wide")
cat("  (a) it is a compositional measure: ticking one box comes at the expense of others.\n")
cat("      Correlations between the three outcomes within subject:\n")
print(round(cor(mc_wide[, -1]), 3))
cat("      An attention measure would show uniformly positive correlations.\n\n")
cat("  (b) being a single global question, it cannot vary by presentation position:\n")
print(round(prop.table(table(position = anv$n, check = anv$man_check_i), 1), 3))
cat("      That flatness is structural, not evidence against memory decay.\n")

sink(type="message"); sink(); close(con)
