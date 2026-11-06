# My G — app iOS

Per compilare senza un Mac di proprietà, segui prima `README.md`: include il percorso GitHub Actions → IPA non firmato → firma 3uTools. Le istruzioni Mac sotto restano una alternativa.

App nativa SwiftUI per iPhone, iOS 16 o successivo. Nessun server, account o dipendenza esterna.

## Funzioni implementate

- Scansione reale delle periferiche Bluetooth Low Energy che trasmettono advertising rilevabile.
- Nome disponibile, identificativo Core Bluetooth locale, RSSI e ultimo segnale ricevuto.
- Filtro per nome e selezione di un risultato come riferimento visivo.
- Messaggio libero e firma/numero facoltativo dichiarato dal mittente.
- Esportazione UTF-8 in un file .txt e apertura del pannello nativo di condivisione, da cui scegliere AirDrop.
- Gestione Bluetooth spento, autorizzazione negata e hardware non supportato.
- Arresto dopo 60 secondi o quando l’app lascia il primo piano. Riavvio manuale.

Il destinatario AirDrop va scelto nel pannello Apple. Il risultato selezionato nello scanner NON viene associato al destinatario e non viene incluso nel file. Non sono implementati invio diretto BLE, SMS, verifica del numero o chat tra due installazioni.

## Installazione sul tuo iPhone

Questo ZIP contiene il progetto sorgente, non un’app già firmata o un IPA installabile. Non si può avviare aprendo lo ZIP in File su iPhone.

1. Su un Mac con una versione di Xcode compatibile con il tuo iPhone, estrai lo ZIP.
2. Apri `MyG.xcodeproj`.
3. Seleziona il target MyG → Signing & Capabilities. Scegli il tuo Team Apple e un Bundle Identifier univoco, ad esempio `it.tuonome.myg`.
4. Collega e autorizza l’iPhone, poi selezionalo come destinazione. Se richiesto da iOS, abilita Modalità sviluppatore in Impostazioni → Privacy e sicurezza e completa il riavvio.
5. Premi Run. Al primo Avvia scansione, autorizza il Bluetooth.

La firma con un Personal Team può avere limitazioni e richiedere rinnovi. Per una distribuzione tramite TestFlight servono gli strumenti e l’account Apple previsti da quel canale.

## Uso

1. Attiva Bluetooth e tocca Avvia scansione.
2. Un dispositivo BLE acceso che trasmette advertising è utile per la prova. Un normale iPhone vicino potrebbe non comparire.
3. Seleziona facoltativamente un risultato per visualizzarne il riferimento.
4. Scrivi il messaggio. Se inserisci il tuo numero nella firma sarà visibile al destinatario; non viene verificato e non è un SMS.
5. Tocca Condividi → AirDrop. Nel pannello Apple scegli AirDrop e il destinatario riconosciuto. Su entrambi i dispositivi devono essere disponibili Wi-Fi, Bluetooth e impostazioni AirDrop compatibili con la ricezione.
6. Il destinatario accetta il file di testo. La disponibilità di AirDrop e i destinatari sono gestiti da iOS.

## Dati e limiti

Elenco dispositivi e bozza restano in memoria e si perdono alla chiusura del processo. La firma è salvata nelle preferenze dell’app; Elimina firma e bozza la cancella. Nessun dato è caricato su un server dall’app. Preferenze e dati dell’app possono essere inclusi nei backup gestiti da iOS secondo le impostazioni del dispositivo.

Il file per la condivisione è temporaneo e rimane nella sandbox finché iOS lo rimuove o una condivisione successiva lo sostituisce. Le copie inviate dipendono dal destinatario e dal servizio scelto.

RSSI non equivale a distanza o direzione. Un risultato può essere vecchio: controlla Ultimo segnale. Gli identificativi Core Bluetooth non sono numeri di telefono o indirizzi MAC; i nomi non provano l’identità. La scansione BLE non costituisce un elenco completo dei dispositivi vicini e non rivela i destinatari AirDrop. Non vengono effettuati collegamenti ai dispositivi rilevati.

## Verifica

In questo ambiente non sono disponibili macOS, Xcode o un iPhone collegato: compilazione, firma e prove radio/AirDrop non sono state eseguite. Sono stati controllati struttura del progetto, riferimenti ai file, plist, schema e archivio. Le prove sul dispositivo sono necessarie prima di considerare l’app verificata.

Su Mac, per verificare la compilazione senza firma:

```sh
xcodebuild -project MyG.xcodeproj -scheme MyG -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Il simulatore serve per l’interfaccia; BLE e AirDrop vanno verificati su iPhone fisici.

Prove manuali consigliate: autorizzazione accettata/negata; Bluetooth spento; scansione con periferica BLE; aggiornamento RSSI/ora senza righe duplicate; arresto manuale/60 secondi/background; messaggio vuoto bloccato; file con testo Unicode e firma; annullamento condivisione; ricezione AirDrop su secondo dispositivo; firma cancellata dopo riavvio.

## Fonti Apple

- Core Bluetooth: https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/scanforperipherals(withservices:options:)
- Condivisione: https://developer.apple.com/documentation/uikit/uiactivityviewcontroller
- AirDrop: https://support.apple.com/it-it/119857
- Sicurezza AirDrop: https://support.apple.com/it-it/guide/security/sec2261183f4/web
