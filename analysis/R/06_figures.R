# 06_figures.R ---------------------------------------------------------------
# Figure basate sulle stime corrette (modelli a effetti misti), da usare nel
# documento di revisione e nel blog post.
#   fig_01_effetti_focali.png       effetto della manipolazione per variabile
#   fig_02_manipulation_check.png   stesse stime nel sottogruppo di slide 6
#   fig_03_confronto.png            effetto per variabile e posizione di confronto
# Output: analysis/outputs/figures/
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")
suppressPackageStartupMessages({
  library(lme4); library(emmeans); library(ggplot2)
})

long <- read.csv(file.path(DIR_DERIV, "long_measures.csv"))
long$focal    <- factor(long$focal,    levels = c("brand", "rep", "pop"))
long$position <- factor(long$position, levels = c("first", "second", "third"))
long$subj_f   <- factor(long$subject)
long$x_f      <- factor(long$x, levels = c(0, 1), labels = c("low", "high"))
long$comp_f   <- factor(long$comp, levels = c(0, 1),
                        labels = c("mostrata per prima", "dopo altre app"))

lab_focal <- c(brand = "Brand dello\nsviluppatore", rep = "Reputazione\n(rating)",
               pop = "Popolarita'\n(download)")
pal <- c(brand = "#1f4e79", rep = "#c0504d", pop = "#7f7f7f")

theme_thesis <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(colour = "grey30", size = 9),
        plot.caption = element_text(colour = "grey45", size = 8, hjust = 0),
        legend.position = "top")

fit_pool <- function(d) lmer(y ~ focal * x_f + position + inv_app + inv_dl + inv_cat +
                               (1 | subj_f), data = d, REML = FALSE)
eff_tab <- function(m, tag) {
  e <- as.data.frame(summary(contrast(emmeans(m, ~ x_f | focal), "revpairwise"),
                             infer = c(TRUE, TRUE)))
  e$campione <- tag
  e
}

# --- Figura 1: effetto della manipolazione per variabile focale --------------
m_all <- fit_pool(long)
e1 <- eff_tab(m_all, "tutte le osservazioni")
e1$focal <- factor(e1$focal, levels = c("brand", "rep", "pop"))

p1 <- ggplot(e1, aes(x = focal, y = estimate, colour = focal)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.12, linewidth = 0.7) +
  geom_point(size = 3.2) +
  scale_x_discrete(labels = lab_focal) +
  scale_colour_manual(values = pal, guide = "none") +
  labs(title = "Quanto sposta l'intenzione di download passare dal livello basso all'alto",
       subtitle = "Modello a effetti misti su tutte le 1.473 osservazioni, intercetta casuale per rispondente",
       x = NULL, y = "Differenza in ITD (scala 1-7), IC 95%",
       caption = paste("Brand e reputazione non sono statisticamente distinguibili (p = 0,22).",
                       "Entrambe superano la popolarita' (p < 0,001).",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_01_effetti_focali.png"), p1,
       width = 7, height = 4.6, dpi = 200)

# --- Figura 2: robustezza al manipulation check ------------------------------
m_ok <- fit_pool(long[long$manip_ok == 1, ])
e2 <- rbind(e1, eff_tab(m_ok, "dichiara di aver usato il segnale"))
e2$focal <- factor(e2$focal, levels = c("brand", "rep", "pop"))
e2$campione <- factor(e2$campione,
                      levels = c("tutte le osservazioni", "dichiara di aver usato il segnale"))

p2 <- ggplot(e2, aes(x = focal, y = estimate, colour = focal, shape = campione)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL),
                width = 0.12, linewidth = 0.7,
                position = position_dodge(width = 0.45)) +
  geom_point(size = 3, position = position_dodge(width = 0.45)) +
  scale_x_discrete(labels = lab_focal) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  labs(title = "Il nullo sulla popolarita' non e' solido come sembra",
       subtitle = "Stesse stime, ristrette a chi dichiara di aver considerato quel segnale (slide 6)",
       x = NULL, y = "Differenza in ITD (scala 1-7), IC 95%",
       caption = paste("Nel sottogruppo l'effetto della popolarita' passa da +0,22 (p = 0,075) a +0,51 (p = 0,002).",
                       "Attenzione: la slide 6 non verifica se la manipolazione e' stata percepita, chiede quali",
                       "segnali il rispondente dichiara di aver usato. E' condizionamento post-trattamento su una",
                       "variabile simile a un mediatore: indica fragilita' del nullo, non lo ribalta.",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_02_manipulation_check.png"), p2,
       width = 7.4, height = 4.8, dpi = 200)

# --- Figura 3: effetto per variabile e presenza di confronto -----------------
m_comp <- lmer(y ~ focal * x_f * comp_f + inv_app + inv_dl + inv_cat + (1 | subj_f),
               data = long, REML = FALSE)
e3 <- as.data.frame(summary(contrast(emmeans(m_comp, ~ x_f | focal * comp_f), "revpairwise"),
                            infer = c(TRUE, TRUE)))
e3$focal <- factor(e3$focal, levels = c("brand", "rep", "pop"))

p3 <- ggplot(e3, aes(x = comp_f, y = estimate, colour = focal, group = focal)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.08, linewidth = 0.6) +
  geom_point(size = 3) +
  scale_colour_manual(values = pal, name = NULL,
                      labels = c(brand = "Brand", rep = "Reputazione", pop = "Popolarita'")) +
  labs(title = "Cosa cambia quando l'utente puo' confrontare piu' app",
       subtitle = "Effetto della manipolazione stimato su un unico modello, non su sottocampioni separati",
       x = NULL, y = "Differenza in ITD (scala 1-7), IC 95%",
       caption = paste("Il brand si indebolisce (1,41 -> 0,90), la reputazione si rafforza (0,69 -> 0,91): convergono, non si invertono.",
                       "L'interazione a tre vie non e' significativa (p = 0,11): il pattern e' suggestivo, non dimostrato.",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_03_confronto.png"), p3,
       width = 7.4, height = 4.8, dpi = 200)

cat("Figure salvate in", DIR_FIG, "\n")
print(list.files(DIR_FIG))
