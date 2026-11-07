# USI Pocket Security 0.3

App nativa iOS 16+, pensata per iPhone 15: chat locale Qwen3-0.6B-Q8_0 + sicurezza, Web, voce e strumenti deterministici.

- Qwen/llama.cpp CPU con Accelerate, nessun server di inferenza. Chat con contesto recente opzionale, risposte senza saluti automatici e modalità Approfondisci (256/384 token).
- Richieste prezzo singolo asset riconosciute: Coinbase Spot (BTC, ETH, SOL, AVAX, DOGE; EUR/USD), importo e fonte visualizzati direttamente. Nessuna fallback al modello per inventare prezzi in caso di errore.
- Web: WKWebView HTTPS, sessione non persistente; ricerca DuckDuckGo e lettura esplicita di testo selezionato/pagina, anteprima e fonte allegata alla prossima domanda. Nessun accesso alla sessione del browser esterno.
- Voce: SFSpeechRecognizer + AVAudioEngine, 45 secondi, locale se disponibile, fallback Apple online solo se consentito; trascrizione rivista e inviata. AVSpeechSynthesizer per risposta letta su richiesta o automaticamente.
- Calcolatore aritmetico locale: parser senza eval, precedenza, potenze, parentesi e controlli errori.
- Strumenti sicurezza invariati: URL, QR, SHA-256, JPEG senza GPS/EXIF, connessioni TCP a singolo host privato autorizzato.

## Build e installazione

Leggi **INIZIA_QUI.md**. GitHub Actions macos-15 → workflow **USI Pocket Security - Crea IPA** → artifact **PocketAI-IPA-da-firmare** → Sideloadly Windows. Versione 0.3/build 4, bundle ID `com.usino.pocketai`, fix LIBRARY_SEARCH_PATHS Vendor preservato. Nessuna chiave o credenziale inclusa; GGUF scaricato separatamente dal repository ufficiale Qwen.

Nuovi sorgenti: OnlineTools.swift, LocalCalculator.swift, VoiceController.swift, BrowserView.swift. Il generatore elenca automaticamente tutti i sorgenti. Info.plist include Microfono, Speech e Rete locale. La cronologia precedente con soli role/text/id rimane decodificabile; sourceURL/sourceTitle sono opzionali.

## Vincoli

Qwen0.6B non diventa un modello più grande collegandolo a Internet. Non sono stati misurati ragionamento, velocità, memoria o batteria della versione nuova. La ricerca generale è mediata dall’utente e limitata a estratti; il modello non può controllare browser o altre app autonomamente. Nessun acquisto di servizi AI a pagamento attivato. Servizi web e Apple possono richiedere rete e rispettivi limiti.

Motore: llama.cpp b6000, commit 4762ad7316dcdec20016ab5985fb46a27902204d (MIT inclusa). Modello Qwen3-0.6B-GGUF Q8_0, Apache2.0, impronta verificata dall’importatore.

Stato dei controlli: **VERIFICHE.md**. Nuova build iOS e prove vocali/browser ancora da eseguire.
