# Gate Matrix

## Scopo

Questa matrice collega i problemi individuati nella baseline `folder_sito_v1` ai controlli che devono essere introdotti nella soluzione `folder_sito_v2`.

Il principio è: un problema corretto solo manualmente può tornare; un problema coperto da gate viene intercettato prima del merge o del deploy.

## Matrice difetto -> controllo

| Difetto baseline | Rischio | Gate previsto | Dove viene controllato | Stato |
|---|---|---|---|---|
| Password e token in file di configurazione | Esposizione credenziali | Secret scanning | CI su pull request | Da fare |
| Deploy manuale con FileZilla | Errore umano, assenza tracciabilità | Workflow di release | GitHub Actions | Da fare |
| Rollback basato su copia locale vecchia | Ripristino incerto | Rollback da SHA/artifact | Workflow o procedura versionata | Da fare |
| Bucket S3 con policy troppo permissiva | Esposizione dati o modifica non autorizzata | Policy as Code | Checkov/custom rule | Da fare |
| Uso manuale della console AWS | Drift e modifiche non tracciate | IaC validation + branch protection | CI + processo PR | Da fare |
| Duplicazione CloudFormation/Terraform | Confusione operativa | Scelta IaC unica | Review + documentazione team | Da fare |
| Assenza test applicativi | Bug non rilevati | `npm test` obbligatorio | CI su pull request | Da fare |
| `totaleOre()` esclude il primo corso | Dato errato pubblicato | Unit test sul totale ore | Test applicativo | Da fare |
| HTML generato con `tdclass` errato | Markup non corretto | Smoke test su HTML generato | Test/build CI | Da fare |
| Dipendenza `left-pad` non usata | Debito tecnico / supply chain inutile | Controllo dipendenze | Review + npm audit opzionale | Da valutare |
| Assenza `package-lock.json` | Build non riproducibile | Uso obbligatorio di `npm ci` | CI | Da fare |
| Nessuna protezione su `main` | Merge o push non controllati | Branch protection | GitHub repository settings | Da fare |
| Nessuna separazione ambienti | Deploy confuso | Variabili per `dev/test/prod` | Team contract + workflow | Da fare |
| Nessuna approvazione produzione | Rilascio non governato | Environment `produzione` con reviewer | GitHub Environments | Da fare |
| Nessuna evidenza di collaudo | Impossibile dimostrare qualità | Smoke test + screenshot/run link | Release checklist | Da fare |

## Gate minimi della prima CI

La prima versione della CI deve almeno bloccare:

- test applicativi falliti;
- build fallita;
- presenza di segreti;
- assenza o incoerenza del lockfile;
- modifiche rischiose non revisionate.

## Gate minimi della parte IaC

Quando la struttura IaC sarà pronta, la CI dovrà bloccare:

- Terraform non formattato;
- Terraform non valido;
- bucket pubblici non giustificati;
- risorse senza tag minimi;
- configurazioni senza protezioni di base;
- segreti nei file `.tf` o `.tfvars`.

## Gate minimi della release

La release deve richiedere:

- CI verde;
- artifact generato;
- approvazione manuale per produzione;
- deploy tracciato;
- smoke test finale;
- possibilità di rollback.

## Evidenze da raccogliere

| Evidenza | Scopo |
|---|---|
| PR bloccata da test fallito | Dimostrare efficacia CI |
| PR bloccata da secret scan | Dimostrare sicurezza |
| PR verde | Dimostrare percorso corretto |
| Screenshot branch protection | Dimostrare governance |
| Run release con approval | Dimostrare controllo produzione |
| Test rollback | Dimostrare resilienza operativa |