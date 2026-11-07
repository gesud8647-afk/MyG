# Verifiche — Pocket Security 0.2

## Eseguito nell’ambiente di sviluppo

- Generazione progetto Xcode con tutti i sorgenti, unicità/riferimenti degli oggetti, plist e schema XML.
- Versione 0.2/build 2 e descrizione Rete locale nel plist generato.
- Parsing workflow (trigger push e workflow_dispatch, job macos-15), sintassi degli script Bash e Python.
- Validatore IPA con fixture dispositivo e rifiuto fixture simulatore; integrità ZIP sorgente.
- Revisione percorsi: nessuna apertura URL/QR, nessun invio automatico al modello; controllo TCP limitato a indirizzo privato e porte scelte; nessun tentativo di autenticazione.
- Il bridge C++ invariato era già stato controllato con g++ contro gli header reali del commit llama.cpp fissato. Questo non prova il linking o l’inferenza.

## Incluso nel workflow, da eseguire su GitHub

- Swift: test precedenti ChatML/storia/think e nuovi casi limite per host con credenziali, omissione valori query, IPv4 privati/pubblici/ambigui, hash e comandi espliciti.
- Compilazione motore CPU arm64 contro SDK iPhone, bridge clang, intera app SwiftUI e collegamento.
- Verifica architettura arm64 e struttura IPA. La firma rimane esterna.

Non disponibili qui Swift/Xcode/macOS o iPhone collegato: i test Swift e la compilazione iOS NON sono stati eseguiti localmente. Il modello GGUF reale non è stato eseguito. Non misurati RAM, velocità, batteria o temperatura.

## Prove sul tuo iPhone

1. Aggiornamento con stesso account/identificativo Sideloadly, mantenimento chat e GGUF, avvio di entrambe le schede.
2. Senza caricare Qwen: tutti i comandi espliciti aprono strumenti; testo libero non viene interpretato come un comando.
3. URL `https://esempio.it@altro.example/login?token=prova`: host effettivo altro.example; nessuna apertura; valore token non nel report.
4. QR URL, testo e Wi-Fi da foto: decodifica; nessuna connessione automatica; credenziali Wi-Fi non nel report.
5. SHA-256 di un file noto contro hash calcolato sul PC: corrispondenza/differenza/riferimento errato; annullamento; file iCloud.
6. Foto con GPS/EXIF noti: esportazione copia, controllo indipendente dei metadati esportati, originale preservato; foto ruotata e formati HEIC/JPEG.
7. LAN autorizzata: IP con servizio noto, porte irraggiungibili, permesso concesso/negato e successiva ripetizione. Stop, background, uscita e riapertura senza risultati duplicati.
8. Prepara spiegazione → bozza rivista → invio; nessun controllo eseguito dalla risposta del modello. Report condiviso tramite pannello iOS/AirDrop.
9. Qwen: importazione corretta/rifiuto file errato, carica/scarica, italiano/UTF-8/streaming, stop, background e pressione memoria, chat in modalità aereo dopo import.
10. Font grandi, VoiceOver, tastiera e spazi delle barre inferiori sul tuo iPhone 15.

La riuscita dei controlli strutturali non garantisce una build verde o corretto comportamento delle API iOS sul dispositivo. In caso di errore servono i dettagli dello step rosso, non il solo codice 65.
