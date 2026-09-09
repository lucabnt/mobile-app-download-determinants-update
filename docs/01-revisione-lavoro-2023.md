# Revisione del lavoro 2023

**Oggetto:** *Determinants of Download on Mobile App Stores — An Empirical Analysis*
(tesi magistrale, Chair of Marketing, Universität Tübingen / Università di Pavia, 14/02/2023)

**Stato:** revisione completata sul materiale originale invariato in [`original/`](../original/).
Tutti i numeri citati sono riproducibili con gli script in [`analysis/R/`](../analysis/R/);
i log completi sono in [`analysis/outputs/logs/`](../analysis/outputs/logs/).

---

## 1. Sintesi esecutiva

Il lavoro è **replicabile e i dati sono integri**. Le nove regressioni della Tabella 3.2
si riproducono cifra per cifra e i dataset non presentano incoerenze interne, valori
mancanti o discrepanze rispetto alle statistiche descrittive pubblicate.

I problemi non sono nei dati: sono nel modo in cui l'inferenza è stata condotta a
partire da essi. Tre difetti sono sostanziali e cambiano le conclusioni.

| # | Problema | Effetto sulle conclusioni |
|---|---|---|
| **A** | L'ANOVA a misure ripetute non modella le misure ripetute (`Error(lfdn)` con `lfdn` intero) | L'interazione a tre vie dichiarata significativa **sparisce** con la specifica corretta (F = 0,64; p = 0,63) |
| **B** | La graduatoria brand > reputazione > popolarità è dedotta confrontando a occhio coefficienti stimati su sottocampioni diversi, senza test della differenza | Con il test formale **brand e reputazione non sono distinguibili** (p = 0,22). La gerarchia difendibile è: brand ≈ reputazione ≫ popolarità |
| **C** | Il manipulation check è riportato ma mai usato | Il risultato più citato della tesi — "la popolarità è sorprendentemente inefficace" — **non regge**: sui rispondenti che superano il check l'effetto passa da +0,22 (p = 0,075) a +0,51 (p = 0,002) |

Altri tre problemi sono di calibrazione dell'evidenza, non di direzione:

- **81 coefficienti stimati, nessuna correzione per test multipli.** Dei 23 significativi a
  p < 0,10 ne sopravvivono **2** a Holm e **4** a FDR < 0,05 — in entrambi i casi
  essenzialmente il solo effetto principale del brand.
- **Due delle tre moderazioni dell'involvement non si replicano** in un modello pooled.
- **L'affermazione "nessuna interazione a due vie fra variabili focali" è inconcludente,
  non nulla:** il disegno poteva rilevare solo interazioni ≥ 0,75–0,98 deviazioni standard.

Il quadro che emerge non demolisce il lavoro. Ne cambia il baricentro: la storia più
solida non è "il brand vince", ma **"brand e reputazione sono equivalenti finché l'utente
guarda una sola app; il confronto li fa convergere; la popolarità conta poco ma non zero"**.

---

## 2. Cosa è stato verificato e ha retto

### 2.1 Replica esatta della Tabella 3.2

Lo script [`01_replication.R`](../analysis/R/01_replication.R) riproduce le nove
regressioni con la stessa specifica dell'originale. Corrispondenza a quattro decimali su
tutti i coefficienti, errori standard, R², R² aggiustati, numerosità e quote di
manipulation check. Nessuna discrepanza.

Coefficienti focali replicati:

| Modello | β | p |
|---|---|---|
| M1 (rep) | 0,4986 | 0,0596 |
| M1 (pop) | 0,3611 | 0,0944 |
| M1 (brand) | 1,5289 | < 0,001 |
| M2 (rep) | 1,3351 | 0,0014 |
| M2 (pop) | 0,5340 | 0,2560 |
| M2 (brand) | 1,0347 | 0,0180 |
| M3 (rep) | 0,4576 | 0,0895 |
| M3 (pop) | 0,3677 | 0,0929 |
| M3 (brand) | 1,5028 | < 0,001 |

### 2.2 Integrità dei dati

[`02_data_audit.R`](../analysis/R/02_data_audit.R) verifica:

- **Struttura del disegno.** 491 rispondenti × 3 misure = 1.473 osservazioni. Ogni
  soggetto vede ogni variabile focale esattamente una volta e ogni posizione esattamente
  una volta: è un quadrato latino, correttamente randomizzato (nessun duplicato).
- **Coerenza fra file.** Il merge su `lfdn` fra i file dei modelli e il file ANOVA dà
  0 discordanze su `y`, 0 su `x` e 0 su `comp` per tutte e tre le variabili focali.
- **Sottocampioni.** Le numerosità di M1 (n = 1) e M2 (n = 3) coincidono esattamente con
  quelle attese dal file a misure ripetute: 149/189/153 e 196/143/152, somma 491 in
  entrambi i casi.
- **Centratura.** `y_i_mc` è la centratura di `y_i` sulla media **per variabile focale**
  (errore massimo 0,000000); le tre misure di involvement sono centrate sulla media
  globale.
- **Valori mancanti.** Zero, in tutti gli undici file.
- **Statistiche descrittive.** Medie e deviazioni standard della Tabella 3.1 coincidono
  con i dati.

### 2.3 Due scostamenti minori nella Tabella 3.1

Nessuno dei due cambia alcuna conclusione, ma vanno corretti in una eventuale
ripubblicazione:

- Le deviazioni standard sono **di popolazione** (divise per *N*), non campionarie
  (*N* − 1). Esempio: `y_rep` riportata 1,7077 contro 1,7095 campionaria. Scarto ~0,001.
- La riga `comp_i` riporta i valori **di disegno** (media 2/3 = 0,6667; s.d. 0,4714),
  non quelli realizzati. Nel campione la media varia per variabile focale: 0,6965 per
  reputazione, 0,6883 per brand, 0,6151 per popolarità.

---

## 3. I difetti che cambiano le conclusioni

### 3.1 (A) L'ANOVA a misure ripetute non modella le misure ripetute

Lo script originale contiene:

```r
ANOVA.aov <- aov(y_i ~ i_name*x_i_name*n_name + Error(lfdn), data = data1)
```

`lfdn` è letto come **intero**. `aov()` lo tratta quindi come covariata continua, non
come fattore di raggruppamento: lo strato `Error: lfdn` collassa a 1 grado di libertà
senza residui, e tutti i test finiscono nello strato `Within` con 1.454 df residui — cioè
un'ANOVA fra osservazioni indipendenti. La struttura a misure ripetute, che è il cuore
del disegno, non entra nel modello.

Che i dati siano fortemente raggruppati per rispondente lo mostra il modello a effetti
misti: **ICC = 0,41**. Il 41% della varianza in ITD è varianza fra persone. Ignorarla non
è un dettaglio.

Con `subject` come fattore, i test cambiano:

| Termine | Tesi (specifica originale) | Specifica corretta (strato *Within*) |
|---|---|---|
| variabile focale *i* | F = 42,19 *** | F = 73,96 *** |
| manipolazione *x* | F = 60,84 *** | F = 98,99 *** |
| posizione *n* | F = 2,37 (p = 0,094) | F = 4,03 (p = 0,018) |
| *i* × *x* | F = 10,28 *** | F = 9,90 *** |
| **i × x × n** | **F = 2,68 (p = 0,030)** | **F = 0,64 (p = 0,633)** |

L'interazione a tre vie, che il testo della tesi presenta come *"further foundations for
subsequent analyses"*, **non sopravvive**. Il modello misto lo conferma
(χ² = 6,01; 4 df; p = 0,198).

**Errore di trascrizione collegato.** Il testo riporta *F*(2, 4) = 42,187 e *F*(1, 4) =
60,841. I gradi di libertà al denominatore non sono 4 ma 1.454 (il "4" sembra ripreso
dalla colonna *Df* di un'altra riga della tabella `aov`). I valori di *F* e i p-value
sono corretti; i df pubblicati no.

### 3.2 (B) La graduatoria non è mai testata

Il claim centrale — *"developer's brand is generally the most decisive element"* — nasce
dal confronto fra β = 1,5289 (M1 brand), β = 0,4986 (M1 rep) e β = 0,3611 (M1 pop). Ma
questi tre coefficienti provengono da **tre regressioni su tre sottocampioni disgiunti**
(153, 149 e 189 rispondenti diversi). Confrontarli non è un test: non esiste in tutta la
tesi una statistica che risponda alla domanda "brand batte davvero reputazione?".

Il modello pooled su tutte le 1.473 osservazioni, con intercetta casuale per rispondente,
la risponde. L'interazione `focale × manipolazione` è necessaria (LRT: χ² = 25,02; 2 df;
p < 0,001), quindi gli effetti *sono* diversi fra loro. Ma i confronti a coppie
(correzione di Holm) mostrano **dove** sta la differenza:

| Confronto | Δβ | IC 95% | p (Holm) |
|---|---|---|---|
| reputazione − brand | −0,210 | [−0,623; 0,202] | **0,222** |
| popolarità − brand | −0,835 | [−1,252; −0,418] | < 0,001 |
| popolarità − reputazione | −0,624 | [−1,035; −0,214] | 0,0006 |

Gli effetti stimati sull'intero campione:

| Variabile | β | IC 95% | *d* di Cohen |
|---|---|---|---|
| Brand | +1,053 | [0,813; 1,293] | 0,66 |
| Reputazione | +0,842 | [0,602; 1,083] | 0,49 |
| Popolarità | +0,218 | [−0,022; 0,458] | 0,14 |

**Brand e reputazione non sono statisticamente distinguibili.** La gerarchia a tre
gradini della tesi è in realtà a due: {brand, reputazione} ≫ popolarità.

Che l'apparente vantaggio del brand fosse in buona parte un artefatto della
frammentazione in sottocampioni si vede dal confronto fra la stima di M1 per la
reputazione (0,4986, p < 0,10, su 149 osservazioni) e la stima pooled (0,842, p < 0,001,
su 491 misure di reputazione). Il coefficiente della reputazione **raddoppia** quando lo
si stima usando tutta l'informazione disponibile invece di un terzo di essa.

### 3.3 (C) Il manipulation check non è mai usato

La Tabella 3.2 riporta le quote di superamento del manipulation check, poi non le
utilizza. Sono queste:

| Modello | Quota | IC 95% | p vs. 50% |
|---|---|---|---|
| M1 rep | 75,8% | [68,2; 82,5] | < 0,001 |
| M2 rep | 79,1% | [72,7; 84,6] | < 0,001 |
| M3 rep | 77,2% | [73,2; 80,8] | < 0,001 |
| M1 brand | 68,6% | [60,6; 75,9] | < 0,001 |
| M2 brand | 63,2% | [55,0; 70,8] | 0,0015 |
| M3 brand | 67,4% | [63,1; 71,5] | < 0,001 |
| M1 pop | 62,4% | [55,1; 69,4] | 0,0008 |
| **M2 pop** | **55,9%** | **[47,4; 64,2]** | **0,181** |
| M3 pop | 60,5% | [56,0; 64,8] | < 0,001 |

Nel sottocampione M2 la manipolazione della popolarità è **indistinguibile dal caso**.
Complessivamente 194 osservazioni su 491 falliscono il check sulla popolarità, contro
112 su 491 per la reputazione. Solo 163 rispondenti su 491 superano tutti e tre i check.

Questo importa perché il risultato più notevole della tesi è proprio un nullo sulla
popolarità. Un nullo su una manipolazione che spesso non è stata percepita non è un
risultato sostantivo: è attenuazione da errore di misura. Rifacendo la stima:

| Campione | Brand | Reputazione | Popolarità |
|---|---|---|---|
| Tutte le osservazioni (N = 1.473) | 1,053 *** | 0,842 *** | 0,218 (p = 0,075) |
| Solo check superato (N = 1.007) | 1,381 *** | 1,098 *** | **0,507 (p = 0,002)** |
| Solo soggetti 3/3 check (N = 489) | 1,344 *** | 1,242 *** | **0,517 (p = 0,013)** |

L'effetto della popolarità **più che raddoppia** e diventa nettamente significativo. Tutti
e tre gli effetti crescono, come atteso quando si rimuove errore di misura, ma la
popolarità è quella che cambia di più — coerente col fatto che è quella con la
manipolazione più debole.

> **Nota di cautela.** Il filtro sul manipulation check è un condizionamento
> post-trattamento: può reintrodurre selezione. Le stime filtrate vanno lette come limite
> superiore, quelle non filtrate come limite inferiore attenuato. L'intervallo fra 0,22 e
> 0,51 è la risposta onesta. Ciò che non è più difendibile è la lettura "zero".

---

## 4. Problemi di calibrazione dell'evidenza

### 4.1 Test multipli

Nove regressioni producono **81 coefficienti** (intercette escluse). Nessuna correzione.

| | Conteggio |
|---|---|
| p < 0,10 grezzo | 23 |
| p < 0,05 grezzo | 13 |
| Sopravvivono a Holm (p < 0,05) | **2** |
| Sopravvivono a Benjamini–Hochberg (FDR < 0,05) | **4** |

I due che sopravvivono a Holm sono l'effetto del brand in M1 e in M3 — cioè lo stesso
effetto stimato due volte. A FDR si aggiungono l'effetto della reputazione in M2 e
`inv_cat` in M3 (pop).

Va detto che la soglia p < 0,10 adottata nella tesi è, di per sé, una scelta legittima e
dichiarata; il problema è che i claim narrativi non distinguono fra i risultati robusti e
quelli che vivono al margine. Diverse conclusioni del Capitolo 3 poggiano su coefficienti
con p fra 0,05 e 0,10 su un totale di 81 test.

### 4.2 Le moderazioni dell'involvement in gran parte non si replicano

Stimando le moderazioni in un unico modello pooled invece che in nove regressioni
separate:

| Claim della tesi | Fonte | Nel modello pooled | Esito |
|---|---|---|---|
| L'involvement nel processo di download rafforza la reputazione | M1 rep, β = 0,3861, p < 0,10 | β = −0,066, p = 0,48 | **Non si replica** |
| L'involvement nella categoria favorisce il brand | M1 brand, β = 0,4001, p < 0,10 | β = 0,089, p = 0,37 | **Non si replica** |
| L'involvement nelle app rafforza tutte e tre le variabili | M2, M3 | brand 0,119 (p = 0,27); rep 0,260 (p = 0,016); pop 0,324 (p = 0,003) | **Parziale**: vale per reputazione e popolarità, non per il brand |

L'unico effetto di moderazione che regge è quello dell'involvement generale nelle app, e
regge esattamente per le due variabili per cui la tesi non lo enfatizza.

Le implicazioni manageriali del §3.3 costruite su queste due moderazioni — *"quando gli
utenti sono molto coinvolti nel processo di download si affidano di più alla
reputazione"* e *"quando l'involvement nella categoria è alto scelgono brand noti"* —
vanno ritirate o degradate a ipotesi.

### 4.3 "Nessuna interazione fra variabili focali" è inconcludente

La tesi conclude di non aver trovato *"clear evidence of any two-way interaction between
reputation, popularity and brand"*. È vero che nessuna delle sei interazioni in M2 è
significativa. Ma con campioni di 143–196 osservazioni e 11 predittori, l'effetto minimo
rilevabile (α = 0,05, potenza 80%) è:

| Modello | Termine | β | s.e. | MDE (punti) | MDE (s.d.) |
|---|---|---|---|---|---|
| M2 rep | x_rep : x_brand | 0,166 | 0,467 | 1,31 | 0,77 |
| M2 rep | x_rep : x_pop | −0,371 | 0,461 | 1,29 | 0,76 |
| M2 pop | x_pop : x_brand | 0,392 | 0,546 | 1,53 | 0,98 |
| M2 pop | x_pop : x_rep | −0,744 | 0,539 | 1,51 | 0,96 |
| M2 brand | x_brand : x_rep | 0,251 | 0,507 | 1,42 | 0,90 |
| M2 brand | x_brand : x_pop | −0,677 | 0,511 | 1,43 | 0,90 |

Il disegno poteva rilevare soltanto interazioni fra 0,76 e 0,98 deviazioni standard —
effetti enormi per la letteratura di riferimento, dove le interazioni sono tipicamente
frazioni dell'effetto principale (qui: 0,14–0,66 s.d.). Il modello era **cieco** a
qualunque interazione plausibile. La formulazione corretta è "inconcludente", non
"assente".

---

## 5. Il difetto di disegno che genera gli altri

La tesi lo dichiara onestamente nel §3.5: non è un fattoriale 2×2×2, ma un disegno in cui
**una sola variabile per volta viene manipolata** mentre le altre restano a valori
intermedi. È la scelta che rende possibile lo studio dell'effetto-confronto, e in questo
senso è motivata.

Ma è anche la causa a monte di tutto il resto:

- Impone la frammentazione in nove regressioni su sottocampioni disgiunti (§3.2).
- Rende le interazioni fra variabili focali strutturalmente sotto-potenziate (§4.3).
- Spinge verso una lettura per confronto visivo di coefficienti anziché per test.

**La cosa importante è che il difetto di disegno non impone il difetto di analisi.** I
dati raccolti *supportano* un'analisi pooled a effetti misti: sono un quadrato latino
bilanciato con 491 soggetti e 1.473 osservazioni. La frammentazione era una scelta
analitica, non una necessità del disegno — ed è la scelta che ha sprecato la maggior
parte del potere statistico disponibile.

---

## 6. Un risultato che la tesi ha quasi trovato

L'effetto del confronto merita una riscrittura, non una correzione. La tesi lo descrive
come una **inversione**: *"there was a reversal between the developer's brand and
reputation, which became the most important element of the three"*. Stimando lo stesso
fenomeno su un unico modello invece che su M1 vs M2:

| Variabile | Mostrata per prima | Dopo altre app |
|---|---|---|
| Brand | **1,407** (p < 0,001) | 0,902 (p < 0,001) |
| Reputazione | 0,691 (p = 0,002) | 0,912 (p < 0,001) |
| Popolarità | **0,462 (p = 0,019)** | 0,059 (p = 0,707) |

Non è un'inversione: è una **convergenza**. Il brand perde un terzo della sua forza
(1,41 → 0,90), la reputazione ne guadagna un terzo (0,69 → 0,91), e finiscono
sovrapposti. Nessuno dei due supera l'altro in modo statisticamente distinguibile.

E c'è un dato che la tesi non menziona affatto: **la popolarità funziona, quando l'utente
non ha alternative davanti** (0,462; p = 0,019). Crolla a zero appena il confronto entra
in gioco. Questo è più interessante del nullo generalizzato che la tesi riporta, e ha una
lettura sostantiva immediata: il numero di download è un'euristica di ripiego, usata in
assenza di informazione migliore e abbandonata non appena ne compare altra.

**Cautela dovuta:** l'interazione a tre vie `focale × manipolazione × confronto` ha
p = 0,111. Il pattern è coerente e nella direzione attesa, ma non è dimostrato. Va
presentato come ipotesi motivata dai dati, da testare in una raccolta dedicata.

---

## 7. Robustezza alla specificazione

La variabile dipendente è una Likert 1–7 trattata con OLS. Rifacendo la stima con un
logit ordinale cumulativo a effetti misti (`ordinal::clmm`, stessa specifica), le
conclusioni non cambiano:

| Variabile | log-odds | Odds ratio |
|---|---|---|
| Brand | +1,712 | 5,54 |
| Reputazione | +1,297 | 3,66 |
| Popolarità | +0,374 | 1,45 |

Stessa gerarchia, stesso divario fra {brand, reputazione} e popolarità, stessa
non-significatività del contrasto brand-vs-reputazione (p = 0,128). **La scelta di usare
OLS su una Likert non è un problema in questo dataset**: è l'unico dei controlli
effettuati che conferma il lavoro originale senza riserve.

---

## 8. Errori nel codice pubblicato

[`original/code/thesis_analysis_2023.R`](../original/code/thesis_analysis_2023.R), righe
64 e 73:

```r
M2_rep <- lm(y_rep_3 ~ ..., data=data1)
summary(M4_rep)          # <- oggetto inesistente
...
M2_pop <- lm(y_pop_3 ~ ..., data=data1)
summary(M4_pop)          # <- oggetto inesistente
```

Residui di una precedente numerazione dei modelli. Lo script **si interrompe** con
`object 'M4_rep' not found`: chi lo scarichi per replicare i risultati non arriva in
fondo. I modelli sono stimati correttamente, è solo la chiamata a `summary()` a essere
sbagliata, quindi nessun risultato pubblicato ne è affetto.

Due problemi minori aggiuntivi:

- I CSV hanno un BOM UTF-8. Senza `fileEncoding = "UTF-8-BOM"` la prima colonna viene
  letta come `ï..lfdn`; innocuo qui perché `lfdn` non entra nei modelli, ma è una trappola
  per chi estenda il codice.
- `library(caret)` è caricata e mai usata.

---

## 9. Cosa resta in piedi

Il documento fin qui è una lista di problemi, e conviene dire chiaramente cosa **non** è
in discussione:

1. **La domanda di ricerca è buona** e l'impostazione sperimentale — partecipazione
   diretta degli utenti invece che scraping delle classifiche — è il contributo
   metodologico più solido del lavoro. L'argomento del §3 sul perché le classifiche degli
   store non riflettono le preferenze è corretto e ben documentato.
2. **La raccolta dati è pulita.** 491 rispondenti completi su 545, randomizzazione
   corretta, zero valori mancanti, quadrato latino bilanciato. Questa è la parte del
   lavoro su cui tutto il resto può essere ricostruito.
3. **L'effetto del brand è reale e grande**, ed è l'unico risultato che sopravvive a
   qualunque correzione, inclusa Holm su 81 test. β ≈ 1,05–1,53 punti su 7, *d* ≈ 0,66.
4. **La scelta della categoria** (app scanner: bassi effetti di rete, freemium, presenza
   di un brand globale come Adobe) è ben argomentata e fa esattamente il lavoro che deve
   fare.
5. **Le limitazioni sono dichiarate onestamente** nel §3.5, incluso il difetto di disegno
   principale.

La revisione non ribalta il lavoro. Ribalta **un** risultato (popolarità), **appiattisce**
una gerarchia (brand vs reputazione), **ritira** due moderazioni e **riqualifica** un
nullo in un'inconcludenza. Il resto tiene.

---

## 10. Riepilogo delle correzioni da riportare

Per un'eventuale erratum o ripubblicazione:

| Sede | Testo attuale | Correzione |
|---|---|---|
| §3.2, ANOVA | *F*(2, 4) = 42,187; *F*(1, 4) = 60,841; *F*(2, 4) = 2,369 | df al denominatore = 1.454 |
| §3.2, ANOVA | Interazione a tre vie significativa (*F*(4) = 2,681; p < 0,05) | Non significativa con misure ripetute corrette (p = 0,63) |
| §3.2, Abstract | *"developer's brand is generally the most decisive element"* | Brand e reputazione non distinguibili; entrambi ≫ popolarità |
| §3.2, Abstract | *"popularity [...] unexpectedly ineffective [...] across all models"* | Effetto positivo e significativo sui rispondenti che superano il check; nullo solo dopo il confronto |
| §3.2 | *"reversal between brand and reputation"* | Convergenza, non inversione |
| §3.3 | Moderazione involvement-download su reputazione | Non replicata |
| §3.3 | Moderazione involvement-categoria su brand | Non replicata |
| Abstract | *"not possible to find clear evidence of any two-way interaction"* | Inconcludente per potenza insufficiente (MDE ≥ 0,76 s.d.) |
| Tab. 3.1 | s.d. di popolazione; `comp_i` con valori di disegno | s.d. campionarie; valori realizzati |
| `*.r` | `summary(M4_rep)`, `summary(M4_pop)` | `summary(M2_rep)`, `summary(M2_pop)` |

---

## 11. Riproducibilità di questa revisione

```bash
Rscript analysis/R/01_replication.R       # replica della Tabella 3.2
Rscript analysis/R/02_data_audit.R        # integrità dei dati
Rscript analysis/R/03_build_derived.R     # dataset in formato long
Rscript analysis/R/04_corrected_inference.R
Rscript analysis/R/05_robustness.R
Rscript analysis/R/06_figures.R
```

Ambiente usato: R 4.2.2, `lme4`, `emmeans`, `ordinal`, `clubSandwich`, `car`, `ggplot2`.
I log integrali sono versionati in [`analysis/outputs/logs/`](../analysis/outputs/logs/),
le tabelle in [`analysis/outputs/tables/`](../analysis/outputs/tables/).

Il passo successivo — quali analisi aggiuntive i dati permettono ancora — è in
[`02-piano-di-lavoro.md`](02-piano-di-lavoro.md).
