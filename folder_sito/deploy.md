# Deploy - Portale ITS

## Prerequisiti

- Node.js installato
- Terraform installato
- Credenziali AWS configurate (`aws configure`)

## Workflow

### 1. Aggiornare i dati

Modificare `data/corsi.json` con le nuove informazioni sui corsi.

### 2. Build

```bash
node src/build.mjs
```

Genera `dist/index.html` a partire da `data/corsi.json`.

### 3. Init Terraform (solo al primo deploy o quando si cambia ambiente)

```bash
cd infra/tf
terraform init -reconfigure -backend-config="key=portale-its/<ambiente>/terraform.tfstate"
```

Sostituire `<ambiente>` con `dev`, `test` o `prod`.

### 4. Deploy

```bash
terraform apply -var="environment=<ambiente>"
```

Terraform carica `dist/index.html` nel bucket S3 e applica l'infrastruttura.

### 5. Verifica

L'URL del sito viene stampato a fine apply come output `sito_url`.

## Rollback

Il bucket S3 ha il versioning abilitato in `prod`. Per ripristinare una versione precedente di `index.html`:

1. Aprire la console AWS → S3 → `portale-its-prod-sito`
2. Selezionare `index.html` → tab **Versioni**
3. Ripristinare la versione desiderata

## Destroy

Per eliminare le risorse di un ambiente:

```bash
terraform init -reconfigure -backend-config="key=portale-its/<ambiente>/terraform.tfstate"
terraform destroy -var="environment=<ambiente>"
```

### Generazione file sito

# Posizionarsi in folder_sito e runnare `npm run build`

Il file `index.html` viene generato a partire da `data/corsi.json` tramite lo script `src/build.mjs`. Lo script legge i dati dei corsi e li trasforma in HTML statico, pronto per essere servito dal bucket S3.

# Caricamento file aggiornati:
- posizionarsi in folder_sito e runnare il seguente comando inserendo al posto di <ambiente> l'ambiente su cui si sta lavorando test - dev - prod

`aws s3 sync dist/ s3://portale-its-<ambiente>-sito --delete`
