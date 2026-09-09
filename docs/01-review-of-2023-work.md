# Review of the 2023 work

**Subject:** *Determinants of Download on Mobile App Stores — An Empirical Analysis*
(master's thesis, Chair of Marketing, Universität Tübingen / Università di Pavia,
14 February 2023)

**Status:** review completed against the unmodified original material, published at
[github.com/lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants).
The 11 datasets are also versioned here in [`original/data/`](../original/data/) because
the scripts read them directly. Every figure quoted below is reproducible with the
scripts in [`analysis/R/`](../analysis/R/); the full logs are in
[`analysis/outputs/logs/`](../analysis/outputs/logs/).

---

## 1. Executive summary

The work **replicates exactly and the data are internally consistent**. The nine
regressions of Table 3.2 reproduce digit for digit, and the datasets show no internal
inconsistencies, no missing values and no discrepancies against the published descriptive
statistics.

The problems are not in the data. They are in how inference was drawn from it. Three
defects are substantive and change the conclusions.

| # | Problem | Effect on the conclusions |
|---|---|---|
| **A** | The repeated-measures ANOVA does not model repeated measures (`Error(lfdn)` with `lfdn` an integer) | The three-way interaction reported as significant **disappears** under the correct specification (F = 0.64, p = 0.63) |
| **B** | The brand > reputation > popularity ranking is inferred by eyeballing coefficients estimated on different subsamples, with no test of the difference | Under a formal test **brand and reputation are indistinguishable** (p = 0.22). The defensible hierarchy is brand ≈ reputation ≫ popularity |
| **C** | The "manipulation check" is reported but never used — and it is not a perception check, it is a post-treatment self-report | The thesis's most-quoted result, "popularity is surprisingly ineffective", **is fragile**: among respondents who say they looked at downloads the effect goes from +0.22 (p = 0.075) to +0.51 (p = 0.002). This does not overturn it (§3.3), but it removes the null's solidity |

Three further problems concern the calibration of the evidence rather than its direction:

- **81 coefficients estimated, no multiplicity correction.** Of the 23 significant at
  p < 0.10, **2** survive Holm and **4** survive FDR < 0.05 — in both cases essentially
  the brand main effect alone.
- **Two of the three involvement moderations do not replicate** in a pooled model.
- **The claim "no two-way interaction between focal variables" is inconclusive, not
  null:** the design could only detect interactions ≥ 0.75–0.98 standard deviations.

Two further defects concern the construction of the stimuli and of the data, and surfaced
by reading the appendices rather than the models:

- **The low-popularity stimulus is internally impossible** (10K+ downloads alongside 84K
  reviews). This is a confound in the very manipulation that produces the thesis's most
  discussed result (§3.3).
- **18 of 491 respondents have mean-imputed involvement scores**, documented nowhere
  (§2.4).

The picture that emerges does not demolish the work. It shifts its centre of gravity: the
sturdier story is not "brand wins" but **"brand and reputation are equivalent as long as
the user looks at a single app; comparison makes them converge; popularity counts for
little, and how little cannot be determined with these stimuli"**.

---

## 2. What was verified and held up

### 2.1 Exact replication of Table 3.2

[`01_replication.R`](../analysis/R/01_replication.R) reproduces the nine regressions using
the original specification. Agreement to four decimal places on every coefficient,
standard error, R², adjusted R², sample size and manipulation-check rate. No discrepancies.

Replicated focal coefficients:

| Model | β | p |
|---|---|---|
| M1 (rep) | 0.4986 | 0.0596 |
| M1 (pop) | 0.3611 | 0.0944 |
| M1 (brand) | 1.5289 | < 0.001 |
| M2 (rep) | 1.3351 | 0.0014 |
| M2 (pop) | 0.5340 | 0.2560 |
| M2 (brand) | 1.0347 | 0.0180 |
| M3 (rep) | 0.4576 | 0.0895 |
| M3 (pop) | 0.3677 | 0.0929 |
| M3 (brand) | 1.5028 | < 0.001 |

### 2.2 Data integrity

[`02_data_audit.R`](../analysis/R/02_data_audit.R) verifies:

- **Design structure.** 491 respondents × 3 measures = 1,473 observations. Each subject
  sees each focal variable exactly once and each position exactly once: a Latin square,
  correctly randomised (no duplicates).
- **Cross-file consistency.** Merging on `lfdn` between the model files and the ANOVA file
  yields 0 mismatches on `y`, 0 on `x` and 0 on `comp` for all three focal variables.
- **Subsamples.** The M1 (n = 1) and M2 (n = 3) sample sizes match exactly those expected
  from the repeated-measures file: 149/189/153 and 196/143/152, each summing to 491.
- **Centring.** `y_i_mc` is `y_i` centred on the mean **within focal variable** (maximum
  error 0.000000); the three involvement measures are centred on the overall mean.
- **Missing values.** Zero, across all eleven files.
- **Descriptive statistics.** Means and standard deviations in Table 3.1 match the data.

### 2.3 Two minor discrepancies in Table 3.1

Neither changes any conclusion, but both should be fixed in any republication:

- The standard deviations are **population** SDs (divided by *N*), not sample SDs
  (*N* − 1). For instance `y_rep` is reported as 1.7077 against a sample value of 1.7095.
  Difference ~0.001.
- The `comp_i` row reports **design** values (mean 2/3 = 0.6667; s.d. 0.4714) rather than
  realised ones. In the sample the mean varies by focal variable: 0.6965 for reputation,
  0.6883 for brand, 0.6151 for popularity.

### 2.4 Undocumented mean imputation

The involvement scales have 3 items (`inv_app`, `inv_dl`) and 8 items (`inv_cat`) on a 1–7
range, so the scale means must be multiples of 1/3 and 1/8. Each scale instead contains
**one value that is not attainable on the scale and that equals the scale mean exactly** —
the signature of mean imputation:

| Scale | Items | Imputed cases | Published s.d. | s.d. excluding imputed |
|---|---|---|---|---|
| `inv_app` | 3 | 5 (1.0%) | 1.0533 | 1.0587 |
| `inv_dl` | 3 | 3 (0.6%) | 1.2987 | 1.3027 |
| `inv_cat` | 8 | 11 (2.2%) | 1.0640 | 1.0762 |

In total 18 of 491 respondents (3.7%) have at least one imputed scale, one has two. The
numerical impact is negligible — Table 3.1's standard deviations are understated by ~0.01 —
but the choice is declared neither in the thesis nor in the code, and on a moderator it
introduces attenuation towards zero precisely in the imputed cases.

### 2.5 Redundancies and leftovers in the files

Two observations that do not affect the results but explain the file contents:

- **`M plots.csv` is redundant.** It holds the same 1,473 rows as `M ANOVA_RM.csv` on the
  same columns, minus `n_name` and `x_i_name`. Verified with `all.equal`: no additional
  data.
- **The M2 files contain four columns no model uses.** `ITD_pop` and `ITD_brand` are
  top-3-box dichotomisations (`y ≥ 5`) of the ITD measured at position 1 or 2;
  `ITD_pop_2` and `ITD_brand_2` are those same ITDs mean-centred. They are leftovers from
  abandoned exploration.

---

## 3. The defects that change the conclusions

### 3.1 (A) The repeated-measures ANOVA does not model repeated measures

The original script contains:

```r
ANOVA.aov <- aov(y_i ~ i_name*x_i_name*n_name + Error(lfdn), data = data1)
```

`lfdn` is read as an **integer**. `aov()` therefore treats it as a continuous covariate
rather than a grouping factor: the `Error: lfdn` stratum collapses to 1 degree of freedom
with no residuals, and every test lands in the `Within` stratum on 1,454 residual df —
that is, an ANOVA over independent observations. The repeated-measures structure, which is
the heart of the design, never enters the model.

That the data are strongly clustered by respondent is shown by the mixed-effects model:
**ICC = 0.41**. Forty-one percent of the variance in ITD is between-person variance.
Ignoring it is not a detail.

With `subject` as a factor, the tests change:

| Term | Thesis (original specification) | Correct specification (*Within* stratum) |
|---|---|---|
| focal variable *i* | F = 42.19 *** | F = 73.96 *** |
| manipulation *x* | F = 60.84 *** | F = 98.99 *** |
| position *n* | F = 2.37 (p = 0.094) | F = 4.03 (p = 0.018) |
| *i* × *x* | F = 10.28 *** | F = 9.90 *** |
| **i × x × n** | **F = 2.68 (p = 0.030)** | **F = 0.64 (p = 0.633)** |

The three-way interaction, which the thesis text presents as *"further foundations for
subsequent analyses"*, **does not survive**. The mixed model confirms this
(χ² = 6.01, 4 df, p = 0.198).

**A related transcription error.** The text reports *F*(2, 4) = 42.187 and *F*(1, 4) =
60.841. The denominator degrees of freedom are not 4 but 1,454 (the "4" appears to have
been taken from the *Df* column of another row of the `aov` table). The *F* values and
p-values are correct; the published df are not.

### 3.2 (B) The ranking is never tested

The central claim — *"developer's brand is generally the most decisive element"* — comes
from comparing β = 1.5289 (M1 brand), β = 0.4986 (M1 rep) and β = 0.3611 (M1 pop). But
these three coefficients come from **three regressions on three disjoint subsamples** (153,
149 and 189 different respondents). Comparing them is not a test: nowhere in the thesis is
there a statistic that answers "does brand really beat reputation?".

The pooled model on all 1,473 observations, with a random intercept by respondent, answers
it. The `focal × manipulation` interaction is needed (LRT: χ² = 25.02, 2 df, p < 0.001), so
the effects *do* differ. But the pairwise contrasts (Holm-corrected) show **where** the
difference lies:

| Contrast | Δβ | 95% CI | p (Holm) |
|---|---|---|---|
| reputation − brand | −0.210 | [−0.623, 0.202] | **0.222** |
| popularity − brand | −0.835 | [−1.252, −0.418] | < 0.001 |
| popularity − reputation | −0.624 | [−1.035, −0.214] | 0.0006 |

The effects estimated on the whole sample:

| Variable | β | 95% CI | Cohen's *d* |
|---|---|---|---|
| Brand | +1.053 | [0.813, 1.293] | 0.66 |
| Reputation | +0.842 | [0.602, 1.083] | 0.49 |
| Popularity | +0.218 | [−0.022, 0.458] | 0.14 |

**Brand and reputation are not statistically distinguishable.** The thesis's three-step
hierarchy is really a two-step one: {brand, reputation} ≫ popularity.

That the brand's apparent advantage was largely an artefact of fragmenting the sample is
visible in the contrast between M1's reputation estimate (0.4986, p < 0.10, on 149
observations) and the pooled estimate (0.842, p < 0.001, on 491 reputation measures). The
reputation coefficient **doubles** once it is estimated using all the available information
rather than a third of it.

### 3.3 (C) The manipulation check is never used — and it is not a manipulation check

**What it actually measures.** Slide 6 of the questionnaire (Appendix B) is **a single
multiple-choice question**, asked once at the end, about the three apps collectively:

> *"Please indicate which factors you took into consideration when evaluating the apps on
> the previous slides."*

followed by nine tick boxes: *Review rating, Number of downloads, Developer brand, App's
name, App's icon, Number of reviews, App's screenshots, PEGI rate, "About this app"*.
`man_check_i` equals 1 if the matching box is ticked.

It is therefore not a check that the manipulation was perceived: it is a **self-report of
which cues the respondent says they used**, collected after treatment. The thesis itself
calls it *"a compromise (and not ideal) version"*. Three consequences, all verifiable in
the data ([`02_data_audit.R`](../analysis/R/02_data_audit.R) §12):

1. **It is a compositional measure.** Ticking one box comes at the expense of others. The
   correlations between the three outcomes within subject confirm it: rep–pop = +0.305, but
   brand–rep = −0.067 and brand–pop = −0.091. An attention measure would show uniformly
   positive correlations.
2. **It cannot vary by position**, being a single global question. The rates are indeed
   flat (68.4% / 69.2% / 67.4% for *n* = 1, 2, 3). That flatness is structural and says
   nothing about memory decay.
3. **The coding of `man_check_brand` is ambiguous.** The brand manipulation changed three
   elements at once — icon, app name, developer name (Appendix A) — but slide 6 has three
   separate boxes. If `man_check_brand` derives from the *Developer brand* box alone, 67.4%
   is an undercount; if it derives from any of the three, it is not comparable with `rep`
   and `pop`, which depend on a single box. **Not resolvable without the raw questionnaire
   export.**

**The rates reported and never used.** They remain a piece of information the thesis
produces and ignores:

| Model | Rate | 95% CI | p vs 50% |
|---|---|---|---|
| M1 rep | 75.8% | [68.2, 82.5] | < 0.001 |
| M2 rep | 79.1% | [72.7, 84.6] | < 0.001 |
| M3 rep | 77.2% | [73.2, 80.8] | < 0.001 |
| M1 brand | 68.6% | [60.6, 75.9] | < 0.001 |
| M2 brand | 63.2% | [55.0, 70.8] | 0.0015 |
| M3 brand | 67.4% | [63.1, 71.5] | < 0.001 |
| M1 pop | 62.4% | [55.1, 69.4] | 0.0008 |
| **M2 pop** | **55.9%** | **[47.4, 64.2]** | **0.181** |
| M3 pop | 60.5% | [56.0, 64.8] | < 0.001 |

Only 297 of 491 observations have the *Number of downloads* box ticked, against 379 of 491
for *Review rating*. Only 163 of 491 respondents ticked all three relevant boxes.

Restricting the estimate to those who say they used the corresponding cue:

| Sample | Brand | Reputation | Popularity |
|---|---|---|---|
| All observations (N = 1,473) | 1.053 *** | 0.842 *** | 0.218 (p = 0.075) |
| Says they used the cue (N = 1,007) | 1.381 *** | 1.098 *** | **0.507 (p = 0.002)** |
| Subjects ticking all three (N = 489) | 1.344 *** | 1.242 *** | **0.517 (p = 0.013)** |

The popularity effect more than doubles and becomes clearly significant.

> **How to read this — and how not to.** This is not the removal of measurement error, and
> it does not overturn the thesis's result. `man_check_i` is measured **after** treatment
> and is plausibly affected by it: someone moved by a cue is more likely to report having
> used it. Conditioning on it is post-treatment conditioning on a variable that behaves
> like a mediator, and the contrast between the two groups is partly tautological —
> *those who say they looked at downloads were moved by downloads*.
>
> What the data does show defensibly is that **the popularity null is not solid**: it
> depends on including respondents who say they did not look at that cue, and it vanishes
> among those who say they did. That is a reason not to conclude "popularity does not
> matter", not proof that it does. The honest answer remains the range between 0.22 and
> 0.51, with the "zero" reading weakened but not excluded.

**A simpler alternative hypothesis.** The low-popularity stimulus (Fig. A.2) shows **10K+
downloads alongside 84K reviews**: more reviews than downloads, which is impossible. The
review count is held constant across the two conditions, so the defect affects only the low
level. An attentive respondent could perceive the stimulus as not credible and discount it —
and *Number of reviews* was one of the slide-6 boxes. This explanation requires no
post-treatment conditioning at all, and competes with the subgroup-based one. Neither is
testable with the available data.

(The reputation stimulus, Fig. A.1, likewise reports 343K reviews on 1M+ downloads:
implausible, but not impossible.)

---

## 4. Problems in the calibration of the evidence

### 4.1 Multiple testing

Nine regressions produce **81 coefficients** (intercepts excluded). No correction.

| | Count |
|---|---|
| p < 0.10 raw | 23 |
| p < 0.05 raw | 13 |
| Surviving Holm (p < 0.05) | **2** |
| Surviving Benjamini–Hochberg (FDR < 0.05) | **4** |

The two that survive Holm are the brand effect in M1 and in M3 — that is, the same effect
estimated twice. FDR adds the reputation effect in M2 and `inv_cat` in M3 (pop).

In fairness, the p < 0.10 threshold the thesis adopts is a legitimate and declared choice;
the problem is that the narrative claims do not distinguish robust results from marginal
ones. Several Chapter 3 conclusions rest on coefficients with p between 0.05 and 0.10 out
of 81 tests.

### 4.2 The involvement moderations largely do not replicate

Estimating the moderations in a single pooled model rather than nine separate regressions:

| Thesis claim | Source | In the pooled model | Outcome |
|---|---|---|---|
| Involvement in the download process strengthens reputation | M1 rep, β = 0.3861, p < 0.10 | β = −0.066, p = 0.48 | **Does not replicate** |
| Involvement in the category favours brand | M1 brand, β = 0.4001, p < 0.10 | β = 0.089, p = 0.37 | **Does not replicate** |
| Involvement in apps strengthens all three variables | M2, M3 | brand 0.119 (p = 0.27); rep 0.260 (p = 0.016); pop 0.324 (p = 0.003) | **Partial**: holds for reputation and popularity, not brand |

The only moderation effect that holds is general involvement in apps, and it holds
precisely for the two variables the thesis does not emphasise.

> **Caveat.** This section assumes the involvement scales were built correctly. `inv_app`
> contains one reverse-polarity item and `inv_cat` four pairs out of eight: if reverse
> coding was not applied, both would be attenuated and **all** moderation estimates biased
> towards zero, which would by itself explain why two of three fail to replicate. Not
> verifiable without item-level data (§10, *Limitations that remain open*).

The managerial implications in §3.3 built on these two moderations — *"when users are
highly involved in the download process they rely more on reputation"* and *"when
category involvement is high they choose established brands"* — should be withdrawn or
downgraded to hypotheses.

### 4.3 "No interaction between focal variables" is inconclusive

The thesis concludes it found no *"clear evidence of any two-way interaction between
reputation, popularity and brand"*. It is true that none of the six M2 interactions is
significant. But with samples of 143–196 observations and 11 predictors, the minimum
detectable effect (α = 0.05, 80% power) is:

| Model | Term | β | s.e. | MDE (points) | MDE (s.d.) |
|---|---|---|---|---|---|
| M2 rep | x_rep : x_brand | 0.166 | 0.467 | 1.31 | 0.77 |
| M2 rep | x_rep : x_pop | −0.371 | 0.461 | 1.29 | 0.76 |
| M2 pop | x_pop : x_brand | 0.392 | 0.546 | 1.53 | 0.98 |
| M2 pop | x_pop : x_rep | −0.744 | 0.539 | 1.51 | 0.96 |
| M2 brand | x_brand : x_rep | 0.251 | 0.507 | 1.42 | 0.90 |
| M2 brand | x_brand : x_pop | −0.677 | 0.511 | 1.43 | 0.90 |

The design could detect only interactions between 0.76 and 0.98 standard deviations —
enormous effects by the standards of the relevant literature, where interactions are
typically fractions of the main effect (here: 0.14–0.66 s.d.). The model was **blind** to
any plausible interaction. The correct wording is "inconclusive", not "absent".

---

## 5. The design defect that generates the others

The thesis states it honestly in §3.5: this is not a 2×2×2 factorial but a design in which
**one variable at a time is manipulated** while the others are held at intermediate values.
That choice is what makes the study of comparison effects possible, and in that sense it is
motivated.

But it is also the upstream cause of everything else:

- It forces the fragmentation into nine regressions on disjoint subsamples (§3.2).
- It makes interactions between focal variables structurally underpowered (§4.3).
- It pushes towards reading coefficients by visual comparison rather than by test.

**The important point is that the design defect does not force the analysis defect.** The
data as collected *supports* a pooled mixed-effects analysis: it is a balanced Latin square
with 491 subjects and 1,473 observations. The fragmentation was an analytic choice, not a
requirement of the design — and it is the choice that wasted most of the available
statistical power.

---

## 6. A result the thesis nearly found

The comparison effect deserves rewriting, not correcting. The thesis describes it as a
**reversal**: *"there was a reversal between the developer's brand and reputation, which
became the most important element of the three"*. Estimating the same phenomenon on a
single model instead of M1 vs M2:

| Variable | Shown first | After other apps |
|---|---|---|
| Brand | **1.407** (p < 0.001) | 0.902 (p < 0.001) |
| Reputation | 0.691 (p = 0.002) | 0.912 (p < 0.001) |
| Popularity | **0.462 (p = 0.019)** | 0.059 (p = 0.707) |

It is not a reversal: it is a **convergence**. Brand loses a third of its strength
(1.41 → 0.90), reputation gains a third (0.69 → 0.91), and they end up overlapping. Neither
overtakes the other in a statistically distinguishable way.

And there is a finding the thesis does not mention at all: **popularity works when the user
has no alternatives in front of them** (0.462, p = 0.019). It collapses to zero as soon as
comparison enters. This is more interesting than the blanket null the thesis reports, and it
has an immediate substantive reading: the download count is a fallback heuristic, used in
the absence of better information and abandoned the moment other information appears.

**Due caution:** the three-way `focal × manipulation × comparison` interaction has
p = 0.111. The pattern is coherent and in the expected direction, but it is not established.
It should be presented as a data-motivated hypothesis, to be tested in a dedicated
collection.

---

## 7. Robustness to specification

The dependent variable is a 1–7 Likert treated with OLS. Re-estimating with a mixed-effects
cumulative ordinal logit (`ordinal::clmm`, same specification), the conclusions do not
change:

| Variable | log-odds | Odds ratio |
|---|---|---|
| Brand | +1.712 | 5.54 |
| Reputation | +1.297 | 3.66 |
| Popularity | +0.374 | 1.45 |

Same hierarchy, same gap between {brand, reputation} and popularity, same
non-significance of the brand-vs-reputation contrast (p = 0.128). **Using OLS on a Likert
scale is not a problem in this dataset**: it is the only one of the checks performed that
confirms the original work without reservation.

---

## 8. Errors in the published code

In the original script
([`Data and Code/Determinants of Download on Mobile App Stores - An Empirical Analysis.r`](https://github.com/lucabnt/mobile-app-download-determinants/blob/main/Data%20and%20Code/Determinants%20of%20Download%20on%20Mobile%20App%20Stores%20-%20An%20Empirical%20Analysis.r)),
lines 64 and 73:

```r
M2_rep <- lm(y_rep_3 ~ ..., data=data1)
summary(M4_rep)          # <- object does not exist
...
M2_pop <- lm(y_pop_3 ~ ..., data=data1)
summary(M4_pop)          # <- object does not exist
```

Leftovers from an earlier model numbering. The script **aborts** with
`object 'M4_rep' not found`: anyone downloading it to replicate the results does not reach
the end. The models are estimated correctly — only the `summary()` call is wrong — so no
published result is affected.

Two additional minor issues:

- The CSVs carry a UTF-8 BOM. Without `fileEncoding = "UTF-8-BOM"` the first column is read
  as `ï..lfdn`; harmless here because `lfdn` never enters the models, but a trap for anyone
  extending the code.
- `library(caret)` is loaded and never used.

---

## 9. What stands

The document so far is a list of problems, and it is worth stating clearly what is **not**
in question:

1. **The research question is a good one**, and the experimental approach — direct user
   participation rather than scraping store rankings — is the work's strongest
   methodological contribution. The §3 argument for why store rankings do not reflect
   preferences is correct and well documented.
2. **The data collection is clean.** 491 complete respondents out of 545, correct
   randomisation, balanced Latin square, no missing values in the distributed files (with
   the undeclared imputation of §2.4 explaining part of that). This is the part of the work
   on which everything else can be rebuilt.
3. **The brand effect is real and large**, and it is the only result that survives any
   correction, including Holm across 81 tests. β ≈ 1.05–1.53 points out of 7, *d* ≈ 0.66.
4. **The choice of category** (scanner apps: low network effects, freemium, presence of a
   global brand such as Adobe) is well argued and does exactly the job it needs to do.
5. **Stimulus control is rigorous almost throughout.** Within each pair only what should
   vary does vary, and the other attributes are held at consistent intermediate levels
   (rating 4.2; downloads 1M+). The one exception is the Fig. A.2 defect (§3.3).
6. **The limitations are stated honestly** in §3.5, including the main design defect.

The review does not overturn the work. It **flattens** a hierarchy (brand vs reputation),
**withdraws** a three-way interaction and two moderations, **requalifies** two nulls as
indeterminacies (popularity; interactions between focal variables) and **flags** two defects
in the construction of the data. The rest holds.

---

## 10. Summary of corrections to carry over

For a possible erratum or republication:

| Location | Current text | Correction |
|---|---|---|
| §3.2, ANOVA | *F*(2, 4) = 42.187; *F*(1, 4) = 60.841; *F*(2, 4) = 2.369 | Denominator df = 1,454 |
| §3.2, ANOVA | Three-way interaction significant (*F*(4) = 2.681, p < 0.05) | Not significant under correct repeated measures (p = 0.63) |
| §3.2, Abstract | *"developer's brand is generally the most decisive element"* | Brand and reputation indistinguishable; both ≫ popularity |
| §3.2, Abstract | *"popularity [...] unexpectedly ineffective [...] across all models"* | Not a solid null: it vanishes among those who say they looked at downloads, and the low-popularity stimulus is internally impossible. Present as indeterminate, not as an absent effect |
| §3.2 | *"reversal between brand and reputation"* | Convergence, not reversal |
| §3.3 | Download-involvement moderation on reputation | Does not replicate |
| §3.3 | Category-involvement moderation on brand | Does not replicate |
| Abstract | *"not possible to find clear evidence of any two-way interaction"* | Inconclusive for lack of power (MDE ≥ 0.76 s.d.) |
| Tab. 3.1 | Population s.d.; `comp_i` with design values | Sample s.d.; realised values |
| §3.1, Tab. 3.1 | No mention of missing-data handling | Declare the mean imputation on 18 respondents |
| App. A, Fig. A.2 | Low-popularity stimulus: 10K+ downloads with 84K reviews | Construction defect, to be flagged among the limitations |
| `*.r` | `summary(M4_rep)`, `summary(M4_pop)` | `summary(M2_rep)`, `summary(M2_pop)` |

### Limitations that remain open

Two ambiguities cannot be resolved with the published material and require the raw
questionnaire export:

- **Coding of `man_check_brand`.** Which slide-6 box (or combination) does it derive from,
  given that the brand manipulation changed three elements but the boxes are separate?
  Until this is settled, the §3.3 subgroup cannot be used for comparisons *between* focal
  variables.
- **Reverse coding of the involvement scales.** `inv_app` contains one reverse-polarity item
  (*"For me, mobile apps do not matter"*) and `inv_cat` four pairs out of eight. If the
  reversal was not applied before averaging, both scales would be attenuated towards the
  centre and every moderation estimate biased towards zero — which would offer an
  alternative explanation for why two of three moderations fail to replicate (§4.2). Not
  verifiable without item-level data.

---

## 11. Reproducing this review

```bash
Rscript analysis/R/01_replication.R        # replication of Table 3.2
Rscript analysis/R/02_data_audit.R         # data integrity
Rscript analysis/R/03_build_derived.R      # long-format datasets
Rscript analysis/R/04_corrected_inference.R
Rscript analysis/R/05_robustness.R
Rscript analysis/R/06_figures.R
```

Environment used: R 4.2.2 with `lme4`, `emmeans`, `ordinal`, `clubSandwich`, `car`,
`ggplot2`. Full logs are versioned in
[`analysis/outputs/logs/`](../analysis/outputs/logs/), tables in
[`analysis/outputs/tables/`](../analysis/outputs/tables/).

The next step — which further analyses the data still supports — is in
[`02-work-plan.md`](02-work-plan.md).
