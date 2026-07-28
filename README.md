# Perizia tecnica - Portale ITS

## Flusso di build e deploy

Il sito è generato staticamente tramite `src/build.mjs`, uno script Node.js senza dipendenze esterne.

### Ordine delle operazioni

1. **Build** — eseguire lo script prima del deploy:
   ```bash
   node src/build.mjs
   ```
   Lo script legge `data/corsi.json`, genera `dist/index.html` e copia `site/style.css` in `dist/style.css`.

2. **Deploy** — applicare l'infrastruttura Terraform:
   ```bash
   cd data/infra/tf
   terraform apply
   ```
   La risorsa `aws_s3_object "index"` carica `dist/index.html` nel bucket S3 come `index.html`, che è l'entry point configurato in `aws_s3_bucket_website_configuration`.

### Perché non caricare `build.mjs` direttamente

`build.mjs` è uno script di build lato server, non un file servibile dal browser. Il bucket S3 è configurato come static website hosting e si aspetta un file `index.html` come documento principale. Caricare lo script JS non avrebbe prodotto un sito funzionante.

Il contenuto corretto da pubblicare è l'output della build (`dist/index.html`), che contiene l'HTML completo generato a partire dai dati in `data/corsi.json`.

-------------------------------------------------------------------------------------

# CHECKOV

Baseline (checkov.yml)
Contiene:

configurazione output (compact, quiet)

lista dei controlli da ignorare

Utilizzata per:

ambiente dev

risorse dimostrative

static website S3 pubblico

Controlli skippati:

CKV_AWS_53 → S3 versioning

CKV_AWS_54 → block public ACLs

CKV_AWS_55 → block public policies

CKV_AWS_56 → restrict public buckets

CKV_AWS_70 → access logging

CKV_AWS_119 → encryption

CKV2_AWS_62 → event notifications

CKV2_AWS_61 → lifecycle rules

CKV_AWS_18 → access logging

CKV_AWS_6 → encryption

CKV_AWS_144 → cross‑region replication

CKV_AWS_145 → replication configuration

Motivazioni:

il bucket S3 del sito statico deve essere pubblico

logging, lifecycle e replication non richiesti in dev

alcune risorse sono di stima o dimostrative

il Learner Lab non permette IAM roles
Baseline (checkov.yml)
Contiene:

configurazione output (compact, quiet)

lista dei controlli da ignorare

Utilizzata per:

ambiente dev

risorse dimostrative

static website S3 pubblico

Controlli skippati:

CKV_AWS_53 → S3 versioning

CKV_AWS_54 → block public ACLs

CKV_AWS_55 → block public policies

CKV_AWS_56 → restrict public buckets

CKV_AWS_70 → access logging

CKV_AWS_119 → encryption

CKV2_AWS_62 → event notifications

CKV2_AWS_61 → lifecycle rules

CKV_AWS_18 → access logging

CKV_AWS_6 → encryption

CKV_AWS_144 → cross‑region replication

CKV_AWS_145 → replication configuration

CKV_AWS_6 → S3 bucket should have encryption enabled

CKV_AWS_21 → S3 bucket should have versioning enabled
Motivo: il versioning è abilitato solo in produzione, non in dev e test, per ridurre complessità e costi.

Motivazioni:

il bucket S3 del sito statico deve essere pubblico

logging, lifecycle e replication non richiesti in dev

alcune risorse sono di stima o dimostrative

il Learner Lab non permette IAM roles