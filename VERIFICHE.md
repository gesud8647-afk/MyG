# Verifiche — versione 0.3

## Eseguite qui

- Rigenerato progetto Xcode: tutti i sorgenti presenti, riferimenti unici/risolti, schema XML e plist leggibili, versione 0.3/build4 e descrizioni Microfono/Speech/Rete locale.
- Parsing sintattico di tutti i sorgenti e test Swift con tree-sitter: passato; non è type checking o compilazione Swift.
- Controllate sintassi script Bash/Python, trigger workflow e inclusione dei file nei test Swift. Fix linker Vendor nelle configurazioni Debug/Release preservato.
- Verifica live HTTPS Coinbase `BTC-EUR/spot`: status200, JSON data.amount numerico positivo e data.currency EUR. È una singola verifica dell’endpoint, non una garanzia di uptime o test URLSession su iOS.
- Validatore struttura IPA con fixture dispositivo e rifiuto fixture simulatore; integrità archivio sorgenti.
- Revisione cancellazione richieste, blocco fallback prezzo inventato, fonti HTTPS, estratto esplicitamente confermato e testo web separato dalla domanda nel prompt.

## Test aggiunti nel workflow GitHub, non eseguiti localmente

- Precedenti test prompt/sicurezza e modalità indipendente.
- Riconoscimento richieste prezzo, valuta, asset ambigui, mancato riconoscimento di semplici sottostringhe, URL fonte HTTPS senza credenziali.
- Calcolatore: precedenza, potenza associativa a destra, segno unario, interesse composto numerico, divisione per zero e rifiuto codice.
- Escape delimitatori ChatML anche nel testo web, conservazione della domanda e decodifica della cronologia precedente senza campi fonte.
- Compilazione SwiftUI/AVFoundation/Speech/WebKit e motore nativo arm64, linking, creazione IPA.

Il log precedente dell’utente aveva confermato i vecchi test Swift e la compilazione del motore, poi falliva per percorso linker mancante (corretto nella versione FIX). Non è una conferma della build 0.3. Non disponibili qui Xcode/Swift o iPhone; inferenza, browser iOS, voce e nuove funzioni non eseguiti sul dispositivo.

## Prove richieste sul tuo iPhone

1. Aggiornamento Sideloadly con stesso account/identificativo senza disinstallazione, mantenimento GGUF/chat e permessi richiesti solo quando usati.
2. Prezzo BTC EUR, ETH USD, rete assente, richiesta annullata, interruttore prezzi spento, rate limit/errori servizio e richieste ambigue: nessun prezzo inventato. Confronto fonte/orario con il dato appena ricevuto, non con messaggi storici.
3. Browser: ricerca, HTTPS, avanti/indietro, link nuovo tab, pagina non leggibile, testo selezionato, anteprima modificata, annullamento e fonte allegata alla prossima domanda.
4. Fonte allegata: prompt breve/lungo e errore contesto, link visibile anche dopo riavvio della chat, nessuna apertura/azione autonoma dal testo della pagina.
5. Voce: primo consenso, permessi negati, italiano locale supportato/non supportato, fallback Apple esplicito, trascrizione parziale/finale, stop, timeout45s, background e interruzione chiamata. Verificare che il microfono si spenga realmente.
6. Lettura manuale/automatica, stop voce, passaggio lettura→dettatura, cuffie/speaker, volume e comportamento se iOS non ha voce italiana disponibile.
7. Calcolatore senza Qwen, input valido/invalido e arrotondamento; Approfondisci con Qwen, domande reali in italiano, confronto qualità senza promessa di aumento capacità.
8. Contesto recente acceso/spento, persistenza scelta precedente, saluti ripetuti, stop generazione, memoria, temperatura e consumo.
9. Font grandi, VoiceOver, tastiera, disposizione controlli e tab su iPhone15. Strumenti sicurezza precedenti e condivisione/AirDrop.

Il controllo statico del progetto non sostituisce una build Xcode verde o i test su dispositivo.

## 0.3.1
Aggiunta scheda Azioni e routing di richieste esatte. URL costruiti con URLComponents e campi codificati; WhatsApp resta in composizione, avvio Mappe e Comandi Rapidi confermato. Parsing sintattico eseguito; funzionamento delle app esterne e build Xcode ancora da verificare. Non implementato Qwen1.7B.
