# 03_build_derived.R ---------------------------------------------------------
# Rebuilds two tidy datasets from the original files, which stay untouched:
#   data/derived/long_measures.csv  -> 1473 rows (subject x focal variable)
#   data/derived/wide_subjects.csv  ->  491 rows (one per respondent)
# The long format is what makes mixed-effects models and pooled analyses
# possible; the original per-model files do not allow them.
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

anv <- read_orig("M ANOVA_RM.csv")

long <- data.frame(
  subject   = anv$lfdn,
  focal     = factor(anv$i_name, levels = c("brand", "rep", "pop")),
  position  = factor(anv$n, levels = 1:3, labels = c("first", "second", "third")),
  pos_num   = anv$n,
  x         = anv$x_i,                       # 1 = high level, 0 = low
  x_lab     = factor(anv$x_i_name, levels = c("low", "high")),
  y         = anv$y_i,                       # ITD, 1-7 scale
  y_mc      = anv$y_i_mc,                    # centred on the focal variable's mean
  manip_ok  = anv$man_check_i,
  comp      = as.integer(anv$n > 1),         # comparison: shown after other apps
  inv_app   = anv$inv_app_mc,
  inv_dl    = anv$inv_dl_mc,
  inv_cat   = anv$inv_cat_mc
)
long <- long[order(long$subject, long$pos_num), ]

# levels of x for the other two focal variables seen by the same subject
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

cat("long_measures.csv:", nrow(long), "rows,", ncol(long), "columns\n")
cat("wide_subjects.csv:", nrow(wide), "rows,", ncol(wide), "columns\n")
cat("\nsubjects by number of manipulation-check boxes ticked:\n")
print(table(wide$manip_ok_all))
