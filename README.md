# USI Pocket Security 0.2

App nativa SwiftUI iOS 16+, pensata per iPhone 15. Evoluzione della chat locale Pocket AI: Qwen3-0.6B Q8_0 con llama.cpp CPU e cinque strumenti espliciti, utilizzabili senza modello.

- URL: parsing locale, host e indizi; nessuna richiesta al sito.
- QR: Vision su foto selezionata, nessuna azione automatica.
- SHA-256: CryptoKit, lettura a blocchi e confronto con riferimento.
- Foto: ricodifica ImageIO JPEG, controllo assenza GPS/EXIF prima della condivisione.
- LAN: Network.framework, un IPv4 RFC1918 scelto, connessioni TCP limitate e annullabili.

Chat e Sicurezza condividono solo estratti di report richiesti dall’utente. Nessuna esecuzione di codice o tool chiamato dal modello. UI scura con accenti mint, icona esistente CPU locale. Bundle ID invariato: com.usino.pocketai. Build 2, versione 0.2.

Parti da **INIZIA_QUI.md**. Workflow: **USI Pocket Security - Crea IPA**. Artifact: **PocketAI-IPA-da-firmare**, contenente IPA unsigned da firmare con Sideloadly. Modello separato, non incluso.

## Architettura

`SecurityRules.swift`: parsing, confini IPv4, normalizzazione hash e routing esplicito. `SecurityFiles.swift`: hash e ricodifica. `LocalPortProbe.swift`: connessioni seriali TCP con timeout. `SecurityViews.swift`: controlli e report. `PocketRootView`: schede e passaggio bozza alla chat. `PromptBuilder`: contesto limitato, delimitatori ChatML e visualizzazione senza think. `NativeEngine` e bridge C++: inference CPU locale già presente.

Solo permesso Rete locale aggiunto. PhotosPicker non richiede accesso completo alla libreria, né fotocamera. Nessun entitlement multicast o scansione Wi-Fi. Non inviare report o credenziali personali al repository.

Dipendenza motore fissata a llama.cpp b6000, commit 4762ad7316dcdec20016ab5985fb46a27902204d, MIT (licenza inclusa). Modello ufficiale Qwen3-0.6B-GGUF Q8_0, Apache 2.0, verificato dall’importatore con SHA-256. Nessuna chiave API o servizio AI a pagamento.

Non compilato con Xcode in questo ambiente. Stato delle verifiche: **VERIFICHE.md**.
