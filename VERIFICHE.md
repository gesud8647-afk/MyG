# Verifiche My G 2

## Eseguite nell’ambiente di consegna

- Sintassi shell del build script e parsing YAML del workflow.
- Generazione deterministica del progetto Xcode, unicità/riferimenti oggetti, presenza di ogni file sorgente/risorsa e destinazione schema.
- Parsing plist permessi, privacy manifest e asset catalog; icona opaca RGB 1024 × 1024 e controllo visivo logo.
- Configurazione senza Google: nessuna chiave e nessuna dipendenza SDK.
- Configurazione Google richiesta senza chiave: fallimento esplicito prima della compilazione.
- Configurazione Google con valore fittizio di prova: creazione riferimenti SPM e risorsa ignorata; ripristino senza Google e nessuna chiave nel pacchetto consegnato.
- Validatore IPA: accetta una fixture iPhoneOS e respinge una fixture simulatore. Le fixture NON sono app compilate/installabili e non sono incluse.
- Integrità ZIP finale.

## Da eseguire nel workflow macOS

Il job compila ed esegue tests/SignalChecks/main.swift con il vero SignalMath.swift, poi compila l’app per iphoneos arm64. I controlli verificano riferimento a 1 m, monotonicità del modello, rifiuto RSSI non disponibile/NaN e parametri non validi, limitazione burst, tendenza e reset dopo interruzione.

Questi test Swift sono inclusi ma non eseguiti qui: il compilatore Swift/Xcode non è disponibile. Anche la variante Google necessita di esecuzione sul runner, risoluzione del pacchetto e chiave valida.

## Prove indispensabili sul tuo iPhone

1. Aggiornamento v1 con stessa identità Sideloadly; nuova icona e 4 schede.
2. Bluetooth autorizzato/negato/spento, nessun dispositivo, periferica rilevabile.
3. Letture duplicate non generano righe duplicate; RSSI cambia e ultimo rilevamento si aggiorna.
4. Segui segnale: avvicinamento/allontanamento reale confrontato con variazioni; verificare stabilità e non interpretare la tendenza come prova di movimento.
5. Dopo 12 secondi senza RSSI valido: segnale perso, nessuna tendenza attiva e cerchio nascosto. Ripresa: media riparte.
6. Ferma ricerca: valori etichettati dati fermi, cerchio nascosto; nessun aggiornamento RSSI fino al riavvio.
7. Calibrazione ad almeno 1 m misurato fisicamente, con 8 letture recenti; reset e persistenza dopo riavvio.
8. GPS autorizzato/negato/posizione approssimativa/revocata; BLE funziona anche senza mappa. Controllare timestamp e precisione GPS.
9. Mappa Apple: A, cerchio RSSI verde solo recente/attivo, incertezza GPS grigia, Centra A e pan/zoom.
10. Google opzionale: build manuale con secret, Bundle ID firmato autorizzato, consenso, rendering/attribuzioni visibili, cerchi e chiave non valida. Le mappe potrebbero risultare vuote se la configurazione Google è errata; ripassare a mappa Apple.
11. Accessorio Battery Service reale: inserimento marca/modello, connessione, lettura 0–100%, aggiornamento, scollegamento, timeout, servizio assente e perdita radio. Nessuna percentuale finta e nessun comando power.
12. Background e blocco schermo: stop scansione/connessioni; ritorno in primo piano richiede riavvio manuale della ricerca/posizione.
13. AirDrop: Unicode, firma opzionale, annullamento e ricezione file su secondo dispositivo.
14. Rimozione accessorio e cancellazione calibrazioni, consenso mappe revocato, testi leggibili con carattere grande/VoiceOver.

Non è un localizzatore di precisione. I test statici non sostituiscono le prove hardware.
