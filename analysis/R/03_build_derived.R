# 03_build_derived.R ---------------------------------------------------------
# Rebuilds two tidy datasets from the original files, which stay untouched:
#   data/derived/long_measures.csv  -> 1473 rows (subject x focal variable)
#   data/derived/wide_subjects.csv  ->  491 rows (one per respondent)
# The long format is what makes mixed-effects models and pooled analyses
# possible; the original per-model files do not allow them.
# ----------------------------------------------------------------------------

source("analysis/R/00_setup.R")

anv <- read_orig("M ANOVA_RM.csv")

# Involvement covariates: taken from the model files, NOT from the ANOVA file.
# For the 18 respondents with a mean-imputed scale the ANOVA file stores the
# centred score as -mean (the missing value treated as 0, then centred), which
# lies outside what a 1-7 scale can produce; the nine model files store 0, the
# mean imputation the thesis itself used. Found by an independent
# re-computation (not published); the check that should have caught it is now
# section 4b of 02_data_audit.R. Centred here from the raw scores, and asserted
# equal to the model files' own centred columns.
m3r <- read_orig("M3_rep.csv")
inv <- data.frame(lfdn    = m3r$lfdn,
                  inv_app = m3r$inv_app - mean(m3r$inv_app),
                  inv_dl  = m3r$inv_dl  - mean(m3r$inv_dl),
                  inv_cat = m3r$inv_cat - mean(m3r$inv_cat))
stopifnot(max(abs(inv$inv_app - m3r$inv_app_mc)) < 1e-6,
          max(abs(inv$inv_dl  - m3r$inv_dl_mc))  < 1e-6,
          max(abs(inv$inv_cat - m3r$inv_cat_mc)) < 1e-6)
inv_row <- match(anv$lfdn, inv$lfdn)
stopifnot(!anyNA(inv_row))

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
  inv_app   = inv$inv_app[inv_row],
  inv_dl    = inv$inv_dl[inv_row],
  inv_cat   = inv$inv_cat[inv_row]
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
