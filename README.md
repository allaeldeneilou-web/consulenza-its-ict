# Perizia tecnica - Portale ITS

## Flusso di build, controllo e deploy

Il sito è generato staticamente tramite `src/build.mjs`, uno script Node.js senza dipendenze esterne.

### Ordine delle operazioni

1. **Build locale** — eseguire lo script dalla cartella dell'applicazione:
   ```bash
   cd folder_sito
   npm ci
   npm test
   npm run secret-scan
   npm run build
   ```

2. **Validazione IaC** — validare Terraform:
   ```bash
   cd folder_sito/infra/tf
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   ```

3. **Deploy** — pubblicare `dist/` tramite GitHub Actions:
   - workflow: `.github/workflows/deploy.yml`;
   - trigger: manuale (`workflow_dispatch`);
   - target: bucket S3 `portale-its-sito`;
   - controllo finale: smoke test sull'endpoint static website.

## Automazione CI/CD

La repository usa GitHub Actions per automatizzare due fasi distinte:

1. **Continuous Integration (CI)**: controlla automaticamente qualità applicativa e validità dell'infrastruttura prima dell'integrazione su `main`.
2. **Continuous Delivery/Deployment (CD)**: prepara e pubblica manualmente il sito statico su Amazon S3 dopo che il codice è stato validato.

Questa separazione riduce il rischio operativo: ogni modifica viene prima verificata in pull request, mentre il deploy resta un'azione esplicita e controllata.

### Continuous Integration

Il workflow di CI si trova in:

```text
.github/workflows/ci.yml
```

Il workflow viene eseguito automaticamente su pull request verso `main`.

La pipeline è divisa in due job:

| Job | Working directory | Obiettivo |
| --- | --- | --- |
| `Build sito (Node)` | `folder_sito` | Verificare installazione, test e build del sito |
| `Terraform fmt & validate` | `folder_sito/infra/tf` | Verificare formattazione e validità della configurazione Terraform |

#### Job applicativo

Il job applicativo esegue:

```bash
npm ci
npm test
npm run build
```

`npm ci` installa le dipendenze in modo riproducibile usando `package-lock.json`.

`npm test` esegue i test automatici Node, che verificano:

- generazione di `versione.json`;
- generazione di `index.html`;
- presenza dei 6 corsi;
- totale ore corretto;
- assenza del vecchio totale errato.

`npm run build` genera gli artefatti statici dentro `dist/`.

#### Job Terraform

Il job Terraform valida la parte Infrastructure as Code:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

`terraform fmt -check -recursive` verifica la formattazione dei file `.tf`.

`terraform init -backend=false` inizializza Terraform senza accedere al backend remoto.

`terraform validate` controlla sintassi, riferimenti interni e coerenza generale della configurazione.

### Continuous Delivery / Deploy

Il workflow di deploy si trova in:

```text
.github/workflows/deploy.yml
```

Questo workflow non parte automaticamente su ogni push. Viene avviato manualmente da GitHub Actions tramite `workflow_dispatch`.

Il deploy pubblica gli artefatti statici generati in `dist/` su Amazon S3.

Sequenza logica:

1. checkout del codice;
2. setup Node.js;
3. installazione dipendenze;
4. test applicativi;
5. build del sito;
6. configurazione credenziali AWS;
7. sincronizzazione di `dist/` sul bucket S3;
8. smoke test sull'endpoint pubblico.

Il comando centrale di pubblicazione è:

```bash
aws s3 sync dist/ "s3://<bucket_name>" --delete
```

Il flag `--delete` mantiene il bucket allineato alla build corrente, rimuovendo eventuali file non più presenti in `dist/`.

### Regola operativa

Il flusso corretto di lavoro è:

1. creare un branch dedicato;
2. modificare codice, test o infrastruttura;
3. aprire una pull request verso `main`;
4. attendere il passaggio dei job CI;
5. mergiare su `main`;
6. avviare manualmente il workflow di deploy solo quando si vuole pubblicare.

In sintesi: la CI protegge l'integrazione del codice, il CD controlla la pubblicazione, Terraform governa l'infrastruttura, e S3 serve l'output statico generato dalla build.

## Checkov

Checkov è utilizzato per eseguire controlli di sicurezza e qualità sulla configurazione Terraform presente in `folder_sito/infra/tf`.

L’obiettivo non è bloccare ogni scelta progettuale del laboratorio, ma rendere esplicite le verifiche IaC, distinguendo tra:

- controlli applicabili anche in ambiente dev;
- controlli non applicabili al contesto dimostrativo;
- regole custom definite dal team.

### Struttura

```text
folder_sito/infra/tf/checkov/
├── baseline/
│   └── checkov.yml
└── checks/
    └── CKV_ACME_OWNER_TAG.yaml
```

### Baseline dev

Il file `checkov/baseline/checkov.yml` contiene la configurazione Checkov utilizzata per l’ambiente di sviluppo.

Include:

* output compatto;
* modalità quiet;
* lista dei controlli esclusi perché non coerenti con il contesto del laboratorio.

La baseline viene usata per evitare falsi positivi su risorse dimostrative, mantenendo comunque attivo il controllo automatico della configurazione Terraform.

### Controlli esclusi

Alcuni controlli AWS sono stati esclusi perché il progetto è eseguito in ambiente dev/test e non rappresenta una configurazione di produzione completa.

| Check                                                  | Ambito                 | Motivazione                                                        |
| ------------------------------------------------------ | ---------------------- | ------------------------------------------------------------------ |
| `CKV_AWS_53`, `CKV_AWS_21`                             | S3 versioning          | Il versioning non è richiesto in dev/test                          |
| `CKV_AWS_54`, `CKV_AWS_55`, `CKV_AWS_56`, `CKV2_AWS_6` | S3 public access block | Il bucket del sito statico deve essere pubblicamente raggiungibile |
| `CKV_AWS_70`, `CKV_AWS_18`                             | Access logging         | Logging non previsto nel perimetro dimostrativo                    |
| `CKV_AWS_119`, `CKV_AWS_6`                             | Encryption             | Cifratura non richiesta per le risorse dimostrative del lab        |
| `CKV2_AWS_62`                                          | Event notifications    | Notifiche eventi non necessarie                                    |
| `CKV2_AWS_61`                                          | Lifecycle rules        | Lifecycle non richiesto in ambiente dev                            |
| `CKV_AWS_144`, `CKV_AWS_145`                           | Replication            | Replica cross-region non prevista nel laboratorio                  |

Queste esclusioni non rappresentano best practice per un ambiente produttivo. In produzione andrebbero rivalutate e, dove necessario, rimosse.

### Regole custom

La cartella `checkov/checks/` contiene controlli custom definiti dal team.

Attualmente è presente la regola:

```text
CKV_ACME_OWNER_TAG
```

Questa policy verifica la presenza del tag `Owner` sulle risorse Terraform, con l’obiettivo di introdurre una convenzione minima di governance e responsabilità sulle risorse cloud.

### Esecuzione locale

Per eseguire Checkov localmente:

```bash
py -m checkov \
  -d folder_sito/infra/tf \
  --config-file folder_sito/infra/tf/checkov/baseline/checkov.yml \
  --external-checks-dir folder_sito/infra/tf/checkov/checks
```

### Integrazione CI

Checkov è integrato nella pipeline GitHub Actions.

A ogni pull request verso `main`, la CI esegue:

1. build e test del sito;
2. `terraform fmt`;
3. `terraform init -backend=false`;
4. `terraform validate`;
5. scan Checkov con baseline dev e policy custom.

Il controllo Checkov non esegue deploy e non modifica risorse AWS. Serve come quality gate per verificare automaticamente la configurazione IaC prima del merge.
