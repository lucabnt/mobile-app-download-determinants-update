# Piano di lavoro e registro delle modifiche

Documento operativo. La prima parte traccia **cosa è stato fatto**, la seconda **cosa
resta da fare** con priorità e criteri di accettazione, la terza è il **changelog**.

Il documento di revisione del lavoro originale è
[`01-revisione-lavoro-2023.md`](01-revisione-lavoro-2023.md).

---

## 0. Principi di lavoro

1. **Il materiale 2023 si referenzia, non si duplica.** Vive nel suo repository
   ([lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants)).
   Qui è versionato solo `original/data/`, perché gli script lo leggono e senza di esso un
   clone non è riproducibile. Ogni correzione vive in `analysis/` e viene documentata qui,
   mai applicata retroattivamente all'originale.
2. **Ogni numero citato in un documento deve essere prodotto da uno script versionato.**
   Niente valori copiati a mano. I log in `analysis/outputs/logs/` sono la prova.
3. **Le correzioni si dichiarano, non si nascondono.** Dove la revisione contraddice la
   tesi, il documento riporta entrambe le versioni e la ragione dello scarto.
4. **Separare ciò che i dati dimostrano da ciò che suggeriscono.** Un p = 0,11 è un'ipotesi,
   non un risultato; va scritto come tale anche quando la storia sarebbe più bella.

---

## 1. Fase 1 — Replica e validazione **[completata]**

| # | Attività | Script | Esito |
|---|---|---|---|
| 1.1 | Struttura del repository, snapshot dell'originale | — | Fatto |
| 1.2 | Replica esatta delle 9 regressioni e dell'ANOVA | `01_replication.R` | Corrispondenza a 4 decimali |
| 1.3 | Audit di integrità dei dati | `02_data_audit.R` | Nessuna incoerenza |
| 1.4 | Dataset derivati in formato long e wide | `03_build_derived.R` | `data/derived/` |
| 1.5 | ANOVA a misure ripetute corretta + modello misto | `04_corrected_inference.R` | Interazione a 3 vie non confermata |
| 1.6 | Test formale della graduatoria fra variabili focali | `04_corrected_inference.R` | Brand ≈ reputazione ≫ popolarità |
| 1.7 | Robustezza al manipulation check | `05_robustness.R` | Effetto popolarità recuperato |
| 1.8 | Modello logit ordinale | `05_robustness.R` | Conclusioni invariate |
| 1.9 | Correzione per test multipli | `05_robustness.R` | 2/81 sopravvivono a Holm |
| 1.10 | Analisi di potenza sulle interazioni nulle | `05_robustness.R` | MDE ≥ 0,76 s.d. |
| 1.11 | Figure basate sulle stime corrette | `06_figures.R` | 3 figure |
| 1.12 | Documento di revisione | — | `docs/01-revisione-lavoro-2023.md` |

**Risultato della fase:** i dati sono validi, l'inferenza no. Tre conclusioni della tesi
cambiano, il resto tiene. Dettaglio in `01-revisione-lavoro-2023.md` §1.

---

## 2. Fase 2 — Nuove analisi sui dati esistenti

Ordinate per rapporto valore/costo. Tutte fattibili con i dati già in
`data/derived/long_measures.csv`, senza nuova raccolta.

### 2.1 Effetti sequenziali e di ancoraggio **[priorità alta]**

**Domanda.** L'ITD per l'app in posizione *k* dipende da **quali valori** l'utente ha
visto nelle posizioni precedenti, non solo dal fatto che ne abbia viste.

**Perché conta.** È la domanda che la tesi voleva porre con il Modello 2, ma M2 la
affronta su 143–196 osservazioni della sola terza posizione. In formato long, con
predittori ritardati e intercetta casuale per soggetto, la stessa domanda usa tutte le
982 osservazioni con *n* > 1 — cinque volte il potere statistico.

**Metodo.** `y ~ x * (media dei livelli visti prima) + x * (livello immediatamente
precedente) + focale + posizione + (1 | soggetto)`. Distinguere effetto di **contrasto**
(un'app forte vista prima abbassa la valutazione della successiva) da effetto di
**assimilazione** (l'alza).

**Dati.** Già presenti: `x_other_brand`, `x_other_rep`, `x_other_pop`, `pos_num` in
`long_measures.csv`.

**Criterio di accettazione.** Stima del coefficiente di contrasto con IC 95% e verifica
che il segno sia stabile fra specificazione lineare e ordinale.

**Rischio.** L'ordine è randomizzato ma i livelli precedenti sono anch'essi randomizzati,
quindi l'identificazione è pulita. Rischio basso.

---

### 2.2 Eterogeneità fra rispondenti: pendenze casuali **[priorità alta]**

**Domanda.** Tutti gli utenti reagiscono agli stessi segnali, o esistono profili distinti
— chi guarda il brand, chi guarda i rating, chi non guarda niente?

**Perché conta.** L'ICC di 0,41 dice che le persone differiscono molto nel *livello* di
ITD. Non dice nulla su quanto differiscano nella *sensibilità* ai segnali, che è la
domanda con implicazioni pratiche: se metà del campione ignora i rating, la media
sottostima l'effetto per l'altra metà.

**Metodo.** `(1 + x | soggetto)` e `(1 + focale | soggetto)`; confronto via LRT con il
modello a sola intercetta casuale. Se la varianza delle pendenze è significativa,
estrarre i BLUP e descrivere la distribuzione delle sensibilità individuali.

**Limite noto.** Tre osservazioni per soggetto sono poche per stimare pendenze casuali
affidabili. Il modello potrebbe non convergere o dare varianza al confine. **Se accade,
va riportato come tale** — non forzato con specificazioni via via più semplici finché una
"funziona".

**Criterio di accettazione.** LRT più diagnostica di convergenza. Un esito negativo
(nessuna eterogeneità stimabile) è un risultato pubblicabile.

---

### 2.3 Test di equivalenza sui risultati nulli **[priorità alta]**

**Domanda.** L'effetto della popolarità dopo il confronto (β = 0,059) è *zero*, o è solo
*non distinguibile da zero*?

**Perché conta.** È il modo corretto di sostenere un'affermazione nulla, e la tesi ne fa
tre (popolarità inefficace; nessuna interazione fra variabili focali; nessuna moderazione
in vari punti). Un TOST con soglia di rilevanza pratica dichiarata trasforma
"non abbiamo trovato nulla" in "abbiamo escluso effetti superiori a X".

**Metodo.** Two One-Sided Tests con SESOI (smallest effect size of interest) fissato *a
priori* — proposta: 0,20 s.d., cioè circa 0,3 punti sulla scala 1–7, la soglia sotto la
quale un effetto sull'intenzione di download non ha rilevanza gestionale. Applicare a:
effetto popolarità post-confronto, sei interazioni di M2, due moderazioni non replicate.

**Criterio di accettazione.** Per ciascun nullo, una delle tre etichette: *equivalente a
zero*, *inconcludente*, *effetto presente*. Nessun "non significativo" senza qualificazione.

**Nota.** Dalla Fase 1 sappiamo già che le sei interazioni di M2 finiranno quasi
certamente in *inconcludente* (MDE ≥ 0,76 s.d. contro SESOI 0,20). È il punto: renderlo
esplicito e quantificato.

---

### 2.4 Manipulation check come moderatore, non come filtro **[priorità alta]**

**Domanda.** Come cambia l'effetto della manipolazione fra chi l'ha percepita e chi no?

**Perché conta.** Il filtro usato in Fase 1 (§3.3 della revisione) è un condizionamento
post-trattamento e può reintrodurre selezione. Interagire `x` con `manip_ok` invece di
filtrare stima la stessa quantità senza scartare osservazioni, ed è la specificazione
difendibile in una pubblicazione.

**Metodo.** `y ~ focale * x * manip_ok + ... + (1 | soggetto)`. In parallelo, trattare
il fallimento del check come errore di misura nel trattamento e calcolare la correzione
per attenuazione, per avere un secondo limite superiore indipendente.

**Criterio di accettazione.** L'effetto della popolarità nel gruppo che supera il check
deve ricadere nell'intervallo [0,22; 0,51] già stimato, oppure va spiegato perché no.

---

### 2.5 Analisi della curva di specificazione **[priorità media]**

**Domanda.** Quanto dipende la conclusione "brand > reputazione" dalle scelte analitiche?

**Perché conta.** È la risposta empirica al difetto strutturale della tesi. Invece di
sostenere che la specificazione pooled è quella giusta, si mostrano **tutte** le
specificazioni ragionevoli e si guarda dove cade il contrasto brand-vs-reputazione.

**Metodo.** Griglia sulle scelte: campione (tutte / n=1 / n=3 / check superato / soggetti
3-su-3) × modello (OLS / OLS cluster-robust / misto / ordinale misto) × controlli
(con/senza involvement, con/senza posizione). ~120 specificazioni. Grafico della curva
ordinata per stima, con evidenziata quella usata nella tesi.

**Criterio di accettazione.** Percentuale di specificazioni in cui il contrasto
brand-vs-reputazione è significativo al 5%. Se è bassa — come atteso — la conclusione
della tesi è una scelta analitica, non un fatto.

**Nota.** È anche il materiale grafico migliore per il blog post.

---

### 2.6 Riformulazione bayesiana **[priorità media]**

**Domanda.** Qual è la probabilità che il brand conti più della reputazione?

**Perché conta.** È la domanda che un lettore non statistico pone davvero, e il
frequentista non la risponde: "p = 0,22" non è "il 22% di probabilità che siano uguali".
Con un posteriore si scrive direttamente *P*(β_brand > β_rep) = *x*%.

**Metodo.** Preferibile `brms`/Stan con priori debolmente informative. **Vincolo tecnico:**
`brms` non è installato e richiede un toolchain Stan; `lmerTest` non compila su R 4.2.2
in questo ambiente. Ripiego accettabile: simulazione dal posteriore approssimato dei
effetti fissi del modello misto (normale multivariata su `vcov`), sufficiente per una
probabilità di contrasto ma **da etichettare come approssimazione**, non come stima
bayesiana completa.

**Criterio di accettazione.** Se si usa il ripiego, il documento deve dirlo in modo
esplicito. Preferibile aggiornare l'ambiente R prima.

---

### 2.7 Struttura della scala di risposta **[priorità bassa]**

**Domanda.** Gli utenti usano la scala 1–7 in modo uniforme, o si accumulano su valori
focali (4 = neutro, estremi evitati)?

**Perché conta.** Le soglie del modello ordinale stimate in Fase 1 non sono equispaziate:
la distanza 4|5 → 5|6 è molto più piccola di 1|2 → 2|3. Se la scala è compressa al centro,
OLS distorce sistematicamente gli effetti piccoli — cioè proprio quelli sulla popolarità.

**Metodo.** Confronto delle soglie stimate contro l'equispaziatura; modello con
componente di *response style* (tendenza individuale a usare gli estremi) come effetto
casuale.

**Criterio di accettazione.** Quantificare di quanto cambia l'effetto della popolarità
fra scala trattata come intervallo e come ordinale. Dalla Fase 1 la differenza sembra
piccola; serve confermarlo.

---

## 3. Fase 3 — Estensioni che richiedono dati non disponibili

Queste **non sono eseguibili** con il materiale attuale. Elencate perché determinano
cosa cercare negli archivi della raccolta 2023.

| # | Estensione | Dato mancante | Priorità |
|---|---|---|---|
| 3.1 | Eterogeneità per età, genere, occupazione, istruzione | Le variabili demografiche sono descritte nel §3.1.2 della tesi ma **non compaiono in nessuno degli 11 CSV pubblicati** | Alta — recuperare l'export grezzo del questionario |
| 3.2 | Affidabilità e validità delle scale di involvement (α di Cronbach, CFA) | Solo i punteggi medi `inv_app`, `inv_dl`, `inv_cat` sono condivisi, non gli item | Alta — stesso export |
| 3.3 | Qualità delle risposte (straight-lining, tempi di compilazione) | Timestamp e pattern di risposta per item | Media |
| 3.4 | Analisi dei 54 rispondenti che hanno abbandonato | Record incompleti (545 avviati − 491 completati) | Media — verificare selezione differenziale |
| 3.5 | Aggiornamento del contesto di mercato (Appendice C) | Nuova rilevazione del segmento scanner app sul Play Store | Bassa per la revisione, **alta per il blog post** |

**Azione immediata:** verificare se l'export grezzo del questionario (probabilmente
formato SoSci Survey / Qualtrics, dato il campo `lfdn`) è ancora reperibile. Sbloccherebbe
3.1–3.4 in un colpo solo.

---

## 4. Fase 4 — Blog post per lucabontempi.com

**Destinazione.** Aggiornamento del post esistente
[`lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/`](https://lucabontempi.com/blog/determinants_of_download_on_mobile_app_stores/),
o post nuovo che vi rimanda.

**Angolo.** Non "ecco la mia tesi", ma **"ho riaperto la mia tesi di tre anni fa e ho
trovato tre errori miei"**. È il taglio più difendibile e il più leggibile: la
credibilità viene dall'autocorrezione, non dalla difesa del risultato.

**Struttura proposta.**

1. Il contesto: cosa chiedeva la tesi e perché la domanda è ancora aperta nel 2026.
2. Il risultato che non regge: la popolarità *non* era inefficace, la manipolazione non
   passava. Figura 2.
3. Il risultato che si appiattisce: brand e reputazione sono indistinguibili. Figura 1.
4. Il risultato che migliora: la convergenza brand/reputazione col confronto, e la
   popolarità come euristica di ripiego. Figura 3.
5. Cosa ho imparato sull'analisi: nove regressioni su sottocampioni disgiunti sprecano
   potere statistico; 81 test senza correzione producono rumore; un manipulation check
   non usato è un manipulation check sprecato.
6. Cosa resta vero.

**Requisiti.**

- Lingua: da decidere. Il post originale e la tesi sono in inglese; **default proposto:
  inglese**, con eventuale versione italiana.
- Ogni numero deve rimandare a uno script del repository. Il repository è la fonte, il
  post è la sintesi.
- Le tre figure di `analysis/outputs/figures/` vanno rigenerate con etichette nella
  lingua scelta prima della pubblicazione.
- Dichiarare esplicitamente che l'analisi 2026 è stata condotta con assistenza di uno
  strumento di AI, se questo è lo standard del sito.

**Precondizione.** Chiudere almeno 2.1, 2.3 e 2.5 della Fase 2: senza la curva di
specificazione il punto 3 della struttura è un'asserzione, con essa è una dimostrazione.

---

## 5. Ambiente e dipendenze

R 4.2.2 (`C:\Program Files\R\R-4.2.2`).

| Pacchetto | Stato | Uso |
|---|---|---|
| `tidyverse`, `caret` | presente | richiesti dallo script originale |
| `lme4` | presente | modelli a effetti misti |
| `emmeans` | installato in questa sessione | contrasti e medie marginali |
| `ordinal` | presente | logit ordinale misto (`clmm`) |
| `clubSandwich`, `sandwich`, `lmtest` | installati in questa sessione | errori standard cluster-robust |
| `car` | presente | ANOVA di tipo II/III su modelli misti |
| `lmerTest` | **non installabile** | fallisce la compilazione da sorgente su R 4.2.2 |
| `brms` | assente | servirebbe per 2.6; richiede toolchain Stan |

**Debito tecnico.** Aggiornare R a una versione ≥ 4.3 sbloccherebbe `lmerTest` (df di
Satterthwaite sui modelli misti) e renderebbe praticabile `brms`. Nel frattempo i df dei
modelli misti provengono da `emmeans` con metodo Kenward-Roger e sono incrociati con SE
cluster-robust CR2, il che è sufficiente per le conclusioni attuali.

---

## 6. Registro delle modifiche

### 2026-09-09 — Materiale originale referenziato invece che duplicato

**Modificato**

- `original/` non contiene più una copia integrale della tesi 2023. Sono stati rimossi
  dal versionamento `original/pdf/` (8,1 MB), `original/figures/` (20 MB, di cui 18,8 in
  quattro PNG quasi identici), `original/tex/`, `original/code/` e
  `original/README.original.md`: tutti referenziabili a
  [lucabnt/mobile-app-download-determinants](https://github.com/lucabnt/mobile-app-download-determinants).
  I file restano sul disco locale, semplicemente non sono tracciati (`.gitignore`).
- `original/data/` resta versionato: 428 KB letti da ogni script della pipeline. Senza,
  un clone pulito non è riproducibile.
- Aggiunto `original/README.md` con la mappa dei percorsi fra i due repository.
- Aggiornati i riferimenti in `README.md` e `docs/01-revisione-lavoro-2023.md`: i link a
  file non più versionati puntano ora all'upstream.

**Metodo di rimozione.** `git rm --cached` più nuovo commit, scelta non distruttiva: la
storia non è stata riscritta e `main` non è stato forzato. **Conseguenza da tenere
presente:** il commit `ae798f9` era già stato pubblicato su GitHub, quindi i ~28 MB
restano raggiungibili nella storia e `git clone` continua a scaricarli. Renderli
irraggiungibili richiederebbe una riscrittura della storia con force-push su un branch
già pubblicato — deliberatamente non fatta.

### 2026-09-09 — Impianto del repository e Fase 1

**Aggiunto**

- Struttura del repository: `original/`, `analysis/`, `data/derived/`, `docs/`.
- `analysis/R/00_setup.R` — percorsi, lettura CSV con gestione del BOM, helper.
- `analysis/R/01_replication.R` — replica delle 9 regressioni e dell'ANOVA originali.
- `analysis/R/02_data_audit.R` — verifica di integrità e confronto con la Tabella 3.1.
- `analysis/R/03_build_derived.R` — costruzione di `long_measures.csv` (1.473 × 19) e
  `wide_subjects.csv` (491 × 17).
- `analysis/R/04_corrected_inference.R` — ANOVA a misure ripetute corretta, modello
  misto, test formale della graduatoria.
- `analysis/R/05_robustness.R` — manipulation check, logit ordinale, test multipli,
  potenza, moderazioni pooled.
- `analysis/R/06_figures.R` — tre figure basate sulle stime corrette.
- `docs/01-revisione-lavoro-2023.md` — documento di revisione.
- `docs/02-piano-di-lavoro.md` — questo documento.

**Corretto rispetto all'originale** (in `analysis/`, non in `original/`)

- `summary(M4_rep)` / `summary(M4_pop)` → `summary(M2_rep)` / `summary(M2_pop)`. Nello
  script originale sono riferimenti a oggetti inesistenti e ne interrompono l'esecuzione.
- Lettura dei CSV con `fileEncoding = "UTF-8-BOM"` (i file hanno un BOM che rinomina la
  prima colonna in `ï..lfdn`).
- `Error(lfdn)` con `lfdn` intero → `Error(factor(lfdn))` e modelli a effetti misti.

**Conclusioni della tesi modificate**

| Conclusione originale | Stato dopo la revisione |
|---|---|
| Interazione a tre vie *i* × *x* × *n* significativa | **Ritirata** — p = 0,63 con misure ripetute corrette |
| Il brand è il predittore più efficace | **Ridimensionata** — indistinguibile dalla reputazione (p = 0,22) |
| La popolarità è inefficace in tutti i modelli | **Ribaltata** — β = 0,51, p = 0,002 sui rispondenti che superano il check |
| Con il confronto, la reputazione supera il brand | **Riformulata** — convergono, non si invertono |
| L'involvement nel download rafforza la reputazione | **Ritirata** — non si replica (p = 0,48) |
| L'involvement nella categoria favorisce il brand | **Ritirata** — non si replica (p = 0,37) |
| Nessuna interazione fra variabili focali | **Riqualificata** — inconcludente, non nulla (MDE ≥ 0,76 s.d.) |

**Non modificato**

- Nessun contenuto del lavoro 2023: i CSV in `original/data/` sono bit-identici a quelli
  del pacchetto originale, e nessun altro file originale è stato alterato.
