# ECO — Primo Legame

Apri prima **INIZIA_QUI.md** per caricare il progetto in un NUOVO repository e installarlo con GitHub Actions + Sideloadly da Windows.

## Stack

Swift 5, SwiftUI, Core Location, MapKit e PhotosUI. Deployment iOS 16, solo iPhone. Nessuna dipendenza esterna, chiave API, account o server. Le creature sono disegni vettoriali animati via Canvas; non serve un modello AI. Bundle ID base `com.usino.eco.primolegame`; firma e eventuale riscrittura ID gestite da Sideloadly.

## File

- ECO/EcoModel.swift: modello Codable, missioni e regole pure.
- ECO/EcoStore.swift: salvataggio atomico, limiti e import/export.
- ECO/EcoLocation.swift: richiesta GPS singola, timeout, nessun background.
- ECO/CreatureView.swift: forme/animazione/accessibilità.
- ECO/RootView.swift: navigazione, onboarding e collezione.
- ECO/PlaceViews.swift: creazione luogo, visita, missione e foto.
- ECO/PlacesMapView.swift: mappa Apple e lista dei luoghi.
- ECO/JournalView.swift: diario e ricerca locale.
- ECO/SettingsView.swift: privacy, backup e cancellazione.
- tests/RulesChecks/main.swift: test delle vere regole e del vero store.
- scripts/generate_project.py: rigenera progetto/plist/schema senza dipendenze.
- scripts/build-ipa.sh: test Swift, build iphoneos, arm64, packaging.
- .github/workflows/build-ios.yml: esecuzione macOS, artifact IPA e log.

## Dati

Archivio JSON nella sandbox Application Support/ECO/eco-v1.json. Le foto selezionate vengono ridotte a massimo 1024px e ricodificate JPEG (max 2 MB ciascuna); non viene conservato il file originale con i suoi metadati. Il salvataggio e import sono limitati a 64 MB di JSON. Il prototipo riscrive l’archivio a ogni modifica: per una libreria grande serviranno database e file foto separati.

Il salvataggio aggiorna lo stato UI solo dopo la scrittura riuscita. Un archivio non leggibile non viene sovrascritto automaticamente. In quel caso è esportabile il file originale prima di un eventuale ripristino. Importare un backup sostituisce i dati attuali e richiede conferma nell’app.

Il backup JSON contiene testo, foto base64 e coordinate: non è un file cifrato esportato. L’originale nell’app usa la protezione file iOS e può rientrare nei backup del dispositivo. Proteggi le copie esportate. La cancellazione nell’app non rimuove copie già condivise o backup esterni. Non caricare backup personali su GitHub.

La posizione non è registrata passivamente: richiesta singola dopo un tocco, cancellata quando esci dalla schermata o l’app diventa inattiva. Non è presente nessuna autorizzazione Always, Bluetooth, microfono o fotocamera. PhotosPicker apre il selettore di sistema, senza accesso indiscriminato alla libreria; foto solo scelte dall’utente. Se una foto è solo su iCloud può servire rete per scaricarla. MapKit contatta Apple per la mappa: l’app non è totalmente offline per nuove mappe, mentre diario/manuale restano utilizzabili offline.

## Versioni successive, dopo il test

Prima migliorare esperienza e qualità grafica con feedback reale. Poi Android e backup cloud facoltativo. Solo dopo validazione aggiungere contenuti acquistabili e pubblicazione ufficiale: non simulare pagamenti e non distribuire un prodotto commerciale tramite sola firma personale.

## Fonti tecniche

- https://developer.apple.com/documentation/corelocation/cllocationmanager/requestlocation()
- https://developer.apple.com/documentation/photosui/photospicker
- https://developer.apple.com/documentation/mapkit
- https://github.com/actions/checkout
- https://github.com/actions/upload-artifact
