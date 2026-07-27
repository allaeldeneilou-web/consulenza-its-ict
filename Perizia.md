Migrazione su Cloud -> Github:
- Rollback su copia precedente
- Accesso da ovunque per lavorare
- implementazione pipleine
- crezione gate per il deploy

Protezione dati sensibili:
- Eliminare chiavi in chiaro(config/impostazioni.txt)
- Implementazione session token

modifiche IaaC

Solo terraform come Iaac

S3 bucket:
- aggiornare polcy, sicurezza e attivare web hosting deletion
- aggiungere sezione resource per upload di index.html

Dynamodb:
- implementare protezione

Creare due ambienti separati dev-test-prod

------------------------------------------------------------------------------------------------
TERRAFORM
# s3 bucket
FATTO
  La bucket policy consente s3:* a Principal "*".

CONSEGUENZA
  Chiunque su internet puo modificare o
  cancellare le pagine del portale.

RIMEDIO
  Togliere la policy pubblica, riattivare il
  blocco degli accessi pubblici, pubblicare
  solo dalla pipeline.
 
 FATTO
    Le policy su block_public_access non sono attive

------------------------

CONSEGUENZA
    Chiunque può accedere al bucket

RIMEDIO
    Attivare (true) tutte le policy
    - Bloccare ACL pubblici
    - Bloccare policy pubbliche
    - Ignorare accessi pubblici
    - Bloccare la creazione di bucket pubblici

# Dynamo

FATTO
    Credenziali hardcodate di github

CONSEGUENZA
    Chiunque può usarlo per accedere

RIMEDIO
    Rimuovere credenziali dal codice e gestirle con AWS Secrets Manager
-------------------------
FATTO
    Point in time recovery non attivo
    
CONSEGUENZA
    In caso di cancellazione non c'è modo di ripristinarla

RIMEDIO
    Attivare il point in tim recovery
    point_in_time_recovery {
        enabled = true
            }
---------------------------    
