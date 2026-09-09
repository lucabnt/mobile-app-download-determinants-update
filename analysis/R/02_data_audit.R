# 02_data_audit.R ------------------------------------------------------------
# Verifica di integrita' dei dataset originali: coerenza tra file, corrispondenza
# con le statistiche descrittive pubblicate (Tabella 3.1) e con i numeri
# riportati nel testo della tesi.
# Output: analysis/outputs/logs/02_data_audit.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

con <- file(file.path(DIR_LOG, "02_data_audit.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

cat("=== AUDIT DATI ORIGINALI ===\n\n")

anv <- read_orig("M ANOVA_RM.csv")
plt <- read_orig("M plots.csv")

cat("## 1. Struttura del file a misure ripetute\n")
cat("righe:", nrow(anv), "| soggetti unici:", length(unique(anv$lfdn)), "\n")
cat("righe per soggetto:\n"); print(table(table(anv$lfdn)))
cat("\nclasse di lfdn nel file:", class(anv$lfdn), " <- rilevante per Error(lfdn)\n")
cat("\ncrosstab i x n (ogni soggetto deve vedere ogni i una volta e ogni n una volta):\n")
print(table(anv$i_name, anv$n))
cat("\ncrosstab i x x_i:\n"); print(table(anv$i_name, anv$x_i))
cat("\nquadrato latino? soggetti con i duplicati:",
    sum(tapply(anv$i_name, anv$lfdn, function(z) any(duplicated(z)))), "\n")
cat("soggetti con n duplicati:",
    sum(tapply(anv$n, anv$lfdn, function(z) any(duplicated(z)))), "\n")

cat("\n## 2. y_i_mc e' davvero il mean-centering di y_i?\n")
for (v in unique(anv$i_name)) {
  s <- anv[anv$i_name == v, ]
  cat(sprintf("  %-6s mean(y_i)=%.4f  mean(y_i_mc)=%+.4f  max|y_i - mean - y_mc|=%.6f\n",
              v, mean(s$y_i), mean(s$y_i_mc), max(abs(s$y_i - mean(s$y_i) - s$y_i_mc))))
}
cat("  globale: mean(y_i)=", round(mean(anv$y_i),4),
    " max|y_i-mean-y_mc| =", round(max(abs(anv$y_i - mean(anv$y_i) - anv$y_i_mc)), 6), "\n")

cat("\n## 3. Statistiche descrittive vs Tabella 3.1 della tesi\n")
tesi <- data.frame(
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
cmp <- merge(tesi, emp, by = "var", suffixes = c("_tesi", "_dati"))
cmp$d_mean <- round(cmp$mean_dati - cmp$mean_tesi, 4)
cmp$d_sd   <- round(cmp$sd_dati   - cmp$sd_tesi,   4)
print(cmp, digits = 5)

cat("\n## 4. Coerenza tra i file dei modelli e il file ANOVA\n")
for (v in c("rep","pop","brand")) {
  d  <- m3[[v]]
  a  <- anv[anv$i_name == v, ]
  k  <- merge(d[, c("lfdn", paste0("y_", v), paste0("x_", v), paste0("comp_", v))],
              a[, c("lfdn","y_i","x_i","n")], by = "lfdn")
  cat(sprintf("  %-6s merge n=%d | y discordanti=%d | x discordanti=%d | comp!=(n>1)=%d\n",
              v, nrow(k), sum(k[[paste0("y_", v)]] != k$y_i),
              sum(k[[paste0("x_", v)]] != k$x_i),
              sum(k[[paste0("comp_", v)]] != as.integer(k$n > 1))))
}

cat("\n## 5. Sottocampioni M1 (n=1) e M2 (n=3): numerosita' attese vs effettive\n")
for (v in c("rep","pop","brand")) {
  a  <- anv[anv$i_name == v, ]
  n1 <- sum(a$n == 1); n3 <- sum(a$n == 3)
  d1 <- nrow(read_orig(paste0("M1_", v, ".csv")))
  d2 <- nrow(read_orig(paste0("M2_", v, ".csv")))
  cat(sprintf("  %-6s  n=1 attesi %3d / file M1 %3d %s |  n=3 attesi %3d / file M2 %3d %s\n",
              v, n1, d1, ifelse(n1 == d1, "ok", "!! DIVERGENZA"),
              n3, d2, ifelse(n3 == d2, "ok", "!! DIVERGENZA")))
}

cat("\n## 6. Manipulation check: quote di superamento\n")
for (mod in c("M1","M2","M3")) for (v in c("rep","pop","brand")) {
  d <- read_orig(sprintf("%s_%s.csv", mod, v))
  mc <- d[[paste0("man_check_", v)]]
  bt <- binom.test(sum(mc), length(mc), p = 0.5)
  cat(sprintf("  %s_%-6s %5.2f%%  (n=%3d, IC95%% %.1f-%.1f%%, p vs 50%% = %.4f)\n",
              mod, v, 100*mean(mc), length(mc),
              100*bt$conf.int[1], 100*bt$conf.int[2], bt$p.value))
}

cat("\n## 7. Valori mancanti e range\n")
for (f in list.files(DIR_ORIG, pattern = "[.]csv$")) {
  d <- read_orig(f)
  cat(sprintf("  %-16s righe=%4d colonne=%2d NA=%d\n", f, nrow(d), ncol(d), sum(is.na(d))))
}

cat("\n## 8. Distribuzione della variabile dipendente (scala Likert 1-7)\n")
for (v in c("rep","pop","brand")) {
  y <- m3[[v]][[paste0("y_", v)]]
  cat(sprintf("  y_%-6s ", v)); print(table(factor(y, levels = 1:7)))
}

sink(type="message"); sink(); close(con)
