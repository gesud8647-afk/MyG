import SwiftUI

struct AssistantActions: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("pocket.shortcutName") private var shortcut = ""
    @State private var number = ""
    @State private var message = ""
    @State private var destination = ""
    @State private var shortcutInput = ""
    @State private var pending: URL?
    @State private var confirm = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("WhatsApp") {
                    Button("Apri WhatsApp") { launch(URL(string: "whatsapp://")!) }
                    TextField("Numero internazionale, es. +39…", text: $number).keyboardType(.phonePad)
                    TextField("Testo del messaggio", text: $message, axis: .vertical)
                    Button("Prepara messaggio") {
                        let digits = number.filter { "0123456789".contains($0) }
                        guard (7...15).contains(digits.count), !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "Inserisci numero completo con prefisso internazionale e testo."; return }
                        var url = URLComponents(string: "https://wa.me/" + digits)!
                        url.queryItems = [URLQueryItem(name: "text", value: String(message.prefix(4000)))]
                        pending = url.url; confirm = true
                    }
                    Text("Controlla numero e testo. Il messaggio viene preparato in WhatsApp: l’invio resta da confermare lì.").font(.caption)
                }
                Section("Navigazione") {
                    TextField("Destinazione o indirizzo", text: $destination)
                    Button("Prepara navigazione") {
                        guard !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        var url = URLComponents(string: "https://maps.apple.com/")!
                        url.queryItems = [URLQueryItem(name: "daddr", value: String(destination.prefix(500))), URLQueryItem(name: "dirflg", value: "d")]
                        pending = url.url; confirm = true
                    }
                    Text("Mappe interpreta l’indirizzo: verifica la destinazione prima di partire.").font(.caption)
                }
                Section("Il tuo Comando Rapido") {
                    TextField("Nome esatto del comando già installato", text: $shortcut)
                    TextField("Testo da passare al comando (facoltativo)", text: $shortcutInput, axis: .vertical)
                    Button("Apri Comandi Rapidi per configurarlo") { launch(URL(string: "shortcuts://")!) }
                    Button("Prepara avvio del comando") {
                        guard !shortcut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "Crea prima il comando in Comandi Rapidi, poi inserisci qui il suo nome esatto."; return }
                        var url = URLComponents(string: "shortcuts://run-shortcut")!
                        url.queryItems = [URLQueryItem(name: "name", value: shortcut)]
                        if !shortcutInput.isEmpty { url.queryItems! += [URLQueryItem(name: "input", value: "text"), URLQueryItem(name: "text", value: String(shortcutInput.prefix(4000)))] }
                        pending = url.url; confirm = true
                    }
                    Text("L’AI può spiegarti come costruire il comando, ma non lo installa o modifica da sola. Avvialo solo se conosci le sue azioni: un comando può modificare dati. iOS può chiedere ulteriori permessi.").font(.caption)
                }
                Section("Dalla chat o dalla voce") {
                    Text("Scrivi o detta: Apri WhatsApp, Prepara un messaggio, Avvia navigazione oppure Apri comandi rapidi. La richiesta apre questa schermata: completa i dati e usa i pulsanti.").font(.footnote)
                    Text("Per ascoltare le risposte, attiva Leggi automaticamente le risposte nell’ingranaggio della Chat. Non vengono premuti pulsanti in altre app o modificate impostazioni di sistema.").font(.caption)
                }
            }.navigationTitle("Azioni assistente")
                .confirmationDialog("Controlla i campi sopra. Aprire l’app con questi dati? Per un Comando Rapido questo ne avvia l’esecuzione.", isPresented: $confirm, titleVisibility: .visible) {
                    Button("Conferma e apri") { if let url = pending { launch(url) }; pending = nil }
                    Button("Annulla", role: .cancel) { pending = nil }
                }
                .alert("Azioni", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
        }.tint(.mint)
    }
    private func launch(_ url: URL) {
        openURL(url) { accepted in
            if !accepted { error = "iOS non ha aperto il collegamento. Verifica che l’app richiesta sia installata." }
        }
    }
    static func recognizes(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!"))
        return ["/azioni", "apri whatsapp", "prepara un messaggio", "prepara un messaggio whatsapp", "avvia navigazione", "apri comandi rapidi"].contains(value)
    }
}
