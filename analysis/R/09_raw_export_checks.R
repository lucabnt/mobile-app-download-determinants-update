# 09_raw_export_checks.R -----------------------------------------------------
# Verifies the chain from the raw survey export (EFS/Unipark) to the thesis
# datasets, reproducing the formulas of the original processing workbook.
#
# The raw export contains personal data and paradata (browser strings, session
# ids, timestamps) and is NOT part of this repository. Point the RAW_EXPORT
# environment variable at a private copy:
#   RAW_EXPORT="/private/path/data_project_945204_2023_01_22_def.csv" \
#     Rscript analysis/R/09_raw_export_checks.R
# Without it the script exits cleanly. All output is aggregate: no row, no
# identifier and no paradata is ever printed or written.
#
# Output: analysis/outputs/logs/09_raw_export_checks.log
#         analysis/outputs/tables/09_scale_reliability.csv
#         analysis/outputs/tables/09_slide6_boxes.csv
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

raw <- Sys.getenv("RAW_EXPORT")
if (raw == "" || !file.exists(raw)) {
  cat("RAW_EXPORT not set or file not found: skipping (the raw export is private).\n")
  quit(save = "no", status = 0)
}

con <- file(file.path(DIR_LOG, "09_raw_export_checks.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

ex  <- read.csv(raw, sep = ";", quote = "\"", fileEncoding = "UTF-8", check.names = FALSE)
anv <- read_orig("M ANOVA_RM.csv")
m3r <- read_orig("M3_rep.csv")
ids <- m3r$lfdn
inc <- ex[match(ids, ex$lfdn), ]
exc <- ex[!ex$lfdn %in% ids, ]

# EFS codes: -77 = page/item never displayed, 0 = displayed but not answered.
cat("=== RAW EXPORT CHECKS ===\n\n")

cat("## 1. Sample\n")
cat("  respondents in the export (all reached the end):", nrow(ex), "\n")
cat("  dispcode:"); print(table(ex$dispcode))
cat("  thesis respondents found in the export:", sum(ids %in% ex$lfdn), "of", length(ids), "\n")
cat("  completed respondents not in the thesis:", nrow(exc), "\n")

cat("\n## 2. ITD, manipulation level and position rebuilt from v_90..v_119\n")
map <- list(
  rep   = list(high = list(`1` = "v_90", `2` = c("v_104", "v_112"), `3` = c("v_110", "v_118")),
               low  = list(`1` = "v_91", `2` = c("v_105", "v_113"), `3` = c("v_111", "v_119"))),
  pop   = list(high = list(`1` = "v_92", `2` = c("v_96", "v_114"),  `3` = c("v_102", "v_116")),
               low  = list(`1` = "v_93", `2` = c("v_97", "v_115"),  `3` = c("v_103", "v_117"))),
  brand = list(high = list(`1` = "v_94", `2` = c("v_98", "v_106"),  `3` = c("v_100", "v_108")),
               low  = list(`1` = "v_95", `2` = c("v_99", "v_107"),  `3` = c("v_101", "v_109"))))
for (k in names(map)) {
  y <- x <- n <- rep(NA_real_, nrow(inc)); hits <- rep(0, nrow(inc))
  for (lev in c("high", "low")) for (pos in c("1", "2", "3")) for (v in map[[k]][[lev]][[pos]]) {
    val <- inc[[v]]; seen <- val != -77
    hits <- hits + seen
    y[seen] <- val[seen]; x[seen] <- as.integer(lev == "high"); n[seen] <- as.integer(pos)
  }
  a <- anv[anv$i_name == k, ]; a <- a[match(ids, a$lfdn), ]
  cat(sprintf("  %-6s exactly one screen shown: %d/%d | mismatches vs published: y=%d x=%d n=%d\n",
              k, sum(hits == 1), length(hits), sum(y != a$y_i), sum(x != a$x_i), sum(n != a$n)))
}

cat("\n## 3. Slide-6 checks rebuilt with the workbook formulas\n")
boxes <- paste0("v_", 74:82)
rules <- list(rep = c("v_74", "v_77"), pop = "v_75", brand = c("v_76", "v_78", "v_82"))
for (k in names(rules)) {
  mc  <- as.integer(rowSums(inc[, rules[[k]], drop = FALSE] == 1) >= 1)
  pub <- anv$man_check_i[anv$i_name == k][match(ids, anv$lfdn[anv$i_name == k])]
  cat(sprintf("  %-6s = any of %-22s (%d box%s) rate %5.1f%% | mismatches vs published: %d\n",
              k, paste(rules[[k]], collapse = ", "), length(rules[[k]]),
              ifelse(length(rules[[k]]) > 1, "es", ""), 100 * mean(mc), sum(mc != pub)))
}
cat("\n  Tick rate of each box:\n")
rates <- data.frame(box = boxes, tick_rate = sapply(boxes, function(v) mean(inc[[v]] == 1)),
                    used_by = sapply(boxes, function(v) {
                      u <- names(rules)[sapply(rules, function(r) v %in% r)]
                      if (length(u)) u else "-"
                    }), row.names = NULL)
print(transform(rates, tick_rate = round(100 * tick_rate, 1)), row.names = FALSE)
write.csv(rates, file.path(DIR_TAB, "09_slide6_boxes.csv"), row.names = FALSE)
cat("\n  Phi correlations between boxes. The export does not store box labels; the\n")
cat("  structure shows two clusters matching the coding: v_74/v_75/v_77 (numeric cues\n")
cat("  of the stats bar: rating, downloads, number of reviews) and v_76/v_78/v_82\n")
cat("  (identity cues: developer brand, app name, app icon).\n")
print(round(cor(inc[, boxes]), 2))

cat("\n## 4. Involvement scales rebuilt from the items\n")
items <- list(inv_app = c("v_176", "v_177", "v_178"),
              inv_dl  = c("v_179", "v_180", "v_181"),
              inv_cat = paste0("v_", 168:175))
reversed <- c("v_177", "v_168", "v_169", "v_170", "v_172", "v_173")
cat("  reverse-coded items (8 - x):", paste(reversed, collapse = ", "), "\n")
cat("  (inv_app: 1 of 3 items; inv_cat: 5 of 8 pairs, matching the polarity in Appendix B)\n\n")
rel <- list()
for (s in names(items)) {
  X <- sapply(items[[s]], function(v) if (v %in% reversed) 8 - inc[[v]] else inc[[v]])
  skipped <- apply(inc[, items[[s]]], 1, function(r) any(r %in% c(0, -77)))
  score   <- rowMeans(X)
  imputed <- abs(m3r[[s]] - mean(m3r[[s]])) < 1e-9
  Xc <- X[!skipped, , drop = FALSE]; k <- ncol(Xc)
  alpha <- k / (k - 1) * (1 - sum(apply(Xc, 2, var)) / var(rowSums(Xc)))
  cat(sprintf("  %-8s max |rebuilt - published| on complete rows = %.1e | rows with a skipped item = %2d | same rows as the imputed ones? %s | alpha = %.3f\n",
              s, max(abs(score[!skipped] - m3r[[s]][!skipped])), sum(skipped),
              isTRUE(all(unname(skipped) == imputed)), alpha))
  rel[[s]] <- data.frame(scale = s, items = k, reversed = sum(items[[s]] %in% reversed),
                         n_complete = nrow(Xc), n_imputed = sum(imputed), cronbach_alpha = alpha)
}
write.csv(do.call(rbind, rel), file.path(DIR_TAB, "09_scale_reliability.csv"), row.names = FALSE)

cat("\n## 5. The completed respondents excluded from the thesis\n")
inv_items <- unlist(items)
itd_items <- paste0("v_", 90:119)
never_inv <- apply(exc[, inv_items], 1, function(r) all(r == -77))
never_itd <- rowSums(exc[, itd_items] != -77) == 0
excl_type <- ifelse(never_inv & never_itd, "involvement pages and app screens never shown",
             ifelse(never_inv, "involvement pages never shown",
             ifelse(never_itd, "app screens never shown", "all blocks shown")))
cat("  excluded:", nrow(exc), "\n")
print(table(excl_type))
cat("  included: skipped items coded 0 =", sum(sapply(inv_items, function(v) inc[[v]] == 0)),
    "| never-shown items coded -77 =", sum(sapply(inv_items, function(v) inc[[v]] == -77)), "\n")
cat("  -> displayed but skipped -> mean-imputed; block never displayed -> excluded.\n")
cat("     Any 'all blocks shown' case above was excluded for a reason the export does not record.\n")

cat("\n## 6. Completion times of the included respondents\n")
cat("  under 60 s:", sum(inc$duration >= 0 & inc$duration < 60),
    "| not recorded (-1):", sum(inc$duration == -1),
    "| median:", median(inc$duration[inc$duration >= 0]), "s\n")

sink(type = "message"); sink(); close(con)
cat("Done. Log in analysis/outputs/logs/09_raw_export_checks.log\n")
