import Foundation
import Combine

final class ChatModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published var includeHistory = (UserDefaults.standard.object(forKey: "pocket.includeHistory") as? Bool) ?? true {
        didSet { UserDefaults.standard.set(includeHistory, forKey: "pocket.includeHistory") }
    }
    @Published private(set) var busy = false
    @Published private(set) var generating = false
    @Published private(set) var loaded = false
    @Published private(set) var status = "Importa il modello Qwen per iniziare."
    @Published var error: String?
    @Published var onlineEnabled = (UserDefaults.standard.object(forKey: "pocket.online") as? Bool) ?? true {
        didSet { UserDefaults.standard.set(onlineEnabled, forKey: "pocket.online") }
    }
    @Published var detailed = false
    @Published var pendingSource: BrowserSource?
    @Published private(set) var fetching = false
    @Published private(set) var replySerial = 0
    private var onlineTask: Task<Void, Never>?
    var canStop: Bool { generating || fetching }
    func canSend(_ text: String) -> Bool {
        loaded || OnlineTools.asksPrice(text) || LocalCalculator.expression(text) != nil
    }
    private let engine = NativeEngine()
    private var releaseAfterOperation = false
    private var historyReadable = true
    private let defaults = UserDefaults.standard
    private var historyURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PocketChat.json")
    }
    var modelURL: URL? {
        guard let name = defaults.string(forKey: "pocket.model"), name == URL(fileURLWithPath: name).lastPathComponent else { return nil }
        let url = ModelInstaller.folder.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    init() {
        do {
            if FileManager.default.fileExists(atPath: historyURL.path) {
                let data = try Data(contentsOf: historyURL)
                guard data.count <= 1_000_000 else { throw CocoaError(.fileReadTooLarge) }
                messages = Array(try JSONDecoder().decode([ChatMessage].self, from: data).suffix(50))
            }
            if modelURL != nil { status = "Modello presente sul telefono. Tocca Carica Qwen." }
        } catch {
            historyReadable = false
            self.error = "Cronologia non leggibile: il file originale è conservato. Cancella la cronologia dalle impostazioni per ripartire."
        }
    }
    private func saveHistory() {
        guard historyReadable else { return }
        do {
            try FileManager.default.createDirectory(at: historyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(messages.suffix(50)))
            try data.write(to: historyURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch { self.error = "Chat visibile ma salvataggio non riuscito: \(error.localizedDescription)" }
    }
    func install(_ url: URL) {
        guard !busy else { return }
        busy = true; status = "Copio il modello sul telefono…"
        ModelInstaller.install(url, progress: { self.status = $0 }) { result in
            switch result {
            case .failure(let error):
                self.busy = false; self.status = "Importazione non riuscita"; self.error = error.localizedDescription
                self.finishMemoryReleaseIfNeeded()
            case .success(let copied):
                self.loaded = false
                self.status = "Carico Qwen nella memoria…"
                self.engine.load(path: copied.path) { error in
                    self.busy = false
                    if let error = error {
                        try? FileManager.default.removeItem(at: copied)
                        self.status = "Caricamento non riuscito"; self.error = error
                    } else {
                        self.defaults.set(copied.lastPathComponent, forKey: "pocket.model")
                        // The previous model was released by the serialized engine worker.
                        if let files = try? FileManager.default.contentsOfDirectory(at: ModelInstaller.folder, includingPropertiesForKeys: nil) {
                            for old in files where old != copied { try? FileManager.default.removeItem(at: old) }
                        }
                        self.loaded = true; self.status = "Qwen locale pronto · CPU"
                    }
                    self.finishMemoryReleaseIfNeeded()
                }
            }
        }
    }
    func load() {
        guard !busy, let url = modelURL else { return }
        busy = true; status = "Carico Qwen nella memoria…"
        engine.load(path: url.path) { error in
            self.busy = false; self.loaded = error == nil
            self.status = error == nil ? "Qwen locale pronto · CPU" : "Caricamento non riuscito"
            self.error = error
            self.finishMemoryReleaseIfNeeded()
        }
    }
    func unload() {
        guard !busy else { return }
        busy = true; status = "Libero la memoria…"
        engine.unload {
            self.loaded = false; self.busy = false
            self.status = "Memoria liberata. Il file modello resta sul telefono."
        }
    }
    func send() {
        guard !busy, historyReadable else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 1000 else { error = "Scrivi un messaggio da 1 a 1000 caratteri."; return }
        if let expression = LocalCalculator.expression(text) {
            beginUser(text)
            do { finishTool(try LocalCalculator.report(expression), title: "Calcolo locale") }
            catch { finishTool(error.localizedDescription, title: "Calcolo non eseguito") }
            return
        }
        if let request = OnlineTools.priceRequest(text) {
            beginUser(text)
            guard onlineEnabled else { finishTool("Internet è disattivato nelle impostazioni. Non posso verificare la quotazione attuale.", title: "Prezzo non verificato"); return }
            busy = true; fetching = true; status = "Richiedo quotazione a Coinbase…"
            onlineTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    let quote = try await OnlineTools.price(request)
                    try Task.checkCancellation()
                    self.finishTool(quote.text, title: "Coinbase Spot · dato ricevuto", url: quote.url.absoluteString)
                } catch {
                    let message = Task.isCancelled ? "Richiesta annullata. Nessun prezzo verificato." : "Non ho potuto verificare il prezzo: \(error.localizedDescription)"
                    self.finishTool(message, title: "Prezzo non verificato")
                }
                self.fetching = false; self.busy = false; self.onlineTask = nil
                self.finishMemoryReleaseIfNeeded()
            }
            return
        }
        if OnlineTools.asksPrice(text) {
            beginUser(text)
            finishTool("Non ho verificato una quotazione per questa richiesta. Chiedi un singolo asset tra BTC, ETH, SOL, AVAX e DOGE, in EUR o USD. Per altri prezzi o informazioni usa /cerca seguito dalla ricerca e scegli una fonte nel Web.", title: "Prezzo non verificato")
            return
        }
        guard loaded else { error = "Carica Qwen per questa domanda. Prezzi crypto e /calcola funzionano anche senza modello."; return }
        draft = ""
        messages.append(ChatMessage(role: .user, text: text))
        if messages.count > 48 { messages = Array(messages.suffix(48)) }
        let source = pendingSource; pendingSource = nil
        let prompt = PromptBuilder.build(messages, includeHistory: includeHistory, sourceText: source?.text, detailed: detailed)
        var answer = ChatMessage(role: .assistant, text: "")
        if let source = source {
            answer.sourceURL = source.url.absoluteString
            answer.sourceTitle = "Fonte scelta · letta \(source.readAt.formatted(date: .numeric, time: .shortened)) · risposta non verificata"
        }
        let answerID = answer.id
        messages.append(answer)
        busy = true; generating = true; status = "Qwen sta rispondendo sul telefono…"
        saveHistory()
        engine.generate(prompt: prompt, limit: detailed ? 384 : 256, partial: { raw in
            if let i = self.messages.firstIndex(where: { $0.id == answerID }) {
                self.messages[i].text = PromptBuilder.display(raw)
            }
        }) { raw, code, error in
            if let i = self.messages.firstIndex(where: { $0.id == answerID }) {
                let display = PromptBuilder.display(raw)
                self.messages[i].text = display.isEmpty ? (code == 1 ? "[Risposta interrotta]" : "[Nessuna risposta disponibile]") : display
            }
            self.busy = false; self.generating = false
            self.status = code == 1 ? "Risposta interrotta" : code == 2 ? "Limite di risposta raggiunto · chiedi di continuare" : "Qwen locale pronto · CPU"
            if let error = error { self.error = error; self.status = "Generazione non riuscita" }
            self.saveHistory()
            if code >= 0 && code != 1 { self.replySerial += 1 }
            self.finishMemoryReleaseIfNeeded()
        }
    }
    private func beginUser(_ text: String) {
        draft = ""
        messages.append(ChatMessage(role: .user, text: text))
        if messages.count > 48 { messages = Array(messages.suffix(48)) }
    }
    private func finishTool(_ text: String, title: String, url: String? = nil) {
        var answer = ChatMessage(role: .assistant, text: text)
        answer.sourceTitle = title; answer.sourceURL = url
        messages.append(answer); status = title; saveHistory(); replySerial += 1
    }
    func stop() { if fetching { onlineTask?.cancel(); status = "Annullamento richiesta…" }; if generating { engine.cancel(); status = "Interruzione richiesta…" } }
    func memoryWarning() {
        if busy { releaseAfterOperation = true; stop() }
        else if loaded { unload() }
    }
    private func finishMemoryReleaseIfNeeded() {
        if releaseAfterOperation {
            releaseAfterOperation = false
            unload()
        }
    }
    func clearHistory() {
        guard !busy else { return }
        do {
            if FileManager.default.fileExists(atPath: historyURL.path) { try FileManager.default.removeItem(at: historyURL) }
            messages = []; historyReadable = true; draft = ""; pendingSource = nil
        } catch { self.error = "Cancellazione chat non riuscita: \(error.localizedDescription)" }
    }
    func removeModel() {
        guard !busy else { return }
        busy = true
        engine.unload {
            do {
                if FileManager.default.fileExists(atPath: ModelInstaller.folder.path) { try FileManager.default.removeItem(at: ModelInstaller.folder) }
                self.defaults.removeObject(forKey: "pocket.model")
                self.loaded = false; self.status = "Modello eliminato. Importa un GGUF per iniziare."
            } catch { self.loaded = false; self.error = "Eliminazione modello non riuscita: \(error.localizedDescription)" }
            self.busy = false
        }
    }
}
