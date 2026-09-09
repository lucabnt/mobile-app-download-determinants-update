# Work plan and change log

Working document. The first part tracks **what has been done**, the second **what remains**
with priorities and acceptance criteria, the third is the **change log**.

The review of the original work is in
[`01-review-of-2023-work.md`](01-review-of-2023-work.md).

---

## 0. Working principles

1. **The 2023 material is referenced, not duplicated.** It lives in its own repository
   ([lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants)).
   Only `original/data/` is versioned here, because the scripts read it and without it a
   clone is not reproducible. Every correction lives in `analysis/` and is documented here,
   never applied retroactively to the original.
2. **Every number quoted in a document must be produced by a versioned script.** No values
   copied by hand. The logs in `analysis/outputs/logs/` are the proof.
3. **Corrections are declared, not hidden.** Where the review contradicts the thesis, the
   document reports both versions and the reason for the gap.
4. **Separate what the data proves from what it suggests.** A p = 0.11 is a hypothesis, not
   a result, and must be written as such even when the story would be better otherwise.

---

## 1. Phase 1 — Replication and validation **[complete]**

| # | Task | Script | Outcome |
|---|---|---|---|
| 1.1 | Repository structure, snapshot of the original | — | Done |
| 1.2 | Exact replication of the 9 regressions and the ANOVA | `01_replication.R` | Agreement to 4 decimals |
| 1.3 | Data integrity audit | `02_data_audit.R` | Consistent; imputations and redundancies found |
| 1.4 | Derived long- and wide-format datasets | `03_build_derived.R` | `data/derived/` |
| 1.5 | Correct repeated-measures ANOVA + mixed model | `04_corrected_inference.R` | Three-way interaction not confirmed |
| 1.6 | Formal test of the ranking between focal variables | `04_corrected_inference.R` | Brand ≈ reputation ≫ popularity |
| 1.7 | Robustness to the slide-6 check | `05_robustness.R` | Popularity null is fragile (revised, see §6) |
| 1.8 | Ordinal logit model | `05_robustness.R` | Conclusions unchanged |
| 1.9 | Multiplicity correction | `05_robustness.R` | 2/81 survive Holm |
| 1.10 | Power analysis on the null interactions | `05_robustness.R` | MDE ≥ 0.76 s.d. |
| 1.11 | Figures based on the corrected estimates | `06_figures.R` | 3 figures |
| 1.12 | Review document | — | `docs/01-review-of-2023-work.md` |

**Phase outcome:** the data is consistent, the inference is not. Five thesis conclusions
change or need requalifying, and two defects concern the construction of the stimuli and
of the data. The rest holds. Detail in `01-review-of-2023-work.md` §1.

---

## 2. Phase 2 — New analyses on the existing data

Ordered by value/cost ratio. All feasible with the data already in
`data/derived/long_measures.csv`, with no new collection.

### 2.1 Sequence and anchoring effects **[high priority]**

**Question.** Does ITD for the app in position *k* depend on **which values** the user saw
in earlier positions, not merely on the fact that they saw some?

**Why it matters.** This is the question the thesis meant to ask with Model 2, but M2
addresses it on 143–196 observations from the third position alone. In long format, with
lagged predictors and a random intercept by subject, the same question uses all 982
observations with *n* > 1 — five times the statistical power.

**Method.** `y ~ x * (mean of levels seen earlier) + x * (immediately preceding level) +
focal + position + (1 | subject)`. Distinguish a **contrast** effect (a strong app seen
earlier lowers the rating of the next) from an **assimilation** effect (it raises it).

**Data.** Already present: `x_other_brand`, `x_other_rep`, `x_other_pop`, `pos_num` in
`long_measures.csv`.

**Acceptance criterion.** Estimate of the contrast coefficient with 95% CI, and a check
that the sign is stable between the linear and ordinal specifications.

**Risk.** Order is randomised and the earlier levels are randomised too, so identification
is clean. Low risk.

---

### 2.2 Between-respondent heterogeneity: random slopes **[high priority]**

**Question.** Do all users react to the same cues, or are there distinct profiles — some
who look at brand, some at ratings, some at nothing?

**Why it matters.** The ICC of 0.41 says people differ a lot in their *level* of ITD. It
says nothing about how much they differ in their *sensitivity* to cues, which is the
question with practical implications: if half the sample ignores ratings, the average
understates the effect for the other half.

**Method.** `(1 + x | subject)` and `(1 + focal | subject)`; LRT against the
random-intercept-only model. If the slope variance is significant, extract the BLUPs and
describe the distribution of individual sensitivities.

**Known limitation.** Three observations per subject is few for reliable random slopes. The
model may fail to converge or return boundary variance. **If that happens it must be
reported as such** — not forced by trying progressively simpler specifications until one
"works".

**Acceptance criterion.** LRT plus convergence diagnostics. A negative outcome (no estimable
heterogeneity) is a publishable result.

---

### 2.3 Equivalence testing on the null results **[high priority]**

**Question.** Is the popularity effect after comparison (β = 0.059) *zero*, or merely *not
distinguishable from zero*?

**Why it matters.** It is the correct way to support a null claim, and the thesis makes
three (popularity ineffective; no interaction between focal variables; no moderation in
several places). A TOST with a declared practical-relevance threshold turns "we found
nothing" into "we ruled out effects larger than X".

**Method.** Two One-Sided Tests with the SESOI (smallest effect size of interest) fixed *a
priori* — proposal: 0.20 s.d., roughly 0.3 points on the 1–7 scale, the threshold below
which an effect on download intention has no managerial relevance. Apply to: the
post-comparison popularity effect, the six M2 interactions, the two moderations that fail
to replicate.

**Acceptance criterion.** For each null, one of three labels: *equivalent to zero*,
*inconclusive*, *effect present*. No "not significant" without qualification.

**Note.** From Phase 1 we already know the six M2 interactions will almost certainly land
in *inconclusive* (MDE ≥ 0.76 s.d. against a SESOI of 0.20). That is the point: making it
explicit and quantified.

---

### 2.4 Slide 6 as an outcome, not a filter **[high priority — reformulated]**

**Context.** The original reading of this task assumed `man_check_i` was a check that the
manipulation had been perceived. It is not: slide 6 is a single multiple-choice question,
asked at the end of the questionnaire, about which cues the respondent **says** they used
(§3.3 of the review). It is therefore post-treatment and plausibly affected by the
treatment itself.

**Reformulated question.** Two distinct questions, not one:

1. *Does the manipulation influence what the respondent says they looked at?* That is:
   `man_check_i` is itself an outcome. Model: `manip_ok ~ focal * x + (1 | subject)`,
   logistic. If the high level of a cue raises the probability of reporting it, the
   conditioning in §3.3 is confirmed as problematic and must be downgraded further.
2. *Is the pattern compatible with a simple attention effect?* Model:
   `y ~ focal * x * manip_ok + ... + (1 | subject)`, presented as **descriptive**, not
   causal.

**Why it matters.** It determines how much weight §3.3 can carry. If the answer to (1) is
yes, that section must be rewritten again, reducing the subgroup to a mere illustration.

**Acceptance criterion.** No estimate from this task is to be presented as a causal effect.
The output is a qualification of the popularity null, not a replacement for it.

**Blocking dependency.** Point (1) is interpretable only once the coding of
`man_check_brand` is clarified (Phase 3.6).

---

### 2.5 Specification-curve analysis **[medium priority]**

**Question.** How much does the "brand > reputation" conclusion depend on analytic choices?

**Why it matters.** It is the empirical answer to the thesis's structural defect. Instead of
arguing that the pooled specification is the right one, show **all** reasonable
specifications and see where the brand-vs-reputation contrast falls.

**Method.** Grid over the choices: sample (all / n=1 / n=3 / box ticked / subjects ticking
3 of 3) × model (OLS / cluster-robust OLS / mixed / mixed ordinal) × controls (with and
without involvement, with and without position). ~120 specifications. Curve ordered by
estimate, with the thesis's own specification highlighted.

**Acceptance criterion.** Share of specifications in which the brand-vs-reputation contrast
is significant at 5%. If it is low — as expected — the thesis conclusion is an analytic
choice, not a fact.

**Note.** This is also the best graphical material for the blog post.

---

### 2.6 Bayesian reformulation **[medium priority]**

**Question.** What is the probability that brand matters more than reputation?

**Why it matters.** It is the question a non-statistical reader actually asks, and the
frequentist framework does not answer it: "p = 0.22" is not "a 22% probability that they
are equal". With a posterior one writes *P*(β_brand > β_rep) = *x*% directly.

**Method.** Preferably `brms`/Stan with weakly informative priors. **Technical constraint:**
`brms` is not installed and requires a Stan toolchain; `lmerTest` will not compile on R
4.2.2 in this environment. Acceptable fallback: simulation from the approximate posterior of
the mixed model's fixed effects (multivariate normal on `vcov`), sufficient for a contrast
probability but **to be labelled an approximation**, not a full Bayesian estimate.

**Acceptance criterion.** If the fallback is used, the document must say so explicitly.
Upgrading the R environment first is preferable.

---

### 2.7 Structure of the response scale **[low priority]**

**Question.** Do respondents use the 1–7 scale uniformly, or do they cluster on focal values
(4 = neutral, extremes avoided)?

**Why it matters.** The ordinal thresholds estimated in Phase 1 are not equally spaced: the
gap 4|5 → 5|6 is much smaller than 1|2 → 2|3. If the scale is compressed in the middle, OLS
systematically distorts small effects — precisely the ones on popularity.

**Method.** Compare the estimated thresholds against equal spacing; model with a
*response style* component (individual tendency to use the extremes) as a random effect.

**Acceptance criterion.** Quantify how much the popularity effect changes between treating
the scale as interval and as ordinal. From Phase 1 the difference looks small; it needs
confirming.

---

## 3. Phase 3 — Blocked by the missing raw questionnaire export

This is no longer just a list of desirable extensions: **two entries are ambiguities that
undermine conclusions already written**, not optional extras.

| # | What | Missing data | Priority |
|---|---|---|---|
| **3.6** | **Coding of `man_check_brand`** — which slide-6 box does it derive from, given that the brand manipulation changed three elements (icon, app name, developer name) but the boxes are separate? | Item-level slide-6 responses | **Blocking** — without it the §3.3 subgroup is not comparable across focal variables |
| **3.7** | **Reverse coding of the involvement scales** — `inv_app` has one reverse-polarity item, `inv_cat` four pairs out of eight. Applied before averaging? | Scale items | **Blocking** — if not applied, all moderations are biased towards zero and §4.2 must be rewritten |
| 3.1 | Heterogeneity by age, gender, occupation, education | The demographics are described in §3.1.2 of the thesis but **appear in none of the 11 published CSVs** | High |
| 3.2 | Reliability and validity of the involvement scales (Cronbach's α, CFA) | Only the mean scores are shared, not the items | High |
| 3.3 | Response quality (straight-lining, completion times) | Timestamps and per-item response patterns | Medium |
| 3.4 | Analysis of the 54 respondents who dropped out | Incomplete records (545 started − 491 completed) | Medium |
| 3.5 | Updating the market context (Appendix C) | A fresh survey of the scanner-app segment on the Play Store | Low for the review, **high for the blog post** |
| 3.8 | Reconstructing the 18 mean-imputed scores (§2.4 of the review) | Scale items | Low — negligible numerical impact |

**Immediate action, now blocking.** Recover the raw questionnaire export (probably SoSci
Survey, given the `lfdn` field). It unlocks 3.1–3.4 and 3.6–3.8 in one go, and without 3.6
and 3.7 two sections of the review remain conditional.

**If the export cannot be recovered:** 3.6 and 3.7 become permanent declared limitations,
§3.3 must be downgraded further to an illustration, and §4.2 must carry the explicit
reservation that the moderations may be attenuated by a scale-construction error rather
than genuinely absent.

---

## 4. Phase 4 — Blog post for lucabontempi.com

**Destination.** An update to the existing post at
[`lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/`](https://lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/),
or a new post linking to it.

**Angle.** Not "here is my thesis", but **"I reopened my three-year-old thesis and found
three of my own mistakes"**. It is the most defensible framing and the most readable:
credibility comes from self-correction, not from defending the result.

**Proposed structure.**

1. Context: what the thesis asked, and why the question is still open in 2026.
2. The result that flattens: brand and reputation are indistinguishable, and the three-step
   hierarchy had never been tested. Figure 1. **This is the strong piece, not popularity:**
   it is clean, robust and entirely demonstrable.
3. The result that dissolves: popularity. Not "it was ineffective and turns out to be
   effective", but "it cannot be determined" — the low-popularity stimulus showed 10K+
   downloads with 84K reviews, and the null vanishes among those who say they looked at that
   cue. Figure 2. To be told as a limitation found, not as a discovery.
4. The result that improves: the brand/reputation convergence under comparison. Figure 3.
5. What I learned about analysis: nine regressions on disjoint subsamples waste statistical
   power; 81 uncorrected tests produce noise; a self-report question is not a manipulation
   check; and the worst defect was found by looking at the stimulus images, not the models.
6. What still holds.

**Risk to avoid.** An earlier version of this plan led with the overturning of the
popularity result. That reading did not survive scrutiny of slide 6 (§3.3 of the review).
The post must not rebuild it: that would be exactly the over-claiming the post sets out to
criticise.

**Requirements.**

- Language: English, matching the thesis and the original post. An Italian version is
  optional.
- Every number must point to a script in the repository. The repository is the source, the
  post is the summary.
- Declare explicitly that the 2026 analysis was carried out with AI assistance, if that is
  the site's standard.

**Precondition.** Close at least 2.1, 2.3 and 2.5 of Phase 2: without the specification
curve, point 2 of the structure is an assertion; with it, it is a demonstration.

---

## 5. Environment and dependencies

R 4.2.2 (`C:\Program Files\R\R-4.2.2`).

| Package | Status | Use |
|---|---|---|
| `tidyverse`, `caret` | present | required by the original script |
| `lme4` | present | mixed-effects models |
| `emmeans` | installed in this session | contrasts and marginal means |
| `ordinal` | present | mixed ordinal logit (`clmm`) |
| `clubSandwich`, `sandwich`, `lmtest` | installed in this session | cluster-robust standard errors |
| `car` | present | Type II/III ANOVA on mixed models |
| `lmerTest` | **not installable** | fails to compile from source on R 4.2.2 |
| `brms` | absent | needed for 2.6; requires a Stan toolchain |

**Technical debt.** Upgrading R to ≥ 4.3 would unlock `lmerTest` (Satterthwaite df on mixed
models) and make `brms` practical. In the meantime the mixed-model df come from `emmeans`
with the Kenward-Roger method and are cross-checked against CR2 cluster-robust SEs, which is
sufficient for the current conclusions.

---

## 6. Change log

### 2026-09-09 — Whole repository translated to English

The thesis, the original repository and the target blog post are all in English; the review
material now matches. Translated: the six R scripts (comments and console output), all
documents, and the figure labels. Renamed for consistency:

| Before | After |
|---|---|
| `docs/01-revisione-lavoro-2023.md` | `docs/01-review-of-2023-work.md` |
| `docs/02-piano-di-lavoro.md` | `docs/02-work-plan.md` |
| `fig_01_effetti_focali.png` | `fig_01_focal_effects.png` |
| `fig_02_manipulation_check.png` | `fig_02_slide6_subgroup.png` |
| `fig_03_confronto.png` | `fig_03_comparison.png` |

No analysis, estimate or dataset was changed: the whole pipeline was re-run after
translation and reproduces identical numbers. The figure file names also drop the
"manipulation check" wording, which the 2026-09-09 review had already established as a
misnomer.

### 2026-09-09 — Reading the appendices: §3.3 downgraded

Examination of Appendix A (stimuli) and Appendix B (questionnaire), which Phase 1 had not
read. Three findings, the first of which corrects a conclusion of the review.

**Corrected**

- **§3.3 of the review was overstated.** Slide 6 is not a manipulation check: it is a single
  multiple-choice question, asked at the end of the questionnaire, about which cues the
  respondent *says* they used. Conditioning on it is post-treatment conditioning on a
  mediator-like variable, not removal of measurement error. The conclusion "the popularity
  result is overturned" was downgraded to "the popularity null is not solid". Rewrote §1
  (row C), §3.3 and §10; retitled and re-described Figure 2.
- Reformulated task 2.4 of the plan, which assumed the wrong reading.
- Rewrote the blog post structure (§4), which opened on the overturning.

**Added**

- §3.3 of the review: **a stimulus construction defect**. The low-popularity condition
  (Fig. A.2) shows 10K+ downloads with 84K reviews — more reviews than downloads. It is a
  simpler, independent alternative explanation for the null.
- §2.4 of the review: **undocumented mean imputation** on 18 respondents (3.7%), detected
  because the scores are not multiples of 1/3 and 1/8 as they should be.
- §2.5 of the review: `M plots.csv` is redundant given `M ANOVA_RM.csv`; four columns of the
  M2 files (`ITD_pop`, `ITD_brand`, `ITD_pop_2`, `ITD_brand_2`) are unused leftovers.
- §4.2 of the review: caveat on reverse coding.
- `02_data_audit.R` extended with sections 9–12, making all of the above reproducible rather
  than asserted.
- Phase 3 reorganised: entries 3.6 (coding of `man_check_brand`) and 3.7 (reverse coding) are
  **blocking**, not optional extensions. The raw questionnaire export moves from desirable to
  necessary.

### 2026-09-09 — Original material referenced instead of duplicated

**Changed**

- `original/` no longer holds a full copy of the 2023 thesis. Removed from version control:
  `original/pdf/` (8.1 MB), `original/figures/` (20 MB, 18.8 of them in four near-identical
  PNGs), `original/tex/`, `original/code/` and `original/README.original.md` — all
  referenceable at
  [lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants).
  The files remain on the local disk, they are simply untracked (`.gitignore`).
- `original/data/` stays versioned: 428 KB read by every script in the pipeline. Without it a
  clean clone is not reproducible.
- Added `original/README.md` with the path mapping between the two repositories.
- Updated the references in `README.md` and the review document: links to files no longer
  versioned now point upstream.

**Removal method.** `git rm --cached` plus a new commit, a deliberately non-destructive
choice: history was not rewritten and `main` was not force-pushed. **Consequence to keep in
mind:** commit `ae798f9` had already been published on GitHub, so the ~28 MB remain reachable
in history and `git clone` still downloads them. Making them unreachable would require a
history rewrite with a force-push on an already-published branch — deliberately not done.

### 2026-09-09 — Repository setup and Phase 1

**Added**

- Repository structure: `original/`, `analysis/`, `data/derived/`, `docs/`.
- `analysis/R/00_setup.R` — paths, BOM-aware CSV reading, helpers.
- `analysis/R/01_replication.R` — replication of the 9 original regressions and the ANOVA.
- `analysis/R/02_data_audit.R` — integrity checks and comparison against Table 3.1.
- `analysis/R/03_build_derived.R` — builds `long_measures.csv` (1,473 × 19) and
  `wide_subjects.csv` (491 × 17).
- `analysis/R/04_corrected_inference.R` — correct repeated-measures ANOVA, mixed model,
  formal test of the ranking.
- `analysis/R/05_robustness.R` — manipulation check, ordinal logit, multiplicity, power,
  pooled moderations.
- `analysis/R/06_figures.R` — three figures based on the corrected estimates.
- The review document and this work plan.

**Corrected relative to the original** (in `analysis/`, not in the original)

- `summary(M4_rep)` / `summary(M4_pop)` → `summary(M2_rep)` / `summary(M2_pop)`. In the
  original script these reference non-existent objects and abort execution.
- CSVs read with `fileEncoding = "UTF-8-BOM"` (the files carry a BOM that renames the first
  column to `ï..lfdn`).
- `Error(lfdn)` with `lfdn` an integer → `Error(factor(lfdn))` and mixed-effects models.

**Thesis conclusions changed**

| Original conclusion | Status after the review |
|---|---|
| Three-way *i* × *x* × *n* interaction significant | **Withdrawn** — p = 0.63 under correct repeated measures |
| Brand is the most effective predictor | **Downgraded** — indistinguishable from reputation (p = 0.22) |
| Popularity is ineffective in all models | **Requalified** — not a solid null, but not overturned either: see the appendices entry above |
| Under comparison, reputation overtakes brand | **Reformulated** — they converge, they do not swap |
| Download involvement strengthens reputation | **Withdrawn** — does not replicate (p = 0.48) |
| Category involvement favours brand | **Withdrawn** — does not replicate (p = 0.37) |
| No interaction between focal variables | **Requalified** — inconclusive, not null (MDE ≥ 0.76 s.d.) |

**Unchanged**

- No content of the 2023 work: the CSVs in `original/data/` are bit-identical to the original
  package, and no other original file was altered.
