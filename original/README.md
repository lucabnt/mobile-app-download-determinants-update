# Original material (2023)

The original work is published in full here:

**https://github.com/lucabnt/mobile-app-download-determinants**

This folder does not duplicate it. It holds only what the scripts in
[`../analysis/R/`](../analysis/R/) read directly; everything else is referenced upstream.

## What is versioned here

| Path | Contents | Why it is here |
|---|---|---|
| `data/` | The 11 CSV datasets, bit-identical to the 2023 package | Every script in the review reads them. Without them a clean clone is not reproducible. 428 KB. |

The files in `data/` must not be modified: they are the reference snapshot against which
[`../analysis/R/02_data_audit.R`](../analysis/R/02_data_audit.R) verifies every
reconstruction.

## What is referenced, not copied

| Material | Upstream |
|---|---|
| Original R script | [`Data and Code/Determinants of Download on Mobile App Stores - An Empirical Analysis.r`](https://github.com/lucabnt/mobile-app-download-determinants/blob/main/Data%20and%20Code/Determinants%20of%20Download%20on%20Mobile%20App%20Stores%20-%20An%20Empirical%20Analysis.r) |
| LaTeX sources and bibliography | [`.tex` and `.bib` files in the root](https://github.com/lucabnt/mobile-app-download-determinants) |
| Thesis figures | [`Figure/`](https://github.com/lucabnt/mobile-app-download-determinants/tree/main/Figure) |
| Final PDFs (Pavia, Tübingen, print versions) | [`Final Thesis PDFs/`](https://github.com/lucabnt/mobile-app-download-determinants/tree/main/Final%20Thesis%20PDFs) |
| Original repository README | [`README.md`](https://github.com/lucabnt/mobile-app-download-determinants/blob/main/README.md) |

These paths are listed in [`../.gitignore`](../.gitignore). If you have them on your local
disk they stay where they are: they are simply not tracked.

## Getting the complete material

```bash
git clone https://github.com/lucabnt/mobile-app-download-determinants.git
```

Path mapping between the two repositories:

| Upstream | Here |
|---|---|
| `Data and Code/*.csv` | `original/data/` |
| `Data and Code/*.r` | not tracked |
| `Figure/` | not tracked |
| `Final Thesis PDFs/` | not tracked |
| `*.tex`, `*.bib` | not tracked |
