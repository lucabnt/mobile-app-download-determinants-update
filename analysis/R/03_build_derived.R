# 03_build_derived.R ---------------------------------------------------------
# Ricostruisce due dataset "tidy" a partire dai file originali, che restano
# invariati:
#   data/derived/long_measures.csv  -> 1473 righe (soggetto x variabile focale)
#   data/derived/wide_subjects.csv  ->  491 righe (una per rispondente)
# Il formato long e' il presupposto per i modelli a effetti misti e per tutte
# le analisi pooled che nella tesi non erano possibili sui file separati.
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

anv <- read_orig("M ANOVA_RM.csv")

long <- data.frame(
  subject   = anv$lfdn,
  focal     = factor(anv$i_name, levels = c("brand", "rep", "pop")),
  position  = factor(anv$n, levels = 1:3, labels = c("first", "second", "third")),
  pos_num   = anv$n,
  x         = anv$x_i,                       # 1 = livello alto, 0 = basso
  x_lab     = factor(anv$x_i_name, levels = c("low", "high")),
  y         = anv$y_i,                       # ITD, scala 1-7
  y_mc      = anv$y_i_mc,                    # centrata sulla media della focale
  manip_ok  = anv$man_check_i,
  comp      = as.integer(anv$n > 1),         # confronto: mostrata dopo altre app
  inv_app   = anv$inv_app_mc,
  inv_dl    = anv$inv_dl_mc,
  inv_cat   = anv$inv_cat_mc
)
long <- long[order(long$subject, long$pos_num), ]

# valori di x delle altre due variabili focali viste dallo stesso soggetto
x_by <- reshape(long[, c("subject", "focal", "x")], idvar = "subject",
                timevar = "focal", direction = "wide")
names(x_by) <- sub("^x[.]", "x_", names(x_by))
long <- merge(long, x_by, by = "subject")
long$x_other_brand <- ifelse(long$focal == "brand", NA, long$x_brand)
long$x_other_rep   <- ifelse(long$focal == "rep",   NA, long$x_rep)
long$x_other_pop   <- ifelse(long$focal == "pop",   NA, long$x_pop)

wide <- reshape(long[, c("subject", "focal", "y", "x", "pos_num", "manip_ok")],
                idvar = "subject", timevar = "focal", direction = "wide")
inv <- unique(long[, c("subject", "inv_app", "inv_dl", "inv_cat")])
wide <- merge(wide, inv, by = "subject")
wide$manip_ok_all <- with(wide, manip_ok.brand + manip_ok.rep + manip_ok.pop)

write.csv(long, file.path(DIR_DERIV, "long_measures.csv"), row.names = FALSE)
write.csv(wide, file.path(DIR_DERIV, "wide_subjects.csv"), row.names = FALSE)

cat("long_measures.csv:", nrow(long), "righe,", ncol(long), "colonne\n")
cat("wide_subjects.csv:", nrow(wide), "righe,", ncol(wide), "colonne\n")
cat("\nsoggetti per numero di manipulation check superati:\n")
print(table(wide$manip_ok_all))
