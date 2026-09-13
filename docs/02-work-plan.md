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

## Next step — Step 2A: stress-test the claims the post will make

**Status:** completed 2026-09-12. The choices below were fixed **before** anything was run and
were not revised afterwards. Verdicts: §12 of the review. Claim 1 **kept** (brand ahead in 4 of
23 specifications, below the 25% bar), claim 2 **confirmed and made precise** (popularity is an
effect before comparison, at the boundary after it), claim 3 **stays a hypothesis** (6 of 12
significant, below the 9 of 12 bar).

### Why this step, and why now

The post (§4) will make three claims, and each currently rests on a single specification.
Step 2A puts each through a test designed in advance, and does nothing else: it produces no
new findings, only a verdict on findings already written. It is fully unblocked — none of it
depends on the raw questionnaire export.

| Claim in the post | Current evidence | Stress test | Plan task |
|---|---|---|---|
| **1.** Brand and reputation are indistinguishable | One pooled mixed model, p = 0.22 | Specification curve on the brand − reputation contrast | 2.5 |
| **2.** The popularity effect is indeterminate, not zero | Fragile subgroup result + stimulus defect | Equivalence test (TOST) on the popularity effect, overall and after comparison; does the manipulation change what respondents report on slide 6? | 2.3, 2.4 (point 1) |
| **3.** Brand and reputation converge under comparison | Three-way interaction, p = 0.11 | Same specification curve, with the three-way contrast as a second estimand | 2.5 |

### Pre-registered choices

**Specification grid (claims 1 and 3).** Only defensible specifications enter the main curve:

| Sample | Structure | Models | Controls | Specs |
|---|---|---|---|---|
| All observations (1,473) | clustered, 3 per subject | OLS with CR2 cluster-robust SEs; linear mixed; ordinal mixed | involvement on/off × position on/off | 12 |
| Position 1 only (491) | independent, 1 per subject | OLS; ordinal | involvement on/off | 4 |
| Position 2 only (491) | independent | OLS; ordinal | involvement on/off | 4 |
| Position 3 only (491) | independent | OLS; ordinal | involvement on/off | 4 |

24 specifications in the main curve. Design notes:

- The "position 1 only" cells are the thesis's own Model 1 comparison — brand vs reputation
  among respondents who saw each first — run as **one** regression with a formal contrast
  instead of three separate ones. They are highlighted in the curve.
- Naive OLS on the full sample is excluded: its standard errors ignore the ICC of 0.41 and
  are not defensible. In the single-position samples each subject contributes one row, so
  OLS is correct there and a mixed model would be degenerate.
- **Slide-6-filtered samples are excluded from the main curve**, because filtering on a
  post-treatment self-report is not a defensible specification (§3.3 of the review). They
  appear in a separate, labelled panel (24 further specifications).
- Ordinal specifications estimate log-odds, not Likert points: they count towards the
  significance shares but are plotted on their own axis.
- Claim 3 is estimable only in the full-sample cells (within a single-position sample,
  comparison is constant), so its curve has 12 specifications.

**Decision rules for claim 1**, by share of main-curve specifications in which brand exceeds
reputation at p < 0.05:

| Share | Wording in the review and the post |
|---|---|
| < 25% | "Brand and reputation are indistinguishable" — kept as stated |
| 25–75% | "Brand may lead, but whether it does depends on analytic choices" — curve shown |
| > 75% | Claim 1 is wrong: §3.2 of the review is revised and the post restructured |

**Equivalence test for claim 2 — rule fixed 2026-09-12, before running anything.** A single
SESOI cannot settle this question. Every defensible anchor lands between **0.26 and 0.33
Likert points** (0.166–0.210 s.d. of the popularity outcome), and the point at which the
post-comparison verdict flips — 0.315 points — sits inside that band. Choosing one number
would choose the answer. The rule is therefore a band plus a three-way verdict, applied to
the **flip point** of each estimate: the smallest symmetric bound at which the 90% CI still
fits inside.

| Flip point | Verdict |
|---|---|
| below 0.26 points (0.166 s.d.) | *equivalent to zero* under every defensible threshold |
| above 0.33 points (0.210 s.d.) | *inconclusive* under every defensible threshold |
| in between | *at the boundary*, reported as such |

Where the 95% CI excludes zero, the estimate is labelled *effect present* instead. The band
comes from four independent anchors, none of which is decisive on its own: small telescopes
(the effect the original M1 had 33% power to detect, 0.33 points), Cohen's d = 0.20 (0.31),
half a rating star (0.28) and a quarter of the brand effect (0.26). A practical anchor — the
smallest change in downloads a developer would care about — could not be used: these data
contain no bridge from the 1–7 intention scale to conversion. For outcomes other than
popularity the band is applied in s.d. units of that outcome. The same script applies the
rule to the other nulls listed in §2.3 (six M2 interactions, two moderations), closing that
task; those results feed the review, not the post.

**Reporting test for claim 2.** Logistic mixed model `manip_ok ~ focal * x + (1 | subject)`,
for all three focal variables (the coding is now known, Phase 3.6). Because the checks count
1, 2 and 3 boxes respectively, the test compares high vs low *within* each focal variable and
never compares rates across them. If the high level significantly raises the probability of
ticking the matching box, §3.3 of the review is downgraded from "fragile null" to "illustration only", and the post drops the
subgroup figure.

**Claim 3** is presented as a hypothesis whatever the outcome. Its wording can strengthen
only if the three-way contrast is significant in at least 9 of its 12 specifications.

### Deliverables

| Output | Content |
|---|---|
| `analysis/R/07_specification_curve.R` | Grid, estimation, curve for claims 1 and 3 |
| `analysis/R/08_equivalence.R` | TOST on the §2.3 nulls; reporting test on slide 6 |
| `analysis/outputs/figures/fig_04_specification_curve.png` | Main curve + slide-6 panel |
| `analysis/outputs/tables/07_*.csv`, `08_*.csv`, logs | Every number behind the verdicts |
| New §12 in the review | Verdicts, with wording in §3.2, §3.3 and §6 adjusted according to the rules above |
| This plan | Tasks 2.3, 2.5 and 2.4 (point 1) closed; change-log entry |

### Out of scope

2.1 (sequence effects), 2.2 (random slopes), 2.4 point 2, 2.6, 2.7 and all of Phase 3. They
produce new evidence; Step 2A only checks the evidence the post will use.

### After Step 2A

Drafting the post (§4) can start immediately. Task 2.1 can run in parallel: no section of
the post structure needs it, and if it yields a result it belongs in a follow-up rather than
in this post.

---

## 2. Phase 2 — New analyses on the existing data

Ordered by value/cost ratio. All feasible with the data already in
`data/derived/long_measures.csv`, with no new collection.

### 2.1 Sequence and anchoring effects **[closed 2026-09-12]**

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

**Outcome (2026-09-12).** A contrast effect in the expected direction in every specification,
significant in none that can be read without conditioning on an untested interaction. Reported
as a hint, not a finding — see §2 of [`03-new-analyses.md`](03-new-analyses.md).

---

### 2.2 Between-respondent heterogeneity: random slopes **[closed 2026-09-12]**

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

**Outcome (2026-09-12): the prediction above was wrong, and is left standing rather than
quietly edited.** Respondents do differ in how much the manipulation moves them
(χ² = 10.29, 2 df, p = 0.0058; sensitivity s.d. 0.56 against average effects of 0.22–1.05), and
the correlation between baseline and sensitivity is −0.61: the people most inclined to download
anything are the least moved by the cues. The third specification, a personal level for each
cue, is saturated by construction and genuinely not estimable. See §3 of [`03-new-analyses.md`](03-new-analyses.md).

---

### 2.3 Equivalence testing on the null results **[closed 2026-09-12]**

**Question.** Is the popularity effect after comparison (β = 0.059) *zero*, or merely *not
distinguishable from zero*?

**Why it matters.** It is the correct way to support a null claim, and the thesis makes
three (popularity ineffective; no interaction between focal variables; no moderation in
several places). A TOST with a declared practical-relevance threshold turns "we found
nothing" into "we ruled out effects larger than X".

**Method.** Two One-Sided Tests, but with a band instead of a single SESOI: see *Next step —
Step 2A* for the rule adopted on 2026-09-12 (0.26–0.33 Likert points, verdict on the flip
point) and for why a single threshold was rejected. Apply to: the popularity effect overall
and after comparison, the six M2 interactions, the two moderations that fail to replicate.

**Acceptance criterion.** For each null, one of four labels: *equivalent to zero*, *at the
boundary*, *inconclusive*, *effect present*. No "not significant" without qualification.

**Note.** From Phase 1 we already know the six M2 interactions will almost certainly land
in *inconclusive* (MDE ≥ 0.76 s.d. against a SESOI of 0.20). That is the point: making it
explicit and quantified.

**Scheduled.** Step 2A.

---

### 2.4 Slide 6 as an outcome, not a filter **[point 1 closed 2026-09-12]**

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

**Dependency resolved.** The coding of the checks is now known (Phase 3.6).

**Scheduled.** Point (1), for all three focal variables, is part of Step 2A. Point (2) is not
scheduled.

---

### 2.5 Specification-curve analysis **[closed 2026-09-12]**

**Question.** How much does the "brand > reputation" conclusion depend on analytic choices?

**Why it matters.** It is the empirical answer to the thesis's structural defect. Instead of
arguing that the pooled specification is the right one, show **all** reasonable
specifications and see where the brand-vs-reputation contrast falls.

**Method.** Superseded by the pre-registered grid in *Next step — Step 2A*. The grid
originally written here (~120 specifications) was mis-sized and included indefensible
cells: naive OLS on clustered data, degenerate mixed models on single-position samples, and
slide-6-filtered samples inside the main curve.

**Acceptance criterion.** Share of specifications in which the brand-vs-reputation contrast
is significant at 5%. If it is low — as expected — the thesis conclusion is an analytic
choice, not a fact.

**Note.** This is also the best graphical material for the blog post.

---

### 2.6 Bayesian reformulation **[closed 2026-09-12, with the fallback]**

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

**Outcome (2026-09-12): completed with a full Bayesian model.** The task was first closed with
the authorised approximation and then reopened when `cmdstanr` was installed. The models were
fitted in Stan: four chains of 2,000 iterations, weakly informative priors, largest R-hat 1.010
and no divergent transitions. Brand is ahead of reputation with probability 88.8% overall, 98.6%
before any comparison and 51.1% after one. See §7 of [`03-new-analyses.md`](03-new-analyses.md).

**Why `rstan` could not fit it, accurately.** An earlier version of this entry said
RTools was missing. That was true when it was written and is no longer the reason. RTools 4.5 was
installed on 2026-09-12 and works: `make` resolves, `pkgbuild::has_build_tools()` returns TRUE.
Stan still cannot compile a model here. Four hypotheses were tested and eliminated:

| Hypothesis | Test | Result |
|---|---|---|
| The C++ toolchain is missing | Installed RTools; checked `make` and `pkgbuild` | Toolchain present and functional |
| `rstan` and `StanHeaders` versions are mismatched | Installed the aligned pair from the Stan repository (both 2.39.x) | No change |
| Output piped to `grep`/`tail` breaks `rstan`'s output capture | Re-ran with stdout redirected to a file, no pipe | No change |
| `Rscript` handles the sink stack differently from an interactive session | Re-ran under `R --vanilla -f` | No change |

In every attempt the build log contains **no compiler error at all**. The only error is
`sink(type = "output") : connessione non valida`, raised inside `rstan`'s own compilation
wrapper. The blocker is therefore an `rstan` incompatibility with this R 4.6.1 installation, not
the toolchain, not the package versions and not how the script is invoked.

**How it was finally fitted.** `cmdstanr` bundles its own CmdStan and bypasses `rstan`
entirely. It was not installed unprompted — roughly a gigabyte of download and a full CmdStan
build is a system-level change — but it was installed on request, and it works: CmdStan 2.39.0,
minimal model compiling, both models sampling without trouble. The `rstan` failure described
above is unchanged and now simply irrelevant.
`analysis/R/15_bayesian_brms.R` chooses its backend by trying a trivial model rather than
assuming one, so it uses `cmdstanr` where available, falls back to `rstan`, and stops with a
clear message only if neither compiles.

**What the comparison bought.** The approximation was kept rather than deleted, and the script
compares the two sets of probabilities. Across sixteen statements the largest disagreement is
**2.9 percentage points** and every other one is below 1.2. That is the only way to know whether
the work done while Stan was unavailable was resting on anything — and it was.

---

### 2.7 Structure of the response scale **[closed 2026-09-12]**

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

**Outcome (2026-09-12).** The scale is demonstrably not a ruler — the widest step between
cutpoints is 1.95 times the narrowest — and it changes nothing: the effect on the probability of
answering 5 or more differs by 0.8 to 3.1 percentage points between the two treatments, with the
ranking intact. See §4 of [`03-new-analyses.md`](03-new-analyses.md).

---

## 3. Phase 3 — Unblocked: raw export available

The raw questionnaire export (EFS/Unipark, 502 respondents who reached the end) and the
workbook that turned it into the thesis datasets were recovered on 2026-09-11.

**Privacy rule.** The export contains paradata — browser strings, session ids, timestamps —
and must never enter this repository, which is public. Scripts read it from a private path
given in the `RAW_EXPORT` environment variable and write aggregates only; `.gitignore`
blocks accidental copies.

| # | What | Status |
|---|---|---|
| **3.6** | Coding of the slide-6 checks | **Resolved** — brand = any of 3 boxes, reputation = either of 2, popularity = 1. Substantively correct; rates not comparable across focal variables (review §3.3) |
| **3.7** | Reverse coding of the involvement scales | **Resolved** — applied correctly (review §4.2) |
| 3.8 | The 18 mean-imputed scores | **Resolved** — exactly the respondents who skipped an item; mechanism documented (review §2.4). Re-estimating without imputation is optional, given the negligible impact |
| 3.9 | The 11 completed respondents excluded from the thesis | **Closed** — 10 were never shown a whole block (all missed the involvement pages, one also the app screens). The author recalls the exclusions were deliberate and probably test runs, without the specific reason; the export's `tester` flag is 0 for all 502 respondents, so no test run was marked as one (review §2.4) |
| 3.2 | Reliability and validity of the involvement scales | **Partly done** — α = 0.75 / 0.83 / 0.80. CFA still open, low priority |
| 3.1 | Heterogeneity by age, gender, occupation, education | **Done 2026-09-12** — no moderation reaches significance (age p = 0.20, gender p = 0.49, education p = 0.16, occupation p = 0.09). With 69% students the sample cannot tell the groups apart, which is a statement about the sample, not about people (§5 of [`03-new-analyses.md`](03-new-analyses.md)) |
| 3.3 | Response quality (speeding, straight-lining) | **Done 2026-09-12** — 33 respondents flagged (fastest 5%, or an identical answer to all eight items of a scale). Removing them moves every effect slightly up and changes nothing (§6 of [`03-new-analyses.md`](03-new-analyses.md)) |
| 3.4 | The respondents who dropped out | **Still blocked** — the export holds only the 502 who reached the end; the 43 who stopped earlier are not in it |
| 3.5 | Updating the market context (Appendix C) | Unchanged — needs a fresh survey of the Play Store; high priority for the blog post only |

---

## 4. Phase 4 — Blog post for lucabontempi.com **[published]**

**Destination.** A new post at [`lucabontempi.com/blog/reopening-my-thesis`](https://lucabontempi.com/blog/reopening-my-thesis), linking to
the 2023 one at
[`lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/`](https://lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/).

**Angle.** Not "here is my thesis", but **"I reopened my three-year-old thesis and found
three of my own mistakes"**. It is the most defensible framing and the most readable:
credibility comes from self-correction, not from defending the result.

**Published title.** *I Asked an AI to Review My Thesis. It Found Nothing New, Then Found Everything* — the
AI angle, kept marginal in the body, carries the headline. The body's own framing is
unchanged: the mistakes are the subject, the reviewer is the hook.

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

**Precondition.** Close Step 2A (tasks 2.3, 2.5 and 2.4 point 1). Without the
specification curve, point 2 of the structure is an assertion; with it, it is a
demonstration. Task 2.1 is not a precondition: no section of the post uses it.

---

## 5. Environment and dependencies

R 4.6.1, since 2026-09-12. R 4.2.2 is still on the machine but its library was rebuilt for
4.6.1 and no longer loads, so 4.6.1 is the only working interpreter.

| Package | Status | Use |
|---|---|---|
| `lme4`, `lmerTest` | present | mixed-effects models, Satterthwaite degrees of freedom |
| `emmeans` | present | contrasts and marginal means |
| `ordinal` | present | mixed and fixed-effect ordinal logit (`clmm`, `clm`) |
| `clubSandwich`, `sandwich`, `lmtest` | present | cluster-robust standard errors |
| `car`, `ggplot2` | present | Type II/III ANOVA, figures |
| `tidyverse`, `caret` | only needed by the original 2023 script | not used by the review scripts |
| `brms`, `cmdstanr` + CmdStan 2.39.0 | working | task 2.6; `cmdstanr` is the backend that compiles here |
| `rstan` | installed, cannot compile | superseded by `cmdstanr`; the diagnosis is kept in §2.6 |

**Regression check after the upgrade.** The whole pipeline was re-run on 4.6.1: every
versioned table agrees with the 4.2.2 output to twelve significant digits and the derived
datasets are bit-identical, so no number in either document moved.

**Technical debt cleared.** `lmerTest` was listed here as not installable until 2026-09-12;
it is now available, so Satterthwaite degrees of freedom no longer depend on the Kenward-Roger
fallback in `emmeans`.

**Technical debt cleared, second instalment.** RTools 4.5 and then `cmdstanr` were installed on
2026-09-12. Stan models now compile and sample, and task 2.6 rests on a real Bayesian model
rather than an approximation. `rstan` still fails on this installation; nothing depends on it any
more, and the diagnosis is kept in §2.6 because the reasoning is what makes the conclusion
checkable.

---

## 6. Change log

### 2026-09-13 — The design restated explicitly

**Added**

- §2.2 of the review now states, and verifies on the data, what was implicit everywhere: each
  focal variable exists in two versions, strong and weak, and each respondent sees exactly one
  of the two. All 1,473 subject × cue pairs carry a single level of `x`; the high/low split is
  256/235 (brand), 238/253 (reputation), 247/244 (popularity); all eight combinations of the
  three levels occur.
- The consequence is now written down rather than assumed: the manipulation is within subject
  across cues and between subjects within a cue, so every effect of `x` is a comparison
  between different people. It is the structural reason behind the underpowered interactions
  (§4.3) and behind the absence of any within-person perception check (§3.3).
- The same clarification was added to the opening of the blog post, where a reader could
  otherwise assume respondents saw both versions of an element.

---

### 2026-09-12 — The mean-centred ITD, assessed

**Added**

- `analysis/R/17_centering_check.R` and §2.5 of the review. The author asked whether the
  choice of a mean-centred ITD had been evaluated; it had not. The review had verified how
  `y_i_mc` is built and had not asked what it costs.
- What the check establishes: the centring is **within focal variable**, three constants and
  not one; it carries no estimate in the thesis, only Figure 3.1; and refitting every model
  on the centred outcome changes nothing except the between-cue main effect, which becomes
  structurally zero. The choice is sound.
- Two qualifications recorded: the label understates what was done, and heights in Figure 3.1
  are not comparable across cues (in 4 of 6 panels the centred ordering differs from the raw
  one).
- The substantive point: centring cannot replace a respondent term. Centring the outcome by
  respondent — the tempting move in a repeated-measures design — attenuates every effect by
  about a third, while respondent fixed effects and the mixed model agree closely with the
  pooled estimates.
- `fig_14_centring.png`: the same cell means on both scales.

---

### 2026-09-12 — Figures embedded, PDF render, the manipulation check reframed

**Changed**

- The eight figure placeholders in the post are now actual images, with the suggested
  captions promoted to figure captions. Two remain marked optional, in an HTML comment.
- The closing note no longer offers "further figures on the answer scale and on respondent
  demographics": both are now in the post.
- **The author confirmed that not using slide 6 was a deliberate choice**, not an oversight.
  §3.3 of the review, row C of §1 and the corresponding passage of the post were rewritten
  accordingly: the criticism is now directed at the *label* — a post-treatment self-report
  reported under the heading "manipulation check" — and at the consequence the thesis does
  not state, which is that no verification of perception exists in the design. The decision
  itself is recorded as correct.

**Added**

- A pandoc command in `docs/blog/README.md` that renders the post to PDF for review.

---

### 2026-09-12 — The Bayesian model, fitted for real

`cmdstanr` was installed on request and works where `rstan` does not, so task 2.6 no longer rests
on an approximation. Both models were fitted in Stan (four chains of 2,000 iterations, weak
priors, largest R-hat 1.010, no divergent transitions) and the posterior figure was added.

- **The approximation held.** Across sixteen probability statements the full model and the normal
  approximation differ by at most **2.9 percentage points**, and by less than 1.2 everywhere else.
  Keeping the approximation and comparing the two is what makes that checkable.
- **One number in the blog draft changed** and was corrected: brand ahead of reputation after
  comparison, 48.2% under the approximation against **51.1%** under the full model. The sentence
  called it a coin toss either way, and now it is literally one.
- §7 of [`03-new-analyses.md`](03-new-analyses.md) was rewritten: the method section now describes the
  sampler and the priors rather than the approximation, and reports the convergence diagnostics.
- `15_bayesian_brms.R` now selects its backend by trying a trivial model, instead of assuming
  `rstan`. Documentation that said Stan could not be fitted here has been corrected everywhere it
  appeared.

### 2026-09-12 — Explanatory figures, and a second attempt at Stan

**Figures.** `16_figures_extended.R` adds eight figures covering every result that benefits from
one: what splitting the sample cost, the effect of each cue by presentation position, the null
results against the relevance band, respondent heterogeneity, the cutpoints of the answer scale,
the sequence effects, the response-quality check and the demographic comparison. The blog draft
marks suggested figures with placeholders rather than embedding them, so the final selection stays
a human choice.

**Two figure errors of mine, caught before publication.** The heterogeneity figure first reported
the correlation between the plotted points (−0.83) rather than the one the model estimates
(−0.61); predicted individual values are shrunk towards zero, which inflates their apparent
association, and the text everywhere else uses −0.61. And the sequence figure labelled two
different estimands identically, so two different numbers appeared to contradict each other.

**Stan, second attempt.** RTools was installed, so task 2.6 was reopened. Four hypotheses were
tested and all eliminated; the blocker is inside `rstan`, not the toolchain (§2.6). The fallback
stands, `15_bayesian_brms.R` now probes Stan and exits cleanly instead of failing halfway, and the
earlier claim in these documents that "RTools is not installed" has been corrected wherever it
appeared.

**Blog post.** Rewritten to match the thesis's own English — Oxford spelling, the thesis's terms
for the three elements — while staying in a blog register, with figure placeholders and the note
on AI assistance extended into the reflection that prompted the project.

### 2026-09-12 — Phase 2 and Phase 3 completed

All remaining analyses were run and written up in a new document,
[`03-new-analyses.md`](03-new-analyses.md), which explains each model from first principles rather than
assuming the reader knows it. New scripts: `10_sequence_effects.R`, `11_heterogeneity.R`,
`12_response_scale.R`, `13_demographics_quality.R`, `14_posterior_probabilities.R`.

- **2.1 sequence effects — closed.** Contrast in direction everywhere, established nowhere.
- **2.2 heterogeneity — closed, and the pre-registered prediction was wrong.** Individual
  sensitivity to the manipulation is real (p = 0.0058) and inversely related to baseline
  enthusiasm (r = −0.61). The prediction of a null result stays in §2.2 as written.
- **2.6 Bayesian — closed with the authorised fallback.** RTools is absent, so Stan cannot
  compile; the normal approximation to the posterior was used and labelled as such.
- **2.7 response scale — closed.** The scale is not equally spaced and it does not matter.
- **3.1 demographics, 3.3 response quality — done.** Neither changes a conclusion.
- **A method error of mine, corrected before publication.** The first version of the scale
  comparison evaluated the ordinal effect at one reference respondent, which places each cue at
  a different point of the S-shaped curve; for reputation this inflated the gap between methods
  from 3.1 to 11.7 percentage points. Replaced by an average marginal effect over all
  observations.

Phase 4 (the blog post) is drafted, but kept out of the repository on purpose: see §7.

### 2026-09-12 — Step 2A executed; R upgraded to 4.6.1

**Equivalence rule fixed first.** A single SESOI could not settle the popularity question:
every defensible anchor falls between 0.26 and 0.33 Likert points and the flip point of the
post-comparison estimate (0.315) sits inside that band, so choosing one number would have
chosen the answer. The band plus a three-way verdict was written into *Step 2A* before any of
it was run.

**Step 2A executed.** Tasks 2.3, 2.5 and 2.4 (point 1) are closed; results in §12 of the
review, added in this pass. No conclusion of the review changed; what changed is how much
weight each one can carry. New scripts: `07_specification_curve.R`, `08_equivalence.R`.

**R upgraded to 4.6.1.** The 4.2.2 library had been rebuilt for 4.6.1 and stopped loading
mid-session. The whole pipeline was re-run on 4.6.1: every versioned table agrees with the
4.2.2 output to twelve significant digits and the derived datasets are bit-identical.
`lmerTest`, listed here as technical debt since 2026-09-09, is now installed.

**Two errors of mine, recorded because they reached the numbers.** The first convergence guard
keyed on a statistic `clmm` does not report, discarding all sixteen ordinal fits instead of the
one degenerate one (§12.4 of the review). And an earlier version of that guard crashed the
whole run on a zero-length value, so the script now wraps each fit so that one unstable model
cannot take the other 59 down with it.

### 2026-09-11 — Raw export recovered: Phase 3 blockers resolved

The raw EFS export and the original processing workbook (`Elaboration.xlsx`) were provided.
Both stay outside the repository; the new script `analysis/R/09_raw_export_checks.R` reads the
export from a private path and logs aggregates only.

- **Chain verified end to end:** ITD values, manipulation levels, positions and check values
  rebuilt from the raw answers match the published datasets for all 491 respondents.
- **3.7 resolved:** reverse coding applied correctly; α = 0.75 / 0.83 / 0.80. The §4.2 caveat
  of the review was replaced.
- **3.6 resolved:** the checks count 3 (brand), 2 (reputation) and 1 (popularity) boxes.
  Review §3.3 rewritten: the rates are not comparable across focal variables. The "p vs 50%"
  column added in the first version of the review is flagged as meaningless for a
  multi-select self-report.
- **Imputation and exclusions explained:** skipped items → mean-imputed (18); blocks never
  displayed → excluded (10 of 502 completers). One further respondent with complete data was
  excluded for a reason the export does not record. None of this is declared in the thesis.
- **Correction:** the review and this plan said `inv_cat` has four reverse-polarity pairs out
  of eight. It has five.
- Step 2A: the reporting test now covers all three focal variables.
- `.gitignore`: guards against accidental copies of raw exports and workbooks.

### 2026-09-11 — Next step defined: Step 2A

Step 2A (stress-testing the three claims the post will make) defined and pre-registered
before running any of it.

- New section *Next step — Step 2A*, with specification grid, decision rules and
  deliverables.
- §2.5: the specification grid was mis-sized (~120) and included indefensible cells. Replaced
  by a 24-specification main curve plus a separate 24-specification slide-6 panel.
- §2.3, §2.4: marked as scheduled in Step 2A (for 2.4, point 1 only, reputation and
  popularity only).
- §4: the post's precondition no longer includes task 2.1, which no section of the post uses.
- SESOI for the equivalence tests locked at 0.20 s.d., as proposed on 2026-09-09.

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
- §2.6 of the review (then numbered 2.5): `M plots.csv` is redundant given `M ANOVA_RM.csv`; four columns of the
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

---

## 7. Decisions taken without further instruction

Judgement calls made while carrying out the work, listed here so that they can be challenged
rather than discovered. All were reviewed and approved on 2026-09-12.

### Choices inside the analyses

| Decision | What was chosen | Why |
|---|---|---|
| Demographic categories | Age under 25 vs 25 or older; occupation student / employed / other; education in four groups; gender in three | The original categories are too thin to estimate anything: six age bands over 491 respondents, 69% of them students |
| Response-quality flags | Fastest 5% of completion times (under 97 seconds), or an identical answer to all eight items of the category-involvement scale. 33 respondents flagged | Two independent signals of inattention that do not depend on the answers being explained |
| Relevance band on other outcomes | The 0.26–0.33 band was derived for the popularity outcome and applied to the others in standard-deviation units of each | The anchors behind the band are about practical relevance on a common scale, not about one particular variable |
| Moderation effects | Expressed per one standard deviation of the moderator | Makes a moderation slope comparable with the relevance band, which is defined on the answer scale |

### Work deliberately not done

| Task | Status | Reason |
|---|---|---|
| 3.2 — confirmatory factor analysis of the involvement scales | Not done | Cronbach's α was computed (0.75 / 0.83 / 0.80). A CFA on three short scales of 3, 3 and 8 items would add little that α does not already say, and nothing that any conclusion depends on |
| 3.4 — the respondents who dropped out | Impossible | The export contains only the 502 who reached the end. The 43 who stopped earlier are not in it, and no other source holds them |
| 3.5 — updating the market context (Appendix C) | Out of scope | Requires a fresh survey of the scanner-app segment on the Play Store in 2026. That is data collection, not reanalysis, and it matters only to the blog post |

### The blog post

| Decision | What was chosen |
|---|---|
| Language | English, matching the thesis and the original post |
| Spelling | Oxford convention, as the thesis uses it: *-ize* verbs with *-our* nouns (randomized, behaviour) |
| Register | Plainer and shorter than the thesis, but the same voice: few contractions, no jargon left unexplained |
| Framing | Self-correction — "three of my own mistakes" — rather than a defence of the original result. The published title (*I Asked an AI to Review My Thesis. It Found Nothing New, Then Found Everything*) leads with the reviewer instead; the body was left as it is |
| Figures | Embedded as relative links into `analysis/outputs/figures/`: six in the body, three marked optional in an HTML comment so they can be dropped without hunting for them |
| PDF render | `pandoc` with `xelatex`, command in `docs/blog/README.md`. The images resolve through `--resource-path=docs/blog`, so the post keeps working both as a file in the repository and as a rendered document |
| The note on AI assistance | Kept, and extended into the reflection that prompted the project: the curiosity was how an AI would have *written* the thesis, and the useful question turned out to be how it would *review* it |
| Versioning | The drafts are **not** committed: `docs/blog/` is in `.gitignore`. The post lives at its own URL (https://lucabontempi.com/blog/reopening-my-thesis); a draft carrying the author's name should not become public merely because the analysis repository is |
