import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PocketView: View {
    @ObservedObject var chat: ChatModel
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
            .onChange(of: phase) { if $0 == .background { chat.stop() } }
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
                        MessageBubble(message: message)
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
            Text("Versione 0.2 · chat locale + strumenti di sicurezza").font(.caption).foregroundStyle(.secondary)
            Button("Come installo il modello?") { settings = true }.buttonStyle(.bordered)
            Text("Apri Sicurezza oppure scrivi /link, /qr, /hash, /foto o /rete. I controlli funzionano anche senza modello; Qwen può sbagliare.").font(.footnote).foregroundStyle(.secondary)
        }.padding(.vertical, 20)
    }
    private var composer: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom) {
                TextField("Scrivi in italiano…", text: $chat.draft, axis: .vertical).lineLimit(1...5)
                    .padding(12).background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                if chat.generating {
                    Button { chat.stop() } label: { Image(systemName: "stop.fill").padding(12) }.buttonStyle(.bordered).accessibilityLabel("Interrompi risposta")
                } else {
                    Button { if !routeCommand(chat.draft) { chat.send() } } label: { Image(systemName: "arrow.up").padding(12) }.buttonStyle(.borderedProminent)
                        .disabled(chat.busy || (!chat.loaded && SecurityRoute.parse(chat.draft) == nil) || chat.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chat.draft.count > 1000)
                        .accessibilityLabel("Invia messaggio")
                }
            }
            Text("\(chat.draft.count)/1000 · inferenza locale, nessun comando di sistema").font(.caption2).foregroundStyle(.secondary)
        }.padding()
    }
    private var modelSettings: some View {
        ModelSettings(chat: chat, importAction: { settings = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { importing = true } })
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(message.role == .user ? "TU" : "QWEN LOCALE").font(.caption.bold()).foregroundStyle(message.role == .user ? Color.secondary : Color.mint)
            Text(message.text.isEmpty ? "…" : message.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(15).background(message.role == .user ? Color.white.opacity(0.07) : Color.mint.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ModelSettings: View {
    @ObservedObject var chat: ChatModel
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
                Section("Uso e limiti") {
                    Text("CPU locale, contesto 2048 token e fino a 256 token per risposta. Solo una parte recente della cronologia entra nel contesto. Per testi lunghi avvia una nuova chat. La prima risposta può richiedere attesa.")
                    Text("Memoria, velocità e temperatura dipendono dal telefono e dalle altre app. iOS può terminare un’app che usa troppa memoria. La generazione viene interrotta quando l’app va in background.")
                    Text("Niente server AI, account Qwen o chiavi API. I collegamenti di download contattano Hugging Face/CDN. La cronologia è locale e può rientrare nei backup iOS; il modello copiato è escluso dai backup dell’app.")
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
