# Aggiornamento 0.3.1 — Azioni assistente

Nuova scheda Azioni: apertura WhatsApp, preparazione messaggio a numero internazionale, destinazione Mappe e avvio confermato di un Comando Rapido già installato. Puoi dettare le richieste esatte elencate nella schermata; dopo la trascrizione premi Invia. I campi vengono compilati da te, non automaticamente dall’AI. Il testo del messaggio non viene inviato automaticamente.

Per Comandi Rapidi: crea il comando nell’app Apple, assegna un nome, copia quel nome nel campo della scheda Azioni. L’app ricorda il nome e può avviare il comando con un testo di input facoltativo. Il comando deve essere configurato per accettare quell’input. Qwen può fornire istruzioni, non creare/installare silenziosamente il comando. Verifica le azioni del comando prima dell’avvio.

Non include ancora il selettore Qwen1.7B, importazione documenti o confronto di due fonti: il modello supportato rimane lo 0.6B. Non vengono simulate capacità di controllo del sistema iOS. La lettura automatica delle risposte è già disponibile nelle impostazioni Chat. Le azioni mostrano un’anteprima nei campi e richiedono il pulsante di conferma; non è un dialogo vocale autonomo che raccoglie tutti i parametri.

Aggiorna l’intero progetto e compila come descritto sotto. Versione effettiva 0.3.1/build5; stesso bundle ID. Nuova build Xcode e apertura delle tre app da verificare sul dispositivo.

# USI Pocket Security 0.3 — Web, voce, crypto e calcoli

Il progetto contiene la chat Qwen locale e le schede Sicurezza e Web. Il modello rimane Qwen3-0.6B Q8_0: Internet aggiunge informazioni e gli strumenti aggiungono capacità precise, ma non aumentano i parametri o l’intelligenza generale del modello.

## Aggiorna da Windows

1. Estrai lo ZIP, apri la cartella PocketAI esterna e carica il suo CONTENUTO nel repository che usi già per Pocket Security, sostituendo i file omonimi e aggiungendo i nuovi.
2. Alla radice del repository devono esserci la cartella sorgenti `PocketAI`, `PocketAI.xcodeproj`, `scripts` e `tests`. Non aggiungere un’altra cartella contenitore.
3. Includi `.github/workflows/build-ios.yml`. Se il browser non la mostra, apri quel percorso su GitHub e sostituisci il contenuto con il file nello ZIP. Se manca, Add file → Create new file e usa quel percorso esatto.
4. Commit changes → Actions → **USI Pocket Security - Crea IPA**. In alternativa Run workflow sul branch aggiornato. Il workflow mantiene macos-15 e il fix del linker Vendor.
5. Attendi il verde → Summary → Artifacts → **PocketAI-IPA-da-firmare**. Estrai **PocketAI-unsigned.ipa**.
6. Installa con Sideloadly usando stesso Apple ID e impostazioni dell’identificativo già usate. Non disinstallare prima l’app se vuoi conservare chat e GGUF.
7. Nome sotto l’icona: USI Security. Versione 0.3, build 4; bundle ID sorgente sempre `com.usino.pocketai`.

Lo ZIP contiene sorgenti, non un IPA già compilato. Il GGUF è separato; se già importato e aggiornamento eseguito sulla stessa app, non va riscaricato. GitHub non aggiorna automaticamente l’app installata: servono compilazione e Sideloadly. Quote e costi runner dipendono dal tuo piano GitHub.

## Prezzi aggiornati in chat

Scrivi o detta una singola richiesta:

- “Quanto vale BTC in euro?”
- “Prezzo Ethereum in dollari”
- `/prezzo SOL EUR`

Asset supportati in questa versione: BTC, ETH, SOL, AVAX, DOGE. Valute: EUR e USD, con EUR predefinito. Per una richiesta riconosciuta l’app invia soltanto la coppia a Coinbase Spot, senza la cronologia. Mostra importo ricevuto, link alla fonte e ora di ricezione. Non è un flusso continuo: invia di nuovo la richiesta per aggiornare. L’ora indica la ricezione dell’app, non un timestamp di mercato fornito dalla risposta API.

Funziona anche senza Qwen caricato. La quotazione non viene riscritta dal modello. Errori, timeout, rete assente, asset non riconosciuti o richieste ambigue non producono un prezzo inventato: viene mostrato un messaggio. La copertura in linguaggio naturale è semplice, non universale. Per altri prezzi usa il browser.

In ingranaggio → Internet e voce puoi disattivare **Prezzi crypto online**. Questo non disabilita il browser né i link esterni. L’API pubblica documentata non richiede credenziali nel codice; disponibilità e limiti del servizio possono cambiare. Nessun servizio AI a pagamento è attivato.

## Cercare su Internet e far leggere una fonte a Qwen

1. Apri **Web**, oppure dalla chat invia `/cerca notizie di oggi ad Alba`.
2. Inserisci una ricerca (DuckDuckGo) o un indirizzo completo HTTPS e premi Vai.
3. Apri la pagina che vuoi consultare. Puoi selezionare il passaggio pertinente nella pagina.
4. Premi **Leggi testo per Qwen**. Se hai selezionato testo, viene preferito; altrimenti viene preso l’inizio del testo della pagina.
5. Rivedi/modifica l’estratto (massimo 1200 caratteri) e premi **Allega alla prossima domanda**.
6. In Chat carica Qwen, scrivi la domanda, per esempio “Riassumi questi fatti e indica cosa non è confermato”, e invia.

La risposta mostra il collegamento alla pagina scelta e quando l’hai letta. Il link indica la fonte allegata, non dimostra che ogni frase del modello sia supportata. Non è ricerca autonoma illimitata: Qwen non apre da solo pagine o tutti i risultati. Alcuni siti, paywall e documenti non sono leggibili; per testi lunghi seleziona un estratto preciso. I link nelle risposte aprono il browser scelto da iOS; la scheda Web è un browser interno separato.

La sessione Web usa dati non persistenti e non importa la sessione/cookie di Safari o di altre app. I siti e il motore di ricerca ricevono le normali richieste Internet. Non allegare password o dati di account: la schermata di anteprima permette di rimuoverli. Il testo della pagina è trattato come contenuto non attendibile, senza strumenti di esecuzione collegati al modello.

## Conversazione a voce

1. In Chat premi **Parla** e consenti microfono e riconoscimento vocale quando iOS li richiede.
2. Detta in italiano. Il testo compare nella bozza; premi **Ferma dettatura** oppure attendi la fine (limite 45 secondi).
3. Rivedi la trascrizione e premi Invia: può essere una domanda, una richiesta prezzo o un comando.
4. Tocca **Ascolta** sotto una risposta per sentirla. **Ferma voce** interrompe la lettura.
5. Per ascoltare ogni risposta nuova: ingranaggio → **Leggi automaticamente le risposte**.

La dettatura preferisce il riconoscimento locale italiano di iOS. Se il telefono non lo supporta/non è disponibile, l’app non invia automaticamente l’audio a un server: puoi consentire il servizio Apple online nelle impostazioni dell’app. Questo comporta possibile elaborazione dell’audio da Apple. Anche senza tale opzione restano necessarie le autorizzazioni iOS. Nessuna registrazione audio è salvata dall’app; il testo inviato viene salvato nella cronologia.

Il microfono non resta in ascolto in background. Uscita dalla Chat, background e interruzioni audio fermano voce/dettatura. Non c’è parola di attivazione o conversazione continua automatica. La lettura usa le voci italiane disponibili su iOS; disponibilità e qualità dipendono dal dispositivo. Se rifiuti i permessi puoi continuare con la tastiera.

## Calcoli e logica

- `/calcola 7*8` → calcolo numerico eseguito dal codice.
- `/calcola 10000*(1+0,06)^30` → formula di interesse composto a capitalizzazione annuale (esempio matematico).
- Operatori: +, -, *, /, ^, parentesi; virgola o punto decimale; massimo 160 caratteri. Non interpreta automaticamente tassi, unità o percentuali da frasi: scrivi la formula.
- Il calcolatore non esegue JavaScript/codice. Rifiuta divisione per zero, caratteri non ammessi, valori non finiti e formule incomplete. Precisione Double, risultato visualizzato fino a 12 cifre significative; non è un motore di contabilità o algebra simbolica.
- **Approfondisci** richiede risposta, breve metodo verificabile e limiti, fino a 384 token anziché 256. Non cambia modello né garantisce ragionamento migliore. Richiede Qwen caricato e può essere più lento.
- **Usa messaggi precedenti** attiva il contesto recente per conversare. Una nuova installazione lo propone acceso; un aggiornamento conserva la tua scelta precedente, anche se era spento nella 0.2.1. Se vuoi riferimenti ai messaggi prima, controlla l’interruttore nell’ingranaggio. Il contesto rimane breve, non memoria illimitata.

## Sicurezza già inclusa

Analisi locale URL, QR da foto, SHA-256 a blocchi, copie JPEG con controllo assenza GPS/EXIF, connessioni TCP a un singolo IPv4 privato autorizzato. Comandi: `/link URL`, `/qr`, `/hash`, `/foto`, `/rete`. Funzionano senza Qwen. Le azioni richiedono i pulsanti delle schermate; le risposte del modello non le eseguono.

Condividi report ed Esporta copia usano il pannello iOS, anche AirDrop se disponibile e accettato dal destinatario. Non è antivirus di sistema e non localizza altri telefoni. Una porta raggiungibile non dimostra una vulnerabilità. Le copie foto possono perdere qualità/HDR/animazione e restare temporaneamente in cache; non rimuovono i dati visibili nell’immagine.

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
- Massimo 1000 caratteri per messaggio, contesto 2048 token, massimo 256 token di risposta, o 384 con Approfondisci. La cronologia recente passata al modello è più corta della cronologia visibile.
- La v0.3 usa CPU con Accelerate; non usa Metal/GPU. Velocità, RAM, batteria e temperatura vanno misurate sul tuo iPhone. Le prestazioni non sono state ancora testate.
- Qwen 0.6B è piccolo: può dare risposte sbagliate o poco precise, anche in italiano. Non è equivalente a un grande modello cloud.

## Dati, limiti e verifiche

Chat e link alle fonti ricevute sono salvati localmente nell’ultima cronologia, fino a 50 messaggi, e possono rientrare nei backup iOS. La fonte in attesa e il suo estratto restano in memoria; il modello può ripeterne parti nella risposta salvata. Il GGUF copiato è escluso dai backup. File/foto iCloud possono essere scaricati dal selettore Apple.

Qui sono stati verificati struttura progetto, permessi, script e risposta live JSON dell’endpoint BTC-EUR. Non disponibili Xcode/Swift o un iPhone collegato: nuova compilazione, test Swift aggiunti, browser, riconoscimento/lettura voce e comportamento del modello restano da verificare su GitHub e sul dispositivo. Vedi VERIFICHE.md. Nessuna misura di prestazioni o miglioramento del ragionamento è dichiarata.

Se Actions è rosso, apri il primo step rosso e copia l’errore preciso o scarica PocketAI-log-compilazione. “Exit code 65” da solo non identifica il problema. I test già passati nella 0.2 non sostituiscono quelli della nuova versione.

## Documentazione tecnica consultata

- Coinbase Spot: https://docs.cdp.coinbase.com/coinbase-app/track-apis/prices
- Apple Speech: https://developer.apple.com/documentation/speech/recognizing-speech-in-live-audio
- Riconoscimento locale: https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition
