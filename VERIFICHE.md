# Verifiche ECO 0.1

## Controlli eseguibili qui

Parsing workflow, sintassi bash e Python, generazione deterministica progetto Xcode, riferimenti a sorgenti/risorse, schema, plist, privacy manifest, asset e icona RGB opaca. Controllo struttura e piattaforma del validatore IPA con fixture. Integrità ZIP finale. Le fixture non sono app e non sono consegnate.

## Controlli Swift inclusi nel workflow

Test eseguiti contro EcoModel.swift e EcoStore.swift reali:
- crescita iniziale e prima trasformazione;
- più ricordi della stessa giornata non moltiplicano memoria/presenza;
- curiosità solo per missioni diverse e una registrazione missione al giorno;
- missione quotidiana stabile, rotazione nei giorni successivi;
- nessuna penalità durante il riposo;
- coordinate non valide rifiutate;
- serializzazione e ricaricamento del diario;
- limite tre luoghi;
- archivio corrotto protetto e importazione non valida che conserva i dati;
- ripristino backup valido e cancellazione.

Il job poi compila l’intera app per iPhone arm64, impacchetta e verifica il formato dell’IPA. Firma non inclusa.

Questi test Swift e la compilazione Xcode NON sono stati eseguiti nell’ambiente di consegna, privo di Swift/macOS/Xcode. Saranno eseguiti dalla prima Actions nel tuo repository.

## Prove sul tuo iPhone

1. Installazione separata da My G, icona ECO, onboarding una volta sola.
2. Primo luogo manuale senza chiedere GPS; creazione di tre luoghi e blocco del quarto.
3. GPS accettato/negato, timeout, modalità approssimativa e cancellazione richiesta quando l’app esce dal primo piano.
4. Scheda della creatura e dieci missioni, ricordi con testo/foto, forma che cambia alle soglie.
5. Creazione già conteggiata oggi: ulteriore presenza vuota bloccata, memoria consentita, missione duplicata bloccata.
6. Foto locale/iCloud, file troppo grande o non disponibile, rimozione prima del salvataggio, nessun progresso perso in caso di errore.
7. Diario ricercabile e riapertura dell’app con dati conservati.
8. Mappa Apple con pin e lista cliccabile; luogo manuale presente nella lista anche senza pin.
9. Backup esportato in File, importato dopo conferma, backup malformato rifiutato senza perdere il diario.
10. Eliminazione di un luogo e cancellazione completa con conferma.
11. Modalità Riduci movimento, VoiceOver, testi ingranditi e schermo piccolo.
12. Firma scaduta e reinstallazione con lo stesso Apple ID/Bundle ID: esportare comunque un backup prima di aggiornamenti importanti.

La v0.1 è un prototipo: nessuna prova commerciale, approvazione App Store, garanzia di precisione GPS o validazione della domanda di mercato è dichiarata.
