# My G 2.0 — vicini, segnale e mappa

L’idea: selezioni un dispositivo BLE, osservi come cambia il segnale mentre ti muovi e visualizzi sulla mappa il tuo iPhone con un raggio teorico. Una seconda lista conserva gli accessori aggiunti. Nessuna localizzazione precisa di B e nessun telecomando universale.

## Cosa include

- Elenco BLE con nome disponibile, identificativo locale, RSSI medio, ora e ultima distanza stimata.
- Scheda Segui segnale: aggiorna fino a 10 minuti, segnala perdita dopo 12 secondi senza letture valide, distingue dati fermi da dati recenti.
- Media esponenziale delle letture, limitazione dei duplicati, reset della media dopo perdita del segnale e tendenza più forte/più debole/stabile.
- Modello logaritmico RSSI, riferimento iniziale -59 dBm a un metro e fattore ambiente 2; calibrazione personale facoltativa dopo almeno 8 letture e regolazione del fattore.
- Mappa Apple funzionante senza chiave Google; Google Maps nativo integrato come variante opzionale di compilazione (istruzioni sotto).
- Punto A da Core Location e cerchio RSSI teorico; cerchio grigio per precisione GPS. Se segnale/posizione non sono recenti o la ricerca è ferma, il cerchio RSSI non viene mostrato. Puoi usare BLE anche negando il GPS.
- Lista accessori persistente con marca e modello. Driver reale per sola lettura del servizio standard Battery Service BLE 180F / Battery Level 2A19. Compatibilità verificata al collegamento, percentuale soltanto dopo una lettura valida, disconnessione e timeout.
- Messaggio e firma facoltativa, esportati in .txt con il pannello nativo AirDrop come nella versione 1.
- Logo geometrico originale G/radar, icona iPhone e file SVG/PNG nella cartella Brand.

La ricerca iniziale dura 60 secondi. La scansione si interrompe e le connessioni vengono annullate quando l’app lascia il primo piano. Puoi riavviare manualmente. Le letture del dispositivo connesso seguito possono usare anche readRSSI, ma nessun comando di scrittura viene inviato.

## Aggiorna il repository da Windows

1. Estrai questo ZIP. I file sono direttamente alla radice dell’archivio: non c’è una cartella contenitore aggiuntiva.
2. Nella pagina Code del tuo repository scegli Add file → Upload files.
3. Carica le cartelle `MyG`, `MyG.xcodeproj`, `scripts`, `tests` e `Brand`, e i documenti. Conferma la sostituzione con Commit changes. La nuova cartella MyG contiene ANCHE Assets.xcassets: non ometterla.
4. Sostituisci TUTTO `.github/workflows/build-ios.yml` con il file omonimo contenuto nello ZIP. Se l’upload non include `.github`, apri il file nel repository → matita → seleziona tutto → incolla tutto il nuovo YAML → Commit changes. Non aggiungere i delimitatori ```.
5. La nuova esecuzione si chiama **My G 2 - Crea IPA**. Parte su push a main/master oppure Actions → My G 2 - Crea IPA → Run workflow.
6. Per la prima compilazione lascia **Google Maps disattivato**. Non sono necessari segreti o un account Google.
7. Quando è verde, scarica **MyG-2-IPA-da-firmare**, estrai `MyG-unsigned.ipa` e installalo con Sideloadly usando lo stesso Apple ID e la stessa configurazione del Bundle ID usati per la prima versione. Non disinstallare prima la vecchia app se vuoi conservarne i dati. Verifica che Sideloadly stia aggiornando la stessa identità; se cambia Bundle ID può creare una seconda app.

Il workflow usa checkout v5 e upload-artifact v6 su Node 24, corregge l’ordine di lipo (`lipo "$app/MyG" -verify_arch arm64`) e avvia controlli Swift prima della compilazione. Non contiene credenziali Apple. Il runner macOS e lo spazio artifact sono soggetti alle quote e al piano GitHub del tuo account.

## Google Maps: opzione pronta, non attivata

Il rendering nativo Google è in MapPanel.swift. Non è una pagina web o uno screenshot. Per non richiedere subito fatturazione o chiavi personali, la build predefinita non scarica neppure il relativo SDK e mostra MapKit. Il codice Google viene compilato quando abiliti l’opzione nel workflow.

Prima di abilitarlo, configura tu:

1. Un progetto Google Cloud, account di fatturazione collegato e **Maps SDK for iOS** abilitato.
2. Una chiave con restrizione API **Maps SDK for iOS** e restrizione applicazione iOS per il Bundle Identifier EFFETTIVO dell’app firmata. Sideloadly può modificarlo: controlla il Bundle ID finale; una chiave limitata solo a com.myg.nearby potrebbe non funzionare nella copia firmata.
3. Nel repository GitHub: Settings → Secrets and variables → Actions → New repository secret, nome `GOOGLE_MAPS_API_KEY`, valore la chiave. NON inserirla nei sorgenti o in una chat.
4. Actions → My G 2 - Crea IPA → Run workflow → attiva `google_maps`.
5. Scarica e firma quella build. Nella scheda del dispositivo abilita la posizione e scegli Usa Google Maps; il consenso informa che Google riceve l’area della mappa.

Le build automatiche da push mantengono Google disattivato. Il collegamento al pacchetto Google e il file di configurazione vengono generati solo nel runner se l’opzione è selezionata. Il file con la chiave è ignorato da git, ma è necessariamente contenuto nell’app client risultante: una chiave client non è un segreto inviolabile. Le restrizioni sono essenziali. Non condividere pubblicamente un IPA con la tua chiave.

Al controllo del 6 novembre 2026 il listino Google riporta lo SKU **Maps SDK** con gratuità illimitata. L’SDK richiede comunque account di fatturazione e chiave; altri prodotti (Places, Routes, Street View, Maps JavaScript ecc.) hanno regole/costi distinti. Questa app non li abilita o chiama. Ricontrolla il listino, configura restrizioni e avvisi di budget prima di attivare: un avviso di budget non è un blocco automatico della spesa. Non è stato creato o attivato alcun progetto Google dal lavoro qui svolto.

Dipendenza opzionale fissata: Google Maps iOS SDK 9.4.0 via Swift Package Manager, compatibile con il deployment iOS 16 del progetto. La variante Google e la sua risoluzione SPM devono ancora essere compilate sul tuo runner e provate con chiave valida.

## Accessori: cosa manca per il telecomando

Il pulsante Aggiungi per lettura batteria è disponibile solo per advertising segnalati collegabili. Inserisci marca e modello e conferma l’autorizzazione al collegamento. L’app salva un accessorio **da verificare**, non ne dichiara automaticamente la compatibilità.

Il primo collegamento cerca esclusivamente Battery Service 180F e caratteristica leggibile 2A19. Se mancano o sono protetti, mostra incompatibilità/errore. Non esplora protocolli proprietari e non effettua scritture.

Per accendi/spegni serve il modello concreto e il protocollo documentato dal produttore: servizio UUID, caratteristica, payload, eventuali autenticazione/cifratura. Queste informazioni non sono ancora state fornite. Non sono presenti pulsanti finti o connessioni automatiche a tutti i risultati. Un dispositivo completamente spento non riceve BLE senza circuito alimentato in standby.

## Precisione e dati

RSSI varia per molti motivi e la sua tendenza non prova movimento. Il numero di metri non è una misurazione certificata. Una calibrazione a un metro riduce alcuni errori di riferimento, ma non elimina ostacoli e variazioni ambientali. Non è disponibile una probabilità attendibile del tipo “B è certamente nel cerchio”. Il cerchio non fornisce direzione. La precisione GPS può essere peggiore del raggio BLE.

Scanner e bozza sono in memoria; accessori, calibrazioni, consenso mappe e firma sono nelle preferenze locali. I dati possono rientrare nei backup iOS. Non ci sono server My G, registri GPS persistenti o caricamenti dei dispositivi scoperti. Le mappe contattano Apple/Google per l’area visualizzata; gli identificativi BLE non sono passati ai fornitori dal nostro codice. Il SDK Google può trattare propri dati tecnici secondo la sua documentazione e i termini. Il link Apri A in Google Maps invia soltanto le coordinate di A al servizio esterno.

Il file di testo AirDrop è temporaneo; le copie inviate e le app selezionate dipendono dal destinatario e dal pannello iOS. La firma è dichiarata, non un numero verificato.

## Verifiche e limiti di consegna

Vedi `VERIFICHE.md`. Non sono disponibili Xcode, macOS o un iPhone collegato in questo ambiente: NON dichiariamo una compilazione v2 riuscita o una prova radio effettuata. La prima esecuzione del nuovo workflow compilerà codice e test Swift. Non è stato effettuato un push sul tuo repository da questa sessione.

## Fonti ufficiali

- Google: https://developers.google.com/maps/documentation/ios-sdk/config
- Chiavi: https://developers.google.com/maps/documentation/ios-sdk/get-api-key
- Restrizioni: https://developers.google.com/maps/api-security-best-practices
- Prezzi: https://developers.google.com/maps/billing-and-pricing/pricing
- Location: https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization()
- Core Bluetooth: https://developer.apple.com/documentation/corebluetooth
- Artifact: https://github.com/actions/upload-artifact/releases
