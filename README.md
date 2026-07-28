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