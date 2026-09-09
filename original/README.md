# Materiale originale (2023)

Il lavoro originale è pubblicato per intero qui:

**https://github.com/lucabnt/mobile-app-download-determinants**

Questa cartella non lo duplica. Contiene soltanto ciò che gli script in
[`../analysis/R/`](../analysis/R/) leggono direttamente; tutto il resto è
referenziato all'upstream.

## Cosa è versionato qui

| Percorso | Contenuto | Perché è qui |
|---|---|---|
| `data/` | Gli 11 dataset CSV, bit-identici al pacchetto 2023 | Ogni script della revisione li legge. Senza di essi un clone pulito non è riproducibile. 428 KB. |

I file in `data/` non vanno modificati: sono lo snapshot di riferimento contro cui
`../analysis/R/02_data_audit.R` verifica ogni ricostruzione.

## Cosa è referenziato, non copiato

| Materiale | Upstream |
|---|---|
| Script R originale | [`Data and Code/Determinants of Download on Mobile App Stores - An Empirical Analysis.r`](https://github.com/lucabnt/mobile-app-download-determinants/blob/main/Data%20and%20Code/Determinants%20of%20Download%20on%20Mobile%20App%20Stores%20-%20An%20Empirical%20Analysis.r) |
| Sorgenti LaTeX e bibliografia | [file `.tex` e `.bib` nella root](https://github.com/lucabnt/mobile-app-download-determinants) |
| Figure della tesi | [`Figure/`](https://github.com/lucabnt/mobile-app-download-determinants/tree/main/Figure) |
| PDF finali (Pavia, Tübingen, versioni da stampa) | [`Final Thesis PDFs/`](https://github.com/lucabnt/mobile-app-download-determinants/tree/main/Final%20Thesis%20PDFs) |
| README del repository originale | [`README.md`](https://github.com/lucabnt/mobile-app-download-determinants/blob/main/README.md) |

Questi percorsi sono elencati in [`../.gitignore`](../.gitignore). Se li hai sul disco
locale restano dove sono: semplicemente non vengono tracciati.

## Per ottenere il materiale completo

```bash
git clone https://github.com/lucabnt/mobile-app-download-determinants.git
```

Corrispondenza dei percorsi fra i due repository:

| Upstream | Qui |
|---|---|
| `Data and Code/*.csv` | `original/data/` |
| `Data and Code/*.r` | non tracciato |
| `Figure/` | non tracciato |
| `Final Thesis PDFs/` | non tracciato |
| `*.tex`, `*.bib` | non tracciato |
