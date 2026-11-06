# ECO — Primo Legame 0.1

Prototipo iPhone nativo, iOS 16 o successivo. App separata da My G: non sostituire il repository My G.

## Come provarla dal tuo PC Windows

1. Estrai questo ZIP in una cartella sul PC.
2. Su GitHub crea un NUOVO repository chiamato `ECO`. Può essere privato. Inizializzalo con un README.
3. Nel nuovo repository scegli Add file → Upload files.
4. Apri la cartella estratta sul PC e trascina il suo CONTENUTO: `ECO`, `ECO.xcodeproj`, `scripts`, `tests`, `Brand` e i documenti. Non trascinare la cartella esterna e non caricare lo ZIP senza estrarlo.
5. Conferma con Commit changes. Nella pagina principale devono comparire direttamente `ECO.xcodeproj`, `ECO`, `scripts` e `tests`.
6. Aggiungi o sostituisci il workflow `.github/workflows/build-ios.yml`. Se il browser non carica `.github`, usa Add file → Create new file e scrivi ESATTAMENTE `.github/workflows/build-ios.yml` nel nome. Apri il file omonimo nello ZIP con Blocco note, copia TUTTO il contenuto nell’editor GitHub e conferma. Non copiare delimitatori Markdown.
7. Vai in Actions → **ECO - Crea IPA**. Parte su salvataggio a main/master, oppure premi Run workflow → main → Run workflow.
8. Il job controlla le regole di gioco, compila per iPhone arm64 e prepara il pacchetto. Quando è verde, apri Summary → Artifacts → **ECO-IPA-da-firmare**.
9. Scarica ed estrai l’artifact: trovi **ECO-unsigned.ipa**.
10. Collega l’iPhone, sbloccalo, apri Sideloadly, trascina il nuovo IPA e usa il tuo Apple ID. Premi Start e completa la verifica soltanto nel programma. La firma è necessaria: GitHub produce un IPA non firmato.
11. ECO apparirà come app separata da My G. Se iOS lo richiede, autorizza lo sviluppatore in Impostazioni → Generali → VPN e gestione dispositivo e abilita Modalità sviluppatore in Privacy e sicurezza.

Non servono chiavi Google, certificati da caricare su GitHub o password nel repository. Le esecuzioni macOS sono soggette alle quote/costi del tuo piano GitHub. La firma gratuita tramite il tuo account ha i limiti previsti da Apple/Sideloadly e va rinnovata. Non sono implementati aggiornamenti automatici dell’app da GitHub.

## Il tuo primo utilizzo (circa due minuti)

1. Apri ECO e premi Cominciamo.
2. Tocca Crea la tua prima eco e dai un nome a un luogo, per esempio “La mia piazza”.
3. Scegli una sensazione. La posizione è facoltativa: puoi usare il luogo manualmente senza GPS.
4. Premi Fai nascere la tua eco: nasce un Seme della famiglia Lume.
5. Apri il luogo e scegli Aggiungi presenza o ricordo.
6. Leggi la proposta del giorno, scrivi una tua osservazione o aggiungi una foto facoltativa. Conferma manualmente il momento, oppure verifica la vicinanza GPS se disponibile.
7. Se hai svolto la proposta, selezionala e salva. La tua eco potrebbe cambiare forma: dipende dai passi di legame accumulati.
8. Ritrova i ricordi in Diario e le trasformazioni in Forme. Puoi creare fino a tre luoghi.

La creazione conta già come presenza di oggi. Ripremere un pulsante senza aggiungere niente non aumenta i punti. Puoi aggiungere altri ricordi oggi; ritorni e memorie danno al massimo un punto ciascuno per giorno e luogo. Una missione differente aggiunge due punti di curiosità una sola volta. È permessa una missione al giorno per luogo.

## Cosa funziona nel progetto

- Onboarding, quattro sezioni Oggi/Luoghi/Diario/Forme e impostazioni.
- Tre luoghi privati, manuali o con posizione salvata.
- Creatura Lume disegnata in codice, animazione leggera, quattro colori emozionali, cinque forme; riduzione movimento rispettata.
- Dieci missioni creative a rotazione deterministica quotidiana.
- Regole di crescita, limiti giornalieri, sonno dopo sette giorni senza penalità.
- Diario ricercabile con note, foto e indicazione manuale/GPS.
- Mappa Apple con punti salvati e schede cliccabili dei luoghi; nessuna API key necessaria.
- Salvataggio atomico locale, backup completo JSON esportabile/importabile e cancellazione.
- Logo/icona originale e workflow GitHub Actions.

## Cosa non è ancora compreso

Versione Android, account, sincronizzazione cloud, mappe pubbliche, social, riconoscimento AI delle emozioni o del luogo, notifiche, AR, acquisti o abbonamenti. La v0.1 serve a verificare se l’esperienza è interessante prima di investire nella distribuzione commerciale.

La modalità manuale si basa sulla tua dichiarazione. Il GPS conferma soltanto vicinanza indicativa entro 100 m, con precisione iniziale e attuale entro 60 m; non dimostra che una missione sia stata svolta. Non è un sistema antifrode e non distribuisce premi in denaro.

## Stato della verifica

Sono stati verificati struttura Xcode, risorse, plist, workflow e sintassi shell nell’ambiente di consegna. Qui non sono disponibili macOS/Xcode o un iPhone collegato: compilazione Swift e prova hardware NON sono dichiarate riuscite. La prima esecuzione GitHub è la verifica effettiva. Se diventa rossa, scarica ECO-log-compilazione e conserva l’errore.

Vedi `VERIFICHE.md` per casi di prova, `LOGICA.md` per il motore e `README.md` per i dettagli tecnici.
