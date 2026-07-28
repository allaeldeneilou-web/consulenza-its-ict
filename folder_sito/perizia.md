# PERIZIA - Portale corsi ITS
Squadra: Verdurina Binario: CFN / Terraform
Data: 27/07/2026

## Sicurezza

### S1 - Il bucket del sito è aperto a chiunque
- **Gravita**: BLOCCANTE
- **Fatto**: nello stato originale la bucket policy consentiva `s3:*` a Principal `"*"`.
- **Conseguenza**: chiunque su internet poteva modificare o cancellare le pagine del portale.
- **Rimedio**: l'attuale configurazione limita la policy a `s3:GetObject` per il website, riducendo l'accesso pubblico a sola lettura invece di scrittura/cancellazione. Un ulteriore miglioramento resta la pubblicazione controllata da pipeline e l'uso di CDN/CloudFront.

### S2 - Configurazione AWS di test/localstack
- **Gravita**: ALTA
- **Fatto**: l'originale utilizzava `access_key`/`secret_key` di test e endpoint Localstack su `127.0.0.1:5000` per S3 e DynamoDB.
- **Conseguenza**: la configurazione non era riproducibile in un ambiente reale e portava il rischio di deploy errati o di esposizione di credenziali di test.
- **Rimedio**: l'attuale `main.tf` usa il provider AWS standard in `us-east-1` e non lascia credenziali di test hardcoded.

## Affidabilita
- A1 - DynamoDB non cifrato e senza recovery nell'originale
  - **Fatto**: l'originale non prevedeva server-side encryption né point-in-time recovery.
  - **Modifica**: l'attuale tabella `iscrizioni` ha `server_side_encryption` abilitato e `point_in_time_recovery` abilitato.
- A2 - Mancanza di separazione degli ambienti nell'originale
  - **Fatto**: l'originale non separava `dev`, `test`, `prod`.
  - **Modifica**: è stato introdotto il `variable "environment"` con validazione e il prefisso dinamico `${local.prefix}` per i nomi delle risorse.

## Costi
- C1 - DynamoDB `PAY_PER_REQUEST`
  - mantenuto per flessibilità e costi variabili.
- C2 - Versioning su S3 in `prod`
  - introdotto nella configurazione attuale; impatto sui costi di storage ma migliora il recupero da errori.

## Operabilita
- O1 - Stato di Terraform non gestito nell'originale
  - **Fatto**: l'originale non definiva un backend.
  - **Modifica**: l'attuale `main.tf` definisce un backend `s3` su `portale-its-tfstate` in `us-east-1`.
- O2 - Output migliorato
  - l'output è ora `sito_url` con `website_endpoint`, più utile per deploy e verifiche.

## Evolvibilita
- E1 - Nomi risorse parametrizzati
  - l'uso di `${local.prefix}` rende il codice riutilizzabile tra `dev`, `test`, `prod`.
- E2 - Tag su DynamoDB
  - aggiunta categorizzazione con `Progetto` e `Ambiente`.


