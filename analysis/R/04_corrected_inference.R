# 04_corrected_inference.R ---------------------------------------------------
# Correzione dei due difetti inferenziali principali del lavoro 2023:
#
#  (A) ANOVA a misure ripetute. Nell'originale `aov(... + Error(lfdn))` riceve
#      lfdn come intero: aov lo tratta come covariata continua, lo strato
#      Error(lfdn) collassa a 1 df senza residui e la struttura a misure
#      ripetute NON viene modellata. Qui la si specifica correttamente
#      (soggetto come fattore) e si aggiunge un modello a effetti misti e una
#      versione OLS con errori standard cluster-robust per soggetto.
#
#  (B) Test formale della graduatoria brand > reputation > popularity. Nella
#      tesi la graduatoria e' dedotta confrontando a occhio coefficienti stimati
#      su sottocampioni diversi, senza alcun test della differenza. Qui si stima
#      un unico modello pooled sulle 1473 osservazioni con interazione
#      focale x manipolazione e si testano i contrasti a coppie.
#
# Output: analysis/outputs/tables/04_*.csv, analysis/outputs/logs/04_*.log
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4)
  library(emmeans)
  library(clubSandwich)
  library(car)
})

con <- file(file.path(DIR_LOG, "04_corrected_inference.log"), open = "wt")
sink(con, split = TRUE); sink(con, type = "message")

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))

cat("=== (A) ANOVA A MISURE RIPETUTE ===\n\n")

cat("--- A.1 Specifica originale della tesi: Error(lfdn) con lfdn intero ---\n")
a_orig <- aov(y ~ focal * x_f * position + Error(subject), data = long)
print(summary(a_orig))
cat("\nNOTA: lo strato 'Error: subject' ha 1 df e nessun residuo. La struttura\n")
cat("a misure ripetute non e' modellata; i test dello strato 'Within' sono\n")
cat("quelli di una ANOVA fra osservazioni indipendenti su 1454 df residui.\n")
cat("Il testo della tesi riporta invece df = 4 al denominatore.\n\n")

cat("--- A.2 Specifica corretta: soggetto come fattore ---\n")
a_corr <- aov(y ~ focal * x_f * position + Error(subj_f), data = long)
print(summary(a_corr))

cat("\n--- A.3 Modello lineare a effetti misti, intercetta casuale per soggetto ---\n")
m_mix <- lmer(y ~ focal * x_f * position + inv_app + inv_dl + inv_cat + (1 | subj_f),
              data = long, REML = TRUE)
print(summary(m_mix))
cat("\nVarianza fra soggetti / totale (ICC):\n")
vc <- as.data.frame(VarCorr(m_mix))
icc <- vc$vcov[1] / sum(vc$vcov)
cat(sprintf("  ICC = %.4f (var soggetto = %.4f, residuo = %.4f)\n", icc, vc$vcov[1], vc$vcov[2]))

cat("\n--- A.4 Anova di tipo II sul modello misto (Wald chi-quadro) ---\n")
print(Anova(m_mix, type = "II"))

cat("\n--- A.5 OLS con errori standard cluster-robust per soggetto (CR2) ---\n")
m_ols <- lm(y ~ focal * x_f * position, data = long)
ct <- coef_test(m_ols, vcov = "CR2", cluster = long$subject, test = "Satterthwaite")
print(ct)

cat("\n\n=== (B) TEST FORMALE DELLA GRADUATORIA FRA VARIABILI FOCALI ===\n\n")

cat("Modello pooled: y ~ focal * x + posizione + involvement + (1|soggetto)\n")
cat("su tutte le 1473 osservazioni. L'interazione focal:x quantifica di quanto\n")
cat("l'effetto della manipolazione differisce fra brand, reputation e popularity.\n\n")

m_pool <- lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
print(summary(m_pool))

cat("\n--- B.1 L'interazione focal x manipolazione e' necessaria? (LRT) ---\n")
m_pool0 <- lmer(y ~ focal + x_f + position + inv_app + inv_dl + inv_cat + (1 | subj_f),
                data = long, REML = FALSE)
print(anova(m_pool0, m_pool))

cat("\n--- B.2 Effetto della manipolazione (alto vs basso) entro ciascuna focale ---\n")
emm <- emmeans(m_pool, ~ x_f | focal)
eff <- contrast(emm, "revpairwise")
print(summary(eff, infer = c(TRUE, TRUE)))

cat("\n--- B.3 Confronto a coppie fra gli effetti (correzione di Holm) ---\n")
cat("Questo e' il test che la tesi non svolge: brand batte davvero reputation?\n")
diffs <- contrast(emmeans(m_pool, ~ x_f * focal), interaction = c("revpairwise", "revpairwise"))
print(summary(diffs, adjust = "holm", infer = c(TRUE, TRUE)))

rank_tab <- as.data.frame(summary(eff, infer = c(TRUE, TRUE)))
write.csv(rank_tab, file.path(DIR_TAB, "04_effect_by_focal.csv"), row.names = FALSE)
write.csv(as.data.frame(summary(diffs, adjust = "holm", infer = c(TRUE, TRUE))),
          file.path(DIR_TAB, "04_pairwise_focal_contrasts.csv"), row.names = FALSE)

cat("\n--- B.4 Dimensioni dell'effetto in unita' di deviazione standard ---\n")
sd_y <- tapply(long$y, long$focal, sd)
for (f in levels(long$focal)) {
  e <- rank_tab[rank_tab$focal == f, ]
  cat(sprintf("  %-6s  beta = %+.4f  (SD di y = %.4f)  d = %+.3f\n",
              f, e$estimate, sd_y[[f]], e$estimate / sd_y[[f]]))
}

cat("\n\n=== (C) EFFETTO DEL CONFRONTO (posizione) SULLA GRADUATORIA ===\n")
cat("Interazione a tre vie focale x manipolazione x confronto, stimata su un\n")
cat("unico modello anziche' su sottocampioni separati (M1 vs M2 della tesi).\n\n")
long$comp_f <- factor(long$comp, levels = c(0, 1), labels = c("prima", "dopo"))
m_comp <- lmer(y ~ focal * x_f * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
print(Anova(m_comp, type = "III"))
cat("\nEffetto della manipolazione per focale e posizione di confronto:\n")
emm_c <- emmeans(m_comp, ~ x_f | focal * comp_f)
print(summary(contrast(emm_c, "revpairwise"), infer = c(TRUE, TRUE)))
write.csv(as.data.frame(summary(contrast(emm_c, "revpairwise"), infer = c(TRUE, TRUE))),
          file.path(DIR_TAB, "04_effect_by_focal_and_comparison.csv"), row.names = FALSE)

sink(type = "message"); sink(); close(con)
cat("Fatto. Log in analysis/outputs/logs/04_corrected_inference.log\n")
