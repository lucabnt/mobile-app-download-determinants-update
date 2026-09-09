# 05_robustness.R ------------------------------------------------------------
# Controlli di robustezza che il lavoro 2023 non contiene:
#   D.1 restrizione ai rispondenti che superano il manipulation check
#   D.2 modello logit ordinale (la variabile dipendente e' una Likert 1-7)
#   D.3 correzione per test multipli sulle 9 regressioni originali
#   D.4 analisi di potenza: quale effetto minimo era rilevabile? (rilevante per
#       l'affermazione "nessuna interazione fra variabili focali")
#   D.5 moderazione dell'involvement stimata su un unico modello pooled
#
# Output: analysis/outputs/tables/05_*.csv, analysis/outputs/logs/05_robustness.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4)
  library(emmeans)
  library(ordinal)
})

con <- file(file.path(DIR_LOG, "05_robustness.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
long$comp_f   <- factor(long$comp, levels = c(0, 1), labels = c("prima", "dopo"))

fit_pool <- function(d) {
  lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
       data = d, REML = FALSE)
}
eff_by_focal <- function(m, tag) {
  e <- as.data.frame(summary(contrast(emmeans(m, ~ x_f | focal), "revpairwise"),
                             infer = c(TRUE, TRUE)))
  e$campione <- tag
  e[, c("campione", "focal", "estimate", "SE", "lower.CL", "upper.CL", "p.value")]
}

cat("=== D.1 ROBUSTEZZA AL MANIPULATION CHECK ===\n\n")
cat("Nella tesi le quote di superamento sono riportate in Tabella 3.2 ma mai\n")
cat("usate. Per popularity la quota e' 60.5% complessiva e 55.9% nel\n")
cat("sottocampione M2, non distinguibile dal 50% atteso per caso (p = 0.18):\n")
cat("il risultato nullo su popularity potrebbe riflettere una manipolazione\n")
cat("inefficace piu' che un'assenza di effetto.\n\n")

cat("Osservazioni per esito del manipulation check:\n")
print(table(focale = long$focal, check_superato = long$manip_ok))

m_all   <- fit_pool(long)
m_ok    <- fit_pool(long[long$manip_ok == 1, ])
subj_ok <- names(which(tapply(long$manip_ok, long$subject, sum) == 3))
m_ok3   <- fit_pool(long[long$subject %in% as.integer(subj_ok), ])

cat("\nSoggetti che superano tutti e tre i check:", length(subj_ok), "su 491\n\n")

rob <- rbind(
  eff_by_focal(m_all, "tutte le osservazioni (N=1473)"),
  eff_by_focal(m_ok,  sprintf("solo check superato (N=%d)", sum(long$manip_ok == 1))),
  eff_by_focal(m_ok3, sprintf("solo soggetti 3/3 check (N=%d)", 3 * length(subj_ok)))
)
print(rob, digits = 4)
write.csv(rob, file.path(DIR_TAB, "05_manipulation_check_robustness.csv"), row.names = FALSE)

cat("\n\n=== D.2 MODELLO LOGIT ORDINALE A EFFETTI MISTI ===\n\n")
cat("La ITD e' misurata su scala Likert 1-7: OLS ne assume intervalli uguali e\n")
cat("supporto illimitato. Qui la stessa specifica come logit ordinale cumulativo.\n\n")
long$y_ord <- factor(long$y, levels = 1:7, ordered = TRUE)
m_ord <- clmm(y_ord ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, link = "logit")
print(summary(m_ord))

cat("\nOdds ratio dell'effetto della manipolazione, per variabile focale:\n")
cf <- coef(summary(m_ord))
b_brand <- cf["x_fhigh", "Estimate"]
for (f in c("brand", "rep", "pop")) {
  nm <- paste0("focal", f, ":x_fhigh")
  b  <- if (f == "brand") b_brand else b_brand + cf[nm, "Estimate"]
  cat(sprintf("  %-6s  log-odds = %+.4f   OR = %.3f\n", f, b, exp(b)))
}
cat("\nGli OR > 1 indicano maggiore probabilita' di ITD elevata con il livello alto.\n")

cat("\n\n=== D.3 CORREZIONE PER TEST MULTIPLI SULLE 9 REGRESSIONI ORIGINALI ===\n\n")
cf_orig <- read.csv(file.path(DIR_TAB, "01_replication_coefficients.csv"))
cf_orig <- cf_orig[cf_orig$term != "(Intercept)", ]
cf_orig$p_holm <- p.adjust(cf_orig$p_value, method = "holm")
cf_orig$p_bh   <- p.adjust(cf_orig$p_value, method = "BH")
cat("Coefficienti stimati (intercette escluse):", nrow(cf_orig), "\n")
cat("Significativi a p<0.10 senza correzione:", sum(cf_orig$p_value < 0.10), "\n")
cat("Significativi a p<0.05 senza correzione:", sum(cf_orig$p_value < 0.05), "\n")
cat("Sopravvivono a Holm (p<0.05):          ", sum(cf_orig$p_holm  < 0.05), "\n")
cat("Sopravvivono a Benjamini-Hochberg (FDR<0.05):", sum(cf_orig$p_bh < 0.05), "\n\n")
surv <- cf_orig[order(cf_orig$p_value), c("model", "term", "estimate", "se", "p_value", "p_holm", "p_bh")]
cat("Primi 15 coefficienti per p-value grezzo:\n")
print(head(surv, 15), digits = 4, row.names = FALSE)
write.csv(surv, file.path(DIR_TAB, "05_multiplicity_adjusted.csv"), row.names = FALSE)

cat("\n\n=== D.4 POTENZA: QUALE EFFETTO ERA RILEVABILE? ===\n\n")
cat("La tesi conclude che non esistono interazioni a due vie fra le variabili\n")
cat("focali. Con i campioni del Modello 2 si puo' calcolare l'effetto minimo\n")
cat("rilevabile (MDE) con potenza 80% e alpha 0.05: MDE = (t_crit + t_pow) * SE.\n\n")
inter <- cf_orig[grepl("^M2_", cf_orig$model) & grepl(":", cf_orig$term) &
                   grepl("x_(rep|pop|brand):x_(rep|pop|brand)", cf_orig$term), ]
sd_y <- c(brand = 1.5879, rep = 1.7095, pop = 1.5691)
inter$mde <- (qnorm(0.975) + qnorm(0.80)) * inter$se
inter$mde_sd <- inter$mde / sd_y[sub("^M2_", "", inter$model)]
print(inter[, c("model", "term", "estimate", "se", "p_value", "mde", "mde_sd")],
      digits = 3, row.names = FALSE)
cat("\nInterpretazione: il disegno poteva rilevare solo interazioni dell'ordine di\n")
cat(sprintf("%.2f-%.2f punti Likert (%.2f-%.2f deviazioni standard). L'assenza di\n",
            min(inter$mde), max(inter$mde), min(inter$mde_sd), max(inter$mde_sd)))
cat("evidenza non e' evidenza di assenza: i risultati sono inconcludenti, non nulli.\n")
write.csv(inter[, c("model", "term", "estimate", "se", "p_value", "mde", "mde_sd")],
          file.path(DIR_TAB, "05_power_m2_interactions.csv"), row.names = FALSE)

cat("\n\n=== D.5 MODERAZIONE DELL'INVOLVEMENT, MODELLO POOLED ===\n\n")
cat("Nella tesi le moderazioni sono lette da 9 regressioni separate. Qui sono\n")
cat("stimate in un unico modello con struttura a misure ripetute.\n\n")
m_inv <- lmer(y ~ focal * x_f * inv_app + focal * x_f * inv_dl + focal * x_f * inv_cat +
                position + (1 | subj_f), data = long, REML = FALSE)
print(car::Anova(m_inv, type = "III"))

cat("\nPendenza dell'effetto della manipolazione rispetto a ciascun involvement\n")
cat("(variazione dell'effetto alto-vs-basso per +1 SD di involvement):\n")
for (v in c("inv_app", "inv_dl", "inv_cat")) {
  tr <- emtrends(m_inv, ~ x_f | focal, var = v)
  ct <- as.data.frame(summary(contrast(tr, "revpairwise"), infer = c(TRUE, TRUE)))
  ct$moderatore <- v
  print(ct[, c("moderatore", "focal", "estimate", "SE", "lower.CL", "upper.CL", "p.value")],
        digits = 3, row.names = FALSE)
  cat("\n")
}

sink(type = "message"); sink(); close(con)
cat("Fatto. Log in analysis/outputs/logs/05_robustness.log\n")
