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
