import SwiftUI
import UniformTypeIdentifiers
import UIKit
import AVFoundation

struct PocketView: View {
    @ObservedObject var chat: ChatModel
    @StateObject private var voice = VoiceController()
    @AppStorage("pocket.readAloud") private var readAloud = false
    @AppStorage("pocket.networkSpeech") private var networkSpeech = false
    let routeCommand: (String) -> Bool
    @Environment(\.scenePhase) private var phase
    @State private var importing = false
    @State private var settings = false
    @State private var clear = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                conversation
                composer
            }
            .background(Color(red: 0.035, green: 0.05, blue: 0.09))
            .navigationTitle("USI Pocket Security").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { clear = true } label: { Image(systemName: "square.and.pencil") }.disabled(chat.busy).accessibilityLabel("Nuova chat")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Modello e impostazioni")
                }
            }
            .sheet(isPresented: $settings) { modelSettings }
            .fileImporter(isPresented: $importing, allowedContentTypes: [UTType(filenameExtension: "gguf") ?? .data]) { result in
                switch result {
                case .success(let url): chat.install(url)
                case .failure(let error): chat.error = error.localizedDescription
                }
            }
            .alert("USI Pocket Security", isPresented: Binding(get: { chat.error != nil }, set: { if !$0 { chat.error = nil } })) {
                Button("OK", role: .cancel) { chat.error = nil }
            } message: { Text(chat.error ?? "") }
            .confirmationDialog("Cancellare la cronologia e iniziare una nuova chat?", isPresented: $clear, titleVisibility: .visible) {
                Button("Nuova chat", role: .destructive) { chat.clearHistory() }
            }
            .onChange(of: phase) { if $0 == .background { chat.stop(); voice.stopAll() } }
            .onDisappear { voice.stopAll() }
            .onChange(of: chat.replySerial) { _ in
                if readAloud, let answer = chat.messages.last, answer.role == .assistant { voice.speak(answer.text) }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stopAll() }
            .alert("Voce", isPresented: Binding(get: { voice.error != nil }, set: { if !$0 { voice.error = nil } })) {
                Button("OK") { voice.error = nil }
            } message: { Text(voice.error ?? "") }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in chat.memoryWarning() }
        }.tint(.mint)
    }
    private var statusBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(chat.loaded ? Color.mint : Color.orange).frame(width: 7, height: 7)
                Text(chat.status).font(.caption)
                Spacer()
                if chat.busy { ProgressView().scaleEffect(0.8) }
            }
            if !chat.loaded && !chat.busy {
                if chat.modelURL != nil {
                    Button("Carica Qwen") { chat.load() }.buttonStyle(.borderedProminent)
                } else {
                    Button("Importa Qwen GGUF") { importing = true }.buttonStyle(.borderedProminent)
                }
            }
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.04))
    }
    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if chat.messages.isEmpty { welcome }
                    ForEach(chat.messages) { message in
                        MessageBubble(message: message, read: { voice.speak(message.text) })
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }.padding()
            }
            .onChange(of: chat.messages.last?.text) { _ in proxy.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: chat.messages.count) { _ in proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "cpu").font(.system(size: 46)).foregroundStyle(.mint)
            Text("Qwen, sul tuo iPhone.").font(.largeTitle.bold())
            Text("Importa il modello ufficiale, caricalo e fai una domanda breve. La risposta viene calcolata qui, senza inviare la chat a un server.")
            Text("Versione 0.3 · voce, Web, crypto e calcoli").font(.caption).foregroundStyle(.secondary)
            Button("Come installo il modello?") { settings = true }.buttonStyle(.bordered)
            Text("Prova “Quanto vale BTC in euro?”, “/calcola 7*8” o “/cerca ultime notizie”. Nel Web puoi allegare un estratto alla domanda. Tocca il microfono per dettare. Qwen può sbagliare.").font(.footnote).foregroundStyle(.secondary)
        }.padding(.vertical, 20)
    }
    private var composer: some View {
        VStack(spacing: 8) {
            if let source = chat.pendingSource {
                HStack {
                    Text("Fonte allegata: \(source.title)").font(.caption).lineLimit(1)
                    Spacer()
                    Button("Rimuovi") { chat.pendingSource = nil }.font(.caption)
                }
            }
            HStack(alignment: .bottom) {
                TextField("Scrivi in italiano…", text: $chat.draft, axis: .vertical).lineLimit(1...5)
                    .padding(12).background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                if chat.canStop {
                    Button { chat.stop() } label: { Image(systemName: "stop.fill").padding(12) }.buttonStyle(.bordered).accessibilityLabel("Interrompi risposta")
                } else {
                    Button { voice.stop(); voice.silence(); if !routeCommand(chat.draft) { chat.send() } } label: { Image(systemName: "arrow.up").padding(12) }.buttonStyle(.borderedProminent)
                        .disabled(chat.busy || (!chat.canSend(chat.draft) && SecurityRoute.parse(chat.draft) == nil && OnlineTools.browserQuery(chat.draft) == nil && !AssistantActions.recognizes(chat.draft)) || chat.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chat.draft.count > 1000)
                        .accessibilityLabel("Invia messaggio")
                }
            }
            HStack(spacing: 14) {
                Button {
                    if voice.recording || voice.requesting { voice.stop() }
                    else {
                        let base = chat.draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        voice.start(allowNetwork: networkSpeech) { transcript in
                            chat.draft = String((base.isEmpty ? transcript : base + " " + transcript).prefix(1000))
                        }
                    }
                } label: {
                    Label(voice.recording ? "Ferma dettatura" : "Parla", systemImage: voice.recording ? "stop.circle.fill" : "mic.fill")
                }.buttonStyle(.bordered).disabled(chat.busy)
                Button("Ferma voce") { voice.silence() }.font(.caption)
                Spacer()
            }
            Toggle("Approfondisci", isOn: $chat.detailed).font(.caption).disabled(chat.busy)
            if voice.recording || voice.requesting { Text(voice.status).font(.caption).foregroundStyle(.mint) }
            Text("\(chat.draft.count)/1000 · \(chat.includeHistory ? "contesto recente" : "domanda indipendente") · locale").font(.caption2).foregroundStyle(.secondary)
        }.padding()
    }
    private var modelSettings: some View {
        ModelSettings(chat: chat, readAloud: $readAloud, networkSpeech: $networkSpeech, importAction: { settings = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { importing = true } })
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let read: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(message.role == .user ? "TU" : message.sourceTitle != nil && message.sourceTitle?.hasPrefix("Fonte scelta") != true ? "STRUMENTO" : "QWEN LOCALE").font(.caption.bold()).foregroundStyle(message.role == .user ? Color.secondary : Color.mint)
            Text(message.text.isEmpty ? "…" : message.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            if let title = message.sourceTitle { Text(title).font(.caption).foregroundStyle(.secondary) }
            if let url = OnlineTools.sourceURL(message.sourceURL) { Link("Apri fonte", destination: url).font(.caption) }
            if message.role == .assistant, !message.text.isEmpty {
                Button(action: read) { Label("Ascolta", systemImage: "speaker.wave.2.fill") }.font(.caption).buttonStyle(.borderless)
            }
        }.padding(15).background(message.role == .user ? Color.white.opacity(0.07) : Color.mint.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ModelSettings: View {
    @ObservedObject var chat: ChatModel
    @Binding var readAloud: Bool
    @Binding var networkSpeech: Bool
    let importAction: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var deleteModel = false
    @State private var deleteChat = false
    var body: some View {
        NavigationStack {
            Form {
                Section("1 · Scarica il modello") {
                    Text("Qwen3-0.6B-Q8_0.gguf · circa 639 MB. Il modello non è incluso nell’IPA. Scaricalo da Safari e attendi il completamento in File → Download.")
                    Link("Apri il download ufficiale Qwen", destination: URL(string: "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf?download=true")!)
                    Text("Serve spazio per il download e la copia nell’app. Tieni preferibilmente almeno 2 GB liberi prima di iniziare.").font(.caption)
                }
                Section("2 · Importa e carica") {
                    Button("Scegli il GGUF da File") { importAction() }.disabled(chat.busy)
                    Text("L’app verifica l’impronta del file ufficiale. Per ora non accetta modelli diversi, Qwen 7B o altre quantizzazioni.").font(.caption)
                    if chat.modelURL != nil {
                        Button("Carica Qwen") { chat.load() }.disabled(chat.busy || chat.loaded)
                        Button("Libera memoria (conserva file)") { chat.unload() }.disabled(chat.busy || !chat.loaded)
                    }
                    Text(chat.status).font(.caption)
                    if let error = chat.error { Text(error).font(.caption).foregroundStyle(.orange) }
                }
                Section("Internet e voce") {
                    Toggle("Prezzi crypto online", isOn: $chat.onlineEnabled).disabled(chat.busy)
                    Text("Solo richieste prezzo riconosciute inviano la coppia (es. BTC-EUR) a Coinbase. La chat intera non viene inviata. Nel Web scegli tu ricerche e pagine da aprire: questo interruttore non disabilita il browser.").font(.caption)
                    Toggle("Leggi automaticamente le risposte", isOn: $readAloud)
                    Toggle("Consenti dettatura online Apple se necessaria", isOn: $networkSpeech)
                    Text("Il microfono parte solo al tuo tocco e si ferma entro 45 secondi. La dettatura preferisce il riconoscimento locale; se non disponibile, resta bloccata finché non consenti l’elaborazione Apple online. Rivedi il testo e premi Invia. Nessun audio viene salvato dall’app.").font(.caption)
                    Text("Approfondisci chiede risposta, breve metodo verificabile e limiti; non cambia i pesi del modello. /calcola usa invece un calcolatore numerico locale.").font(.caption)
                }
                Section("Contesto della risposta") {
                    Toggle("Usa messaggi precedenti", isOn: $chat.includeHistory).disabled(chat.busy)
                    Text("Spento: ogni domanda è indipendente, anche se la chat resta visibile. Acceso: Qwen riceve anche alcune risposte precedenti; può riprenderne errori o saluti. Se si ripete, disattiva questa opzione o avvia una nuova chat.").font(.caption)
                }
                Section("Uso e limiti") {
                    Text("CPU locale, contesto 2048 token, fino a 256 token per risposta o 384 con Approfondisci. Se attivi Usa messaggi precedenti, una parte recente della cronologia entra nel contesto. Per testi lunghi avvia una nuova chat. La prima risposta può richiedere attesa.")
                    Text("Memoria, velocità e temperatura dipendono dal telefono e dalle altre app. iOS può terminare un’app che usa troppa memoria. La generazione viene interrotta quando l’app va in background.")
                    Text("Nessun server di inferenza AI. Download: Hugging Face/CDN; prezzi: Coinbase; browser: motore di ricerca e siti scelti. La dettatura può usare Apple solo se consentito e necessaria. La cronologia è locale e può rientrare nei backup iOS; il modello copiato è escluso dai backup dell’app.")
                    Text("Questo prototipo non può controllare altre app o modificare impostazioni del telefono. Le risposte sono testo, non azioni eseguite.")
                }
                Section("Dati") {
                    Button("Cancella cronologia", role: .destructive) { deleteChat = true }.disabled(chat.busy)
                    Button("Elimina modello dall’app", role: .destructive) { deleteModel = true }.disabled(chat.busy || chat.modelURL == nil)
                    Text("Conserviamo fino a 50 messaggi nell’ultima chat. Cancellare il modello non elimina il download originale in File.").font(.caption)
                }
                Section("Crediti") {
                    Text("Qwen3: Qwen Team, modello Apache 2.0. Motore llama.cpp: MIT. USI Pocket Security è un prototipo indipendente, non un’app ufficiale Qwen.")
                    DisclosureGroup("Licenza llama.cpp") {
                        Text(llamaLicense).font(.caption).textSelection(.enabled)
                    }
                }
            }.navigationTitle("Qwen sul telefono")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fine") { dismiss() } } }
                .confirmationDialog("Eliminare la copia del modello dall’app?", isPresented: $deleteModel, titleVisibility: .visible) {
                    Button("Elimina modello", role: .destructive) { chat.removeModel() }
                }
                .confirmationDialog("Cancellare tutti i messaggi salvati?", isPresented: $deleteChat, titleVisibility: .visible) {
                    Button("Cancella chat", role: .destructive) { chat.clearHistory() }
                }
        }.tint(.mint)
    }
    private var llamaLicense: String {
        guard let url = Bundle.main.url(forResource: "LLAMA_LICENSE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "Licenza MIT: vedi il progetto llama.cpp." }
        return text
    }

}
