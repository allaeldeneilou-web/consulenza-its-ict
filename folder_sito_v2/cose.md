# Resoconto v1 -> v2: cosa c'e da fare

Analisi del contenuto di `folder_sito_v1` (generatore statico del portale corsi ITS ICT Piemonte) in vista della migrazione a `folder_sito_v2`. Il progetto v1 e un piccolo sito statico (Node, zero dipendenze runtime dichiarate) che legge `data/corsi.json` e genera `dist/index.html`, piu una parte di infrastruttura AWS (S3 + DynamoDB) descritta sia in CloudFormation che in Terraform.

Le criticita trovate confermano e ampliano quanto gia annotato in `Perizia.md`.

---

## 1. Sicurezza - PRIORITA MASSIMA

- **Credenziali in chiaro nel repo**: `config/impostazioni.txt` contiene `FTP_HOST`, `FTP_USER`, `FTP_PASS` in chiaro e un `api_token` (formato token GitHub, `ghp_...`) per il gestionale. Il file e commentato "NON cancellare" e risulta committato in git.
- **Lo stesso token e hardcoded anche nell'infrastruttura**: sia in `infra/portale-its.yaml` / `data/infra/tf/main.tf` (CloudFormation, come `Default` del parametro `ApiTokenGestionale`) sia in `infra/tf/main.tf` (Terraform, come `default` della variabile `api_token_gestionale`). Un default di un parametro non e un segreto protetto: chiunque legga il template lo vede.
- **Il token e gia nella storia git** (unico commit `e8b2d38 riorganizzazione cartelle`): anche cancellandolo dai file adesso resterebbe recuperabile dallo storico. Va **ruotato/revocato**, non solo rimosso.
- **Policy S3 troppo permissiva**: sia nel template CloudFormation che in Terraform, la bucket policy concede `Principal: '*'` con `Action: 's3:*'` (non solo `s3:GetObject`) sull'intero bucket del sito. Questo permette a chiunque su Internet di scrivere/cancellare oggetti nel bucket, non solo leggerli.
- **Public access block disattivato completamente** in Terraform (`block_public_acls/block_public_policy/ignore_public_acls/restrict_public_buckets = false`): nessuna delle protezioni AWS di default e attiva.
- **DynamoDB `iscrizioni` senza protezioni**: nessuna cifratura esplicita, nessun point-in-time recovery, nessun controllo di accesso dedicato. Contiene dati di iscrizione (potenzialmente dati personali) e secondo `DEPLOY.md` "non l'ha mai guardata nessuno" — nessuno ne controlla contenuto o accessi.
- **Provider Terraform punta a `127.0.0.1:5000`** con `access_key/secret_key = "test"`: sembra una configurazione locale/di test (localstack o simile) lasciata come unica definizione dell'infrastruttura "reale", quindi non e chiaro cosa venga effettivamente applicato in produzione.

## 2. Processo di deploy - da rifare completamente

Da `DEPLOY.md` (procedura manuale scritta nel 2023):

- Deploy interamente manuale: modifica locale su un portatile specifico in ufficio, `npm run build`, upload via **FileZilla** con credenziali FTP in chiaro, overwrite completo della cartella remota.
- **Nessun backup della versione precedente**: la nota stessa dice che una volta si e persa la pagina dei corsi per due giorni, e il rollback consiste nello sperare che "qualcuno" abbia ancora la vecchia versione.
- **Single point of failure umano**: la procedura assume la presenza di "Marco"; se non c'e, non e chiaro chi sappia come procedere.
- **Deploy fatto "il venerdi pomeriggio quando non c'e nessuno"**: nessuna revisione, nessun controllo, nessuna tracciabilita di chi ha fatto cosa.
- Se il bucket S3 da errore la soluzione indicata e "rimettere pubblico i permessi" — coerente con il fatto che il public access block e disattivato e la policy e troppo aperta: il workaround manuale ha probabilmente causato la configurazione insicura vista sopra.
- Nessuna pipeline CI/CD, nessun gate di deploy, nessun ambiente di test separato dalla produzione.

Questo conferma quanto gia scritto in `Perizia.md`: serve migrazione a Git/GitHub, pipeline automatizzata, gate per il deploy, ambienti dev/test/prod separati.

## 3. Duplicazione e incoerenza nell'IaC

- I file di infrastruttura esistono **duplicati in due posti diversi** con contenuto identico:
  - `infra/portale-its.yaml` e `data/infra/portale-its.yaml` (CloudFormation)
  - `infra/tf/main.tf` e `data/infra/tf/main.tf` (Terraform)
- Oltre alla duplicazione, **coesistono due strumenti IaC diversi** (CloudFormation e Terraform) per la stessa infrastruttura, con Perizia.md che chiede esplicitamente "Solo terraform come IaC". Va scelto uno strumento unico e vanno rimossi i duplicati/il CloudFormation.

## 4. Bug e problemi nel codice applicativo (`src/build.mjs`)

- **Bug nel calcolo delle ore totali**: `totaleOre()` fa `corsi.slice(1).reduce(...)`, escludendo sistematicamente il **primo corso** dell'array (`SOA-FW - Firewall, 60 ore`) dal totale mostrato in pagina. Il totale visualizzato e quindi sbagliato per costruzione, non solo se cambiano i dati.
- **Nessun escaping dell'HTML generato**: `render()` interpola `dati.istituto`, `c.titolo`, `c.codice`, ecc. direttamente nel template HTML senza sanitizzazione. Con dati statici e curati manualmente il rischio e basso, ma se `corsi.json` diventasse editabile da piu persone o da un form (es. collegato alla tabella iscrizioni) si aprirebbe a XSS.
- **Dipendenza `left-pad` dichiarata in `package.json` ma mai usata** nel codice: dipendenza morta, va rimossa (oltretutto `left-pad` e storicamente il caso di scuola dei rischi delle dipendenze minime/fragili nella supply chain npm).

## 5. Cosa manca del tutto

Rispetto a quanto richiesto in `Perizia.md`:

- Migrazione da lavoro locale a Git/GitHub (repository condiviso, accessibile da ovunque).
- Pipeline di CI/CD e gate di approvazione prima del deploy.
- Autenticazione/protezione degli accessi con session token al posto delle credenziali statiche in chiaro.
- Ambienti separati dev / test / prod (oggi esiste solo "produzione", modificata a mano).
- Un vero sistema di backup/rollback per il sito pubblicato.

## 6. Priorita consigliate per v2

1. **Rotazione immediata delle credenziali esposte** (token gestionale, credenziali FTP) — indipendente da tutto il resto.
2. Spostare tutti i segreti fuori dal repo/dai template IaC (env vars, secrets manager); niente default con valori reali nei parametri CloudFormation/Terraform.
3. Correggere la bucket policy S3 (solo `s3:GetObject` pubblico) e riattivare il public access block dove non serve l'eccezione.
4. Consolidare l'IaC su un solo strumento (Terraform, come richiesto) ed eliminare i file duplicati.
5. Aggiungere protezioni base alla tabella DynamoDB (cifratura, point-in-time recovery, policy di accesso minime).
6. Impostare repo Git + pipeline CI/CD con build (`npm run build`), test e gate manuale/automatico prima del deploy; deploy automatico al posto di FileZilla.
7. Creare ambienti dev/test/prod separati.
8. Correggere il bug di `totaleOre()` e rimuovere la dipendenza `left-pad` inutilizzata.
9. Valutare escaping dell'HTML generato in vista di dati non piu statici.
10. Definire una procedura di backup/rollback del sito pubblicato, per non ripetere l'incidente dei due giorni di pagina persa.
