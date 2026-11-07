# USI Pocket Security 0.2 — iPhone 15

Questo ZIP contiene il progetto aggiornato di Pocket AI e il workflow GitHub. Non contiene un IPA già compilato o il modello GGUF. L’app ha due schede: Chat e Sicurezza; i cinque strumenti funzionano anche senza Qwen.

## 1. Compila e installa da Windows

1. Estrai lo ZIP e apri la cartella PocketAI estratta.
2. Apri il repository GitHub usato per Pocket AI. Se non lo hai ancora creato, creane uno nuovo chiamato PocketAI, anche privato. Non usare il repository My G o ECO.
3. Carica il CONTENUTO: cartella `PocketAI` (sorgenti), `PocketAI.xcodeproj`, `scripts`, `tests`, documenti e licenza. Sostituisci i file omonimi e aggiungi i nuovi; non mettere tutto dentro un’ulteriore cartella contenitore nel repository.
4. Aggiorna anche `.github/workflows/build-ios.yml`. Se Upload non mostra la cartella nascosta, apri il workflow su GitHub e sostituisci tutto il testo con quello del file nello ZIP. Se manca, Add file → Create new file e usa esattamente quel percorso. Non incollare delimitatori Markdown.
5. Commit changes. Nella pagina principale devi vedere `PocketAI`, `scripts`, `tests` e `PocketAI.xcodeproj` allo stesso livello.
6. Actions → **USI Pocket Security - Crea IPA**. Parte al commit su main/master, oppure Run workflow → main → Run workflow.
7. Aspetta il job verde. Il runner macOS compila llama.cpp e l’app, con limite 45 minuti. Valgono le quote/costi GitHub del tuo piano; non servono chiavi AI o credenziali Apple nel repository.
8. Summary → Artifacts → **PocketAI-IPA-da-firmare**. Estrai il download: trovi **PocketAI-unsigned.ipa**.
9. Collega e sblocca iPhone. Trascina l’IPA in Sideloadly e firma con il tuo Apple ID come prima. Per aggiornare Pocket AI usa lo stesso Apple ID e le stesse impostazioni dell’identificativo app. Il bundle sorgente rimane `com.usino.pocketai`.
10. Non disinstallare prima l’app se vuoi conservare chat e modello: la disinstallazione elimina i suoi dati. Verifica che Sideloadly aggiorni l’app esistente. Il nome sotto l’icona sarà **USI Security**.

Non si aggiorna automaticamente al commit GitHub: ogni nuova versione va compilata e reinstallata con Sideloadly. La procedura di rinnovo firma è distinta dall’aggiornamento del codice.

## Uso degli strumenti

| Strumento | Uso e risultato | Limite |
|---|---|---|
| Analizza link | Incolla URL completo → Analizza. Mostra host effettivo e indizi strutturali. | Nessuna apertura, reputazione, redirect o verifica certificato. Nessun verdetto “sicuro”. |
| QR da foto | Scegli un’immagine → legge il testo del QR con Vision. URL ispezionabile separatamente. | Non apre link o Wi-Fi automaticamente. Una lettura non autentica il mittente. |
| SHA-256 | Scegli un file e, se disponibile, incolla l’hash ufficiale del produttore. | Identità del file rispetto al riferimento, non antivirus. Massimo 2 GB. |
| Foto senza metadati | Scegli foto → ricodifica JPEG → controlla assenza dizionari GPS/EXIF → Esporta. | Copia fino a 4096 px; possibili perdita di qualità/HDR/animazione. Dati visibili nell’immagine restano. |
| Rete locale | Inserisci un IPv4 privato noto, seleziona porte, conferma autorizzazione → Avvia. | Un host, massimo sei porte selezionabili, 4 secondi per porta; nessuna autenticazione. |

Il controllo TCP usa gli intervalli privati 10/8, 172.16/12 e 192.168/16. Sono esclusi per prudenza gli indirizzi che terminano in .0 e .255, anche se in alcune reti possono essere host validi. Non accetta nomi DNS, IP pubblici o IPv6. Non identifica automaticamente i dispositivi. Cerca l’indirizzo del tuo accessorio nell’app del produttore o nella pagina dispositivi del tuo router. Una porta aperta non significa vulnerabilità.

Consenti **Rete locale** al primo controllo. Se la richiesta compare durante il timeout, autorizza e ripeti. Background e uscita dalla schermata interrompono il controllo. Un errore può dipendere da firewall, permessi o rete: non dimostra che la porta sia chiusa.

Da Chat puoi usare `/link https://esempio.it`, `/qr`, `/hash`, `/foto`, `/rete`: aprono la schermata corrispondente, senza avviare operazioni. Non occorre caricare Qwen per questi comandi.

Dopo un controllo, **Prepara spiegazione con Qwen** mette un estratto del report nella bozza Chat. Rivedi la bozza, carica Qwen se necessario e premi Invia. Le spiegazioni non sono nuovi controlli e possono essere imprecise. Il modello non riceve le foto o i file originali.

## Dati e condivisione

- I controlli lavorano localmente; solo il controllo TCP effettua connessioni al tuo host scelto. La scelta di file/foto iCloud può richiedere il download Apple.
- Risultati e QR restano nella schermata in memoria, senza archivio automatico. Se mandi un report alla chat, il testo viene salvato nella cronologia locale già prevista dall’app.
- Nel report QR vengono omessi testo generico e credenziali Wi-Fi; il QR completo rimane leggibile nella schermata. Nei report URL sono omessi i valori dei parametri, ma host e nomi dei parametri possono comunque contenere informazioni personali.
- Condividi report o Esporta copia apre il pannello iOS: scegli tu destinatario/app, anche AirDrop se disponibile. Il destinatario deve accettare quando richiesto.
- Le copie JPEG temporanee possono restare nella cache finché iOS non la elimina. L’originale non viene modificato. Questa ricodifica controlla GPS/EXIF e non promette anonimato completo dell’immagine.

## 2. Scarica il modello sul telefono

File previsto ESATTAMENTE: **Qwen3-0.6B-Q8_0.gguf**, dal repository ufficiale Qwen.

Pagina ufficiale:
https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/blob/main/Qwen3-0.6B-Q8_0.gguf

Download:
https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf?download=true

1. Da Safari sull’iPhone apri il download, oppure aprilo dal pulsante nelle impostazioni dell’app.
2. Attendi che il download da circa 639 MB sia completo. Controlla l’app File → Download. Non selezionare il file mentre è ancora in download.
3. Tieni preferibilmente almeno 2 GB liberi per la copia originale e quella interna. È una precauzione pratica, non una misura della RAM utilizzata.
4. Apri USI Pocket Security → **Importa Qwen GGUF** e scegli il file da File.
5. L’app copia il modello, verifica header/dimensione/SHA-256 e poi lo carica in memoria. Attendi **Qwen locale pronto · CPU**.
6. Scrivi una domanda breve, per esempio “Spiegami cos’è un motore elettrico in tre frasi”.
7. Dopo importazione e caricamento puoi provare la chat in modalità aereo. Non vengono inviate richieste di inferenza a un server.

Puoi anche scaricare il GGUF sul PC e trasferirlo in File su iPhone con un metodo a tua scelta; non va importato in Sideloadly e non va caricato su GitHub.

## Uso quotidiano

- Al riavvio il file modello resta sul telefono: premi Carica Qwen per metterlo in RAM.
- Stop interrompe una risposta. Libera memoria conserva il modello ma libera il motore.
- Nuova chat cancella la cronologia dopo conferma; usa questa funzione se il contesto diventa troppo lungo.
- Massimo 1000 caratteri per messaggio, contesto 2048 token, massimo 256 token di risposta. La cronologia recente passata al modello è più corta della cronologia visibile.
- La v0.2 usa CPU con Accelerate; non usa Metal/GPU. Velocità, RAM, batteria e temperatura vanno misurate sul tuo iPhone. Le prestazioni non sono state ancora testate.
- Qwen 0.6B è piccolo: può dare risposte sbagliate o poco precise, anche in italiano. Non è equivalente a un grande modello cloud.

## Limiti e problemi

Non è un antivirus di sistema; non legge altre app, password, messaggi o traffico altrui. Non modifica impostazioni iOS. Non trova la posizione di altri telefoni e non attiva scansioni tramite il modello.

Build rossa: apri il PRIMO step rosso e copia l’errore specifico, oppure scarica l’artifact **PocketAI-log-compilazione**. “Exit code 65” da solo non identifica la causa.

Questo progetto non è stato compilato con Xcode o provato su un iPhone qui. Vedi VERIFICHE.md per distinguere i controlli eseguiti dai test ancora necessari. Non sono garantite prestazioni Qwen, lettura di ogni QR o rimozione di ogni possibile informazione incorporata in un’immagine.
