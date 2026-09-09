# 01_replication.R -----------------------------------------------------------
# Replica fedele delle analisi della tesi 2023 (ANOVA + 9 regressioni OLS),
# Lo script originale non e' versionato qui: vive nel repository del lavoro 2023,
#   github.com/lucabnt/mobile-app-download-determinants
#   -> "Data and Code/Determinants of Download on Mobile App Stores - An Empirical Analysis.r"
# Rispetto a quello, qui ci sono due sole correzioni tecniche:
#   1. summary(M4_rep) / summary(M4_pop)  ->  summary(M2_rep) / summary(M2_pop)
#      (nell'originale sono riferimenti a oggetti inesistenti, lo script si
#       interrompe con "object 'M4_rep' not found").
#   2. lettura dei CSV con fileEncoding = "UTF-8-BOM".
# Nessuna specifica di modello e nessun dato sono stati modificati.
#
# Output: analysis/outputs/tables/01_replication_coefficients.csv
#         analysis/outputs/tables/01_replication_modelfit.csv
#         analysis/outputs/logs/01_replication.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

con <- file(file.path(DIR_LOG, "01_replication.log"), open = "wt")
sink(con, split = TRUE)
sink(con, type = "message")

cat("=== REPLICA TESI 2023 ===\n")
cat("R version:", R.version.string, "\n")
cat("Data esecuzione:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# --- ANOVA a misure ripetute ------------------------------------------------
anova_dat <- read_orig("M ANOVA_RM.csv")
cat("--- M ANOVA_RM.csv ---\n")
cat("Osservazioni:", nrow(anova_dat), " | soggetti:", length(unique(anova_dat$lfdn)), "\n\n")

ANOVA.aov <- aov(y_i ~ i_name * x_i_name * n_name + Error(lfdn), data = anova_dat)
cat("--- aov(y_i ~ i_name*x_i_name*n_name + Error(lfdn)) [come da tesi] ---\n")
print(summary(ANOVA.aov))

regression.aov <- lm(y_i ~ i_name * x_i_name * n_name, data = anova_dat)
cat("\n--- lm equivalente ---\n")
print(summary(regression.aov))

# --- Regressioni ------------------------------------------------------------
specs <- list(
  list(label = "M1_rep",   file = "M1_rep.csv",
       f = y_rep_1   ~ x_rep   + x_rep*inv_app_mc   + x_rep*inv_dl_mc   + x_rep*inv_cat_mc),
  list(label = "M1_pop",   file = "M1_pop.csv",
       f = y_pop_1   ~ x_pop   + x_pop*inv_app_mc   + x_pop*inv_dl_mc   + x_pop*inv_cat_mc),
  list(label = "M1_brand", file = "M1_brand.csv",
       f = y_brand_1 ~ x_brand + x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc),

  list(label = "M2_rep",   file = "M2_rep.csv",
       f = y_rep_3   ~ x_rep   + x_rep*x_brand + x_rep*x_pop
                     + x_rep*inv_app_mc   + x_rep*inv_dl_mc   + x_rep*inv_cat_mc),
  list(label = "M2_pop",   file = "M2_pop.csv",
       f = y_pop_3   ~ x_pop   + x_pop*x_brand + x_pop*x_rep
                     + x_pop*inv_app_mc   + x_pop*inv_dl_mc   + x_pop*inv_cat_mc),
  list(label = "M2_brand", file = "M2_brand.csv",
       f = y_brand_3 ~ x_brand + x_brand*x_rep + x_brand*x_pop
                     + x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc),

  list(label = "M3_rep",   file = "M3_rep.csv",
       f = y_rep   ~ x_rep   + x_rep*inv_app_mc   + x_rep*inv_dl_mc   + x_rep*inv_cat_mc   + x_rep*comp_rep),
  list(label = "M3_pop",   file = "M3_pop.csv",
       f = y_pop   ~ x_pop   + x_pop*inv_app_mc   + x_pop*inv_dl_mc   + x_pop*inv_cat_mc   + x_pop*comp_pop),
  list(label = "M3_brand", file = "M3_brand.csv",
       f = y_brand ~ x_brand + x_brand*inv_app_mc + x_brand*inv_dl_mc + x_brand*inv_cat_mc + x_brand*comp_brand)
)

coef_tab <- list()
fit_tab  <- list()

for (sp in specs) {
  d <- read_orig(sp$file)
  m <- lm(sp$f, data = d)
  cat("\n\n=== ", sp$label, " (", sp$file, ", N righe file = ", nrow(d), ") ===\n", sep = "")
  print(summary(m))

  coef_tab[[sp$label]] <- tidy_lm(m, sp$label)

  # manipulation check: quota di rispondenti che ha superato il check
  mc_col <- grep("^man_check_", names(d), value = TRUE)
  mc <- if (length(mc_col) == 1) 100 * mean(d[[mc_col]], na.rm = TRUE) else NA_real_

  s <- summary(m)
  fit_tab[[sp$label]] <- data.frame(
    model = sp$label,
    n_rows_file = nrow(d),
    n_used = length(stats::residuals(m)),
    r2 = s$r.squared, adj_r2 = s$adj.r.squared,
    f_stat = unname(s$fstatistic[1]),
    df1 = unname(s$fstatistic[2]), df2 = unname(s$fstatistic[3]),
    f_pvalue = unname(pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE)),
    sigma = s$sigma,
    manip_check_pct = mc
  )
}

coefs <- do.call(rbind, coef_tab)
coefs$sig <- stars(coefs$p_value)
fits  <- do.call(rbind, fit_tab)

write.csv(coefs, file.path(DIR_TAB, "01_replication_coefficients.csv"), row.names = FALSE)
write.csv(fits,  file.path(DIR_TAB, "01_replication_modelfit.csv"),     row.names = FALSE)

cat("\n\n=== SINTESI FIT ===\n")
print(fits, digits = 4)

cat("\n\n=== COEFFICIENTI FOCALI (x_i) ===\n")
focal <- coefs[coefs$term %in% c("x_rep", "x_pop", "x_brand"), ]
print(focal[, c("model", "term", "estimate", "se", "p_value", "sig")], digits = 4)

sink(type = "message"); sink(); close(con)
cat("Fatto. Log in analysis/outputs/logs/01_replication.log\n")
