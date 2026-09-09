# 06_figures.R ---------------------------------------------------------------
# Figures based on the corrected estimates (mixed-effects models), for use in
# the review document and the blog post.
#   fig_01_focal_effects.png        manipulation effect by focal variable
#   fig_02_slide6_subgroup.png      same estimates within the slide-6 subgroup
#   fig_03_comparison.png           effect by focal variable and comparison
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
                        labels = c("shown first", "after other apps"))

lab_focal <- c(brand = "Developer\nbrand", rep = "Reputation\n(rating)",
               pop = "Popularity\n(downloads)")
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
  e$sample <- tag
  e
}

# --- Figure 1: manipulation effect by focal variable -------------------------
m_all <- fit_pool(long)
e1 <- eff_tab(m_all, "all observations")
e1$focal <- factor(e1$focal, levels = c("brand", "rep", "pop"))

p1 <- ggplot(e1, aes(x = focal, y = estimate, colour = focal)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.12, linewidth = 0.7) +
  geom_point(size = 3.2) +
  scale_x_discrete(labels = lab_focal) +
  scale_colour_manual(values = pal, guide = "none") +
  labs(title = "How far intention to download moves from the low to the high level",
       subtitle = "Mixed-effects model on all 1,473 observations, random intercept by respondent",
       x = NULL, y = "Difference in ITD (1-7 scale), 95% CI",
       caption = paste("Brand and reputation are not statistically distinguishable (p = 0.22).",
                       "Both beat popularity (p < 0.001).",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_01_focal_effects.png"), p1,
       width = 7, height = 4.6, dpi = 200)

# --- Figure 2: the slide-6 subgroup ------------------------------------------
m_ok <- fit_pool(long[long$manip_ok == 1, ])
e2 <- rbind(e1, eff_tab(m_ok, "says they used the cue"))
e2$focal <- factor(e2$focal, levels = c("brand", "rep", "pop"))
e2$sample <- factor(e2$sample, levels = c("all observations", "says they used the cue"))

p2 <- ggplot(e2, aes(x = focal, y = estimate, colour = focal, shape = sample)) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL),
                width = 0.12, linewidth = 0.7,
                position = position_dodge(width = 0.45)) +
  geom_point(size = 3, position = position_dodge(width = 0.45)) +
  scale_x_discrete(labels = lab_focal) +
  scale_colour_manual(values = pal, guide = "none") +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  labs(title = "The popularity null is not as solid as it looks",
       subtitle = "Same estimates, restricted to respondents who say they considered that cue (slide 6)",
       x = NULL, y = "Difference in ITD (1-7 scale), 95% CI",
       caption = paste("Within the subgroup the popularity effect goes from +0.22 (p = 0.075) to +0.51 (p = 0.002).",
                       "Caution: slide 6 does not verify that the manipulation was perceived, it asks which cues",
                       "the respondent says they used. This is post-treatment conditioning on a mediator-like",
                       "variable: it shows the null is fragile, it does not overturn it.",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_02_slide6_subgroup.png"), p2,
       width = 7.4, height = 4.8, dpi = 200)

# --- Figure 3: effect by focal variable and presence of comparison -----------
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
                      labels = c(brand = "Brand", rep = "Reputation", pop = "Popularity")) +
  labs(title = "What changes once users can compare several apps",
       subtitle = "Manipulation effect estimated on a single model, not on separate subsamples",
       x = NULL, y = "Difference in ITD (1-7 scale), 95% CI",
       caption = paste("Brand weakens (1.41 -> 0.90), reputation strengthens (0.69 -> 0.91): they converge, they do not swap.",
                       "The three-way interaction is not significant (p = 0.11): the pattern is suggestive, not established.",
                       sep = "\n")) +
  theme_thesis
ggsave(file.path(DIR_FIG, "fig_03_comparison.png"), p3,
       width = 7.4, height = 4.8, dpi = 200)

cat("Figures saved in", DIR_FIG, "\n")
print(list.files(DIR_FIG))
