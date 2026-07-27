# Roadmap Automation e CI/CD

## Scopo

Questo documento definisce la roadmap operativa per la parte Automation e CI/CD del progetto `folder_sito_v2`.

L'obiettivo non è solo automatizzare il deploy, ma trasformare i problemi trovati nella baseline cliente (`folder_sito_v1`) in controlli permanenti: test, gate, policy, approval e rollback.

## Confine di progetto

| Cartella | Significato |
|---|---|
| `folder_sito_v1` | Stato consegnato dal cliente. Va trattato come baseline di analisi e perizia. |
| `folder_sito_v2` | Soluzione sviluppata dal team. Qui vengono introdotti test, CI/CD, policy e automazione. |

## Responsabilità

| Persona | Area |
|---|---|
| Alessandro | Infrastructure as Code, Terraform, risorse cloud |
| Janice | Infrastruttura, ambienti, configurazioni operative |
| Allaeldene | GitHub Actions, CI/CD, gate, policy, approval, rollback, evidenze |

## Principio guida

Ogni difetto rilevato nella baseline deve produrre almeno uno tra:

- test automatico;
- controllo di sicurezza;
- policy as code;
- gate di pull request;
- procedura di release;
- procedura di rollback;
- evidenza documentabile.

## Fasi operative

### Fase 1 - Allineamento iniziale

- [ ] Confermare che `folder_sito_v1` resta baseline cliente.
- [ ] Confermare che lo sviluppo avviene in `folder_sito_v2`.
- [ ] Definire ruoli e responsabilità del team.
- [ ] Creare matrice difetto -> gate.
- [ ] Definire contratto tecnico con IaC/infrastruttura.

### Fase 2 - Preparazione applicazione v2

- [ ] Portare in `folder_sito_v2` la struttura applicativa necessaria.
- [ ] Rendere il progetto installabile con `npm ci`.
- [ ] Aggiungere `package-lock.json`.
- [ ] Aggiungere script `npm test`.
- [ ] Aggiungere test su calcolo totale ore.
- [ ] Aggiungere test su generazione `dist/index.html`.
- [ ] Aggiungere test su generazione `dist/versione.json`.

### Fase 3 - CI su pull request

- [ ] Creare workflow `.github/workflows/ci.yml`.
- [ ] Eseguire installazione dipendenze.
- [ ] Eseguire test applicativi.
- [ ] Eseguire build.
- [ ] Eseguire secret scanning.
- [ ] Eseguire controlli IaC quando disponibili.
- [ ] Rendere il workflow obbligatorio prima del merge.

### Fase 4 - Security gate

- [ ] Bloccare token, password e chiavi in chiaro.
- [ ] Bloccare file di configurazione sensibili.
- [ ] Verificare che i segreti non entrino in `dist/`.
- [ ] Documentare uso corretto di GitHub Secrets.
- [ ] Documentare variabili richieste per ambienti `dev`, `test`, `prod`.

### Fase 5 - Policy as Code

- [ ] Integrare controlli Terraform.
- [ ] Eseguire `terraform fmt -check`.
- [ ] Eseguire `terraform validate`.
- [ ] Integrare Checkov o controllo equivalente.
- [ ] Bloccare configurazioni S3 troppo permissive.
- [ ] Bloccare risorse senza tag minimi.
- [ ] Bloccare configurazioni prive di protezioni minime.

### Fase 6 - Protezione branch

- [ ] Proteggere `main`.
- [ ] Vietare push diretto su `main`.
- [ ] Richiedere pull request.
- [ ] Richiedere status checks verdi.
- [ ] Richiedere review.
- [ ] Evitare self-approval per produzione.

### Fase 7 - Release e deploy

- [ ] Creare workflow `.github/workflows/release.yml`.
- [ ] Separare build da deploy.
- [ ] Salvare artifact di build.
- [ ] Richiedere approvazione manuale per produzione.
- [ ] Eseguire smoke test dopo deploy.
- [ ] Salvare evidenze del rilascio.

### Fase 8 - Rollback

- [ ] Definire rollback da commit SHA o artifact precedente.
- [ ] Creare procedura manuale o workflow dedicato.
- [ ] Testare rollback.
- [ ] Misurare tempo di ripristino.
- [ ] Documentare MTTR.

## Strategia di branch

| Branch | Uso |
|---|---|
| `main` | Branch stabile e protetto |
| `aladin` | Branch operativo personale |
| `feature/ci-foundation-v2` | Prima base CI/CD |
| `feature/security-gates-v2` | Secret scanning e policy |
| `feature/release-rollback-v2` | Release, approval e rollback |

## Definition of Done

La parte Automation e CI/CD è completata quando:

- ogni pull request esegue controlli automatici;
- i test applicativi intercettano bug reali della baseline;
- i segreti in chiaro bloccano la PR;
- i controlli IaC bloccano configurazioni rischiose;
- `main` è protetto;
- il deploy passa da workflow;
- la produzione richiede approvazione;
- esiste una procedura di rollback dimostrata;
- sono disponibili evidenze per la presentazione finale.