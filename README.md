# Determinants of Download on Mobile App Stores — review and extension

Review, validation and extension of the empirical analysis in the master's thesis
*Determinants of Download on Mobile App Stores — An Empirical Analysis*
(Luca Bontempi, Chair of Marketing, Eberhard Karls Universität Tübingen and Università di
Pavia, 14 February 2023).

This repository holds only the new work. The 2023 material is **referenced, not
duplicated**: the sole exception is the 11 CSV datasets in
[`original/data/`](original/data/), which the scripts read directly.

**Original work:**
[github.com/lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants)
· published at
[lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/](https://lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/)

---

## In short

The thesis asked which cue on an app store listing — **reputation** (average rating),
**popularity** (download count) or **developer brand** — best predicts the intention to
download an app. 491 respondents, a repeated-measures experimental design, three binary
manipulations.

The 2023 results **replicate exactly** and the data is **internally consistent**. What does
not hold up is the inference drawn from it — and, in one case, the construction of a
stimulus:

| 2023 conclusion | After the review |
|---|---|
| Brand is the most effective predictor | Brand and reputation are **indistinguishable** (p = 0.22); both ≫ popularity |
| Popularity is ineffective in all models | **Not a solid null**: it vanishes among respondents who say they looked at downloads (β = 0.51, p = 0.002), and the low-popularity stimulus showed 10K+ downloads alongside 84K reviews |
| Under comparison, reputation overtakes brand | They **converge**, they do not swap (1.41 → 0.90 vs 0.69 → 0.91) |
| Three-way interaction significant | **Not confirmed** (p = 0.63) once repeated measures are specified correctly |
| No interaction between focal variables | **Inconclusive**, not null: the design was blind to effects below 0.76 s.d. |

Full reasoning and figures: [`docs/01-review-of-2023-work.md`](docs/01-review-of-2023-work.md).

![Manipulation effect by focal variable, on the full sample and within the subgroup that reports using the cue](analysis/outputs/figures/fig_02_slide6_subgroup.png)

Two further defects concern how the data was built, and surfaced by reading the appendices:
the low-popularity stimulus is internally impossible, and 18 respondents have mean-imputed
involvement scores with no documentation of the fact.

---

## Repository structure

```
original/
  data/              the 11 CSV datasets, bit-identical to the 2023 package — do not modify
  README.md          what is versioned here and what is referenced upstream

analysis/
  R/                 review scripts, numbered in execution order
  outputs/
    tables/          results as CSV
    figures/         figures generated from the corrected estimates
    logs/            full output of every script — the evidence behind every number quoted

data/
  derived/           datasets rebuilt in long and wide format

docs/
  01-review-of-2023-work.md   the review: what holds, what does not, why
  02-work-plan.md             plan for further analysis + change log
  blog/                       drafts for the lucabontempi.com post
```

---

## Running the analysis

**Requirements:** R ≥ 4.2 with `lme4`, `emmeans`, `ordinal`, `car`, `clubSandwich`,
`ggplot2`.

```bash
Rscript -e 'install.packages(c("lme4","emmeans","ordinal","car","clubSandwich","ggplot2"), repos="https://cloud.r-project.org")'
```

Scripts must be run **from the repository root**, in the order shown: `03` produces the
datasets that `04`, `05` and `06` consume.

```bash
Rscript analysis/R/01_replication.R         # exact replication of Table 3.2 of the thesis
Rscript analysis/R/02_data_audit.R          # data integrity and comparison against Table 3.1
Rscript analysis/R/03_build_derived.R       # builds data/derived/
Rscript analysis/R/04_corrected_inference.R # correct ANOVA + test of the ranking
Rscript analysis/R/05_robustness.R          # slide-6 check, ordinal model, multiplicity, power
Rscript analysis/R/06_figures.R             # figures
```

Every script writes a complete log to `analysis/outputs/logs/`. If a number appears in a
document under `docs/`, the corresponding log contains it.

### What each script does

| Script | What it produces | Why it exists |
|---|---|---|
| `00_setup.R` | shared paths and helpers | the original CSVs carry a UTF-8 BOM that must be handled on read |
| `01_replication.R` | replication of the 9 regressions and the ANOVA | verify the 2023 work is reproducible before criticising it |
| `02_data_audit.R` | structure, cross-file consistency, descriptives, imputations, redundancies | separate data problems from analysis problems |
| `03_build_derived.R` | `long_measures.csv` (1,473 × 19), `wide_subjects.csv` (491 × 17) | the original files are fragmented per model; long format enables pooled analysis |
| `04_corrected_inference.R` | correct repeated-measures ANOVA, mixed model, contrasts | the original specification does not model repeated measures, and the ranking is never tested |
| `05_robustness.R` | checks on slide 6, ordinal scale, multiplicity, power | four checks the original work does not contain |
| `06_figures.R` | three figures | communicating the corrected estimates |

---

## Relationship to the original work

The 2023 material lives in its own repository:
[**lucabnt/mobile-app-download-determinants**](https://github.com/lucabnt/mobile-app-download-determinants).
It is not duplicated here. The original R script, LaTeX sources, figures and final PDFs are
referenced; the full path mapping is in [`original/README.md`](original/README.md).

The one exception is `original/data/`: the 11 CSVs are versioned because every script reads
them, and without them a clean clone would not be reproducible. They are bit-identical to
those distributed in 2023.

**No original file is modified.** Fixes to the 2023 code — including two references to
non-existent objects that abort its execution — are **reproduced in `analysis/`, not applied
upstream**, and documented in [`docs/02-work-plan.md`](docs/02-work-plan.md) §6. No analysis
in this repository alters any data: `data/derived/` contains reconstructions obtained purely
by reorganisation, verified against the source files in `02_data_audit.R`.

---

## Status

- [x] **Phase 1** — replication, audit, corrected inference, robustness
- [ ] **Phase 2** — sequence effects, between-respondent heterogeneity, equivalence testing,
      specification curve
- [ ] **Phase 3** — **blocked**: requires the raw questionnaire export (demographics, scale
      items, coding of the brand check)
- [ ] **Phase 4** — update post on lucabontempi.com

Detailed backlog with priorities and acceptance criteria:
[`docs/02-work-plan.md`](docs/02-work-plan.md).

---

## Citation

For the original work:

> Bontempi, L. (2023). *Determinants of Download on Mobile App Stores — An Empirical
> Analysis*. Master's thesis, Chair of Marketing, Eberhard Karls Universität Tübingen /
> Università di Pavia.

For the review, cite this repository and the commit date.

---

## Licence

[`LICENSE.md`](LICENSE.md) is carried over from the original repository and distinguishes
three regimes:

| Material | Licence | Where it lives |
|---|---|---|
| CSV datasets | CC BY 4.0 | `original/data/`, `data/derived/` — versioned here |
| 2023 R code and LaTeX sources | MIT | [upstream](https://github.com/lucabnt/mobile-app-download-determinants) |
| Thesis text and PDFs | © 2023 Luca Bontempi, all rights reserved | [upstream](https://github.com/lucabnt/mobile-app-download-determinants) |

The scripts in `analysis/` and the documents in `docs/` are new material under the same MIT
licence. CC BY 4.0 on the data requires attribution and an indication of changes made:
`data/derived/` is derived material, and the transformations producing it are documented in
[`analysis/R/03_build_derived.R`](analysis/R/03_build_derived.R).
