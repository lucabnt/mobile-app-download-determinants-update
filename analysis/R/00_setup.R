# 00_setup.R -----------------------------------------------------------------
# Percorsi, helper e opzioni condivise da tutti gli script di analisi.
# Eseguire gli script dalla root del repository:
#   Rscript analysis/R/01_replication.R
# ----------------------------------------------------------------------------

options(stringsAsFactors = FALSE, width = 120)

ROOT      <- normalizePath(".", winslash = "/")
DIR_ORIG  <- file.path(ROOT, "original", "data")
DIR_DERIV <- file.path(ROOT, "data", "derived")
DIR_OUT   <- file.path(ROOT, "analysis", "outputs")
DIR_TAB   <- file.path(DIR_OUT, "tables")
DIR_FIG   <- file.path(DIR_OUT, "figures")
DIR_LOG   <- file.path(DIR_OUT, "logs")

for (d in c(DIR_DERIV, DIR_TAB, DIR_FIG, DIR_LOG)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# I CSV originali hanno un BOM UTF-8: senza fileEncoding la prima colonna
# viene letta come "ï..lfdn".
read_orig <- function(file) {
  read.csv(file.path(DIR_ORIG, file), header = TRUE, fileEncoding = "UTF-8-BOM")
}

# Estrae coefficiente, SE, t e p da un lm in un data.frame ordinato.
tidy_lm <- function(model, label) {
  s <- summary(model)
  cf <- as.data.frame(coef(s))
  data.frame(
    model    = label,
    term     = rownames(cf),
    estimate = cf[[1]],
    se       = cf[[2]],
    statistic= cf[[3]],
    p_value  = cf[[4]],
    n        = length(stats::residuals(model)),
    r2       = s$r.squared,
    adj_r2   = s$adj.r.squared,
    row.names = NULL
  )
}

stars <- function(p) {
  ifelse(is.na(p), "", ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))))
}
