# My G — da Windows a iPhone con GitHub Actions e 3uTools

Questo pacchetto aggiunge al progetto iOS la compilazione su un runner macOS GitHub. Non serve possedere un Mac. Non include ancora un IPA compilato: lo genera una esecuzione riuscita del workflow.

## 1. Crea il repository da Windows

1. Estrai lo ZIP. Apri la cartella `MyG` estratta.
2. Su https://github.com/new crea un repository chiamato `my-g-ios`. Puoi scegliere Private. Inizializzalo con un README per avere il ramo principale.
3. Nel repository scegli Add file → Upload files.
4. Trascina il contenuto della cartella `MyG`, non la cartella contenitore e non lo ZIP. Carica `MyG` (sorgenti), `MyG.xcodeproj`, `scripts`, `.github` e i documenti. Conferma con Commit changes.
5. Controlla che nella pagina principale ci siano `MyG.xcodeproj` e `scripts`, e che esista `.github/workflows/build-ios.yml`.

IMPORTANTE: se l’upload del browser omette la cartella `.github`, crea il workflow così:

- Nel repository premi Add file → Create new file.
- Come nome scrivi esattamente `.github/workflows/build-ios.yml`.
- Apri con Blocco note il file `.github/workflows/build-ios.yml` incluso nello ZIP e incollane TUTTO il contenuto nell’editor GitHub.
- Conferma con Commit changes sul ramo principale.

Non caricare password, certificati Apple o dati personali nel repository. Il workflow non necessita di segreti Apple.

## 2. Genera l’IPA

1. Apri la scheda Actions del repository. Se GitHub lo richiede, abilita i workflow.
2. Scegli **Compila My G per 3uTools**.
3. Premi Run workflow → Run workflow sul ramo principale.
4. Apri l’esecuzione e attendi il completamento con esito verde.
5. Nella sezione Artifacts scarica **MyG-IPA-da-firmare**.
6. Estrai lo ZIP dell’artifact: al suo interno trovi **MyG-unsigned.ipa**.

Il workflow parte solo manualmente. Il runner è `macos-15`, compila per iPhone fisico arm64 e conserva l’artifact per 7 giorni. La disponibilità delle esecuzioni e gli eventuali costi dipendono dal piano, dal repository e dalle quote del tuo account GitHub; controllali prima di avviare il job.

Se compare rosso, scarica l’artifact **MyG-log-compilazione** oppure apri il passaggio fallito. Il progetto non è stato ancora compilato in questo ambiente: il primo job GitHub è la prima verifica Xcode effettiva.

## 3. Firma e installa con 3uTools sul PC

1. Collega l’iPhone via USB, sbloccalo e autorizza il computer.
2. Apri 3uTools → Toolbox → IPA Signature.
3. Aggiungi **MyG-unsigned.ipa**, non lo ZIP scaricato da GitHub.
4. Scegli la firma con Apple ID o con un certificato/profilo validi per il dispositivo, secondo le opzioni disponibili nella tua versione di 3uTools.
5. Completa la firma nel programma. Non inviare le credenziali nella chat o su GitHub.
6. Usa Open Signed IPA Location e installa l’IPA firmato tramite 3uTools.
7. Se iOS lo richiede, abilita Modalità sviluppatore in Impostazioni → Privacy e sicurezza e autorizza il profilo di sviluppo in Impostazioni → Generali → VPN e gestione dispositivo.

Il file generato è un IPA non firmato: NON è installabile prima della firma. La firma può richiedere rinnovi; disponibilità e compatibilità della funzione di 3uTools con account e versione iOS non sono garantite da questo progetto. Se fallisce, conserva il testo esatto dell’errore per la diagnosi. Non occorre jailbreak.

## Cosa fa l’app

Scansione BLE in primo piano, nome/identificativo locale/RSSI/ultimo rilevamento, bozza e firma facoltativa, file di testo condivisibile dal pannello Apple. Il dispositivo selezionato nello scanner non viene automaticamente collegato a un destinatario AirDrop. Il destinatario va scelto nel pannello Apple e deve poter accettare la condivisione. Nessuna verifica del numero, SMS o chat diretta implementata.

## Verifiche già effettuate

Controllo sintassi bash, parsing workflow, riferimenti del progetto, plist/schema e integrità archivio. Il validatore IPA controlla struttura e piattaforma, non firma o possibilità di installazione. Mancano esecuzione GitHub/Xcode, firma 3uTools e prova su iPhone.

Per dettagli sull’app e sui dati: `LEGGIMI.md`.

## Fonti ufficiali

- Workflow e runner: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- Artifact: https://docs.github.com/en/actions/tutorials/store-and-share-data
- Firma 3uTools: https://www.3u.com/tutorial/articles/10212/
- Firma e distribuzione Apple: https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices
