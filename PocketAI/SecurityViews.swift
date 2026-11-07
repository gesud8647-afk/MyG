import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import Vision
import UIKit

struct SecurityHub: View {
    @Binding var path: [SecurityRoute]
    let explain: (String) -> Void
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Text("Verifiche concrete. Spiegazioni locali.").font(.title2.bold())
                    Text("Questi strumenti funzionano senza Qwen. L’AI può spiegare un estratto dei risultati, senza inventare controlli eseguiti.").font(.subheadline).foregroundStyle(.secondary)
                }
                Section("Analisi locale") {
                    NavigationLink(value: SecurityRoute.links("")) { Label("Analizza link", systemImage: "link") }
                    NavigationLink(value: SecurityRoute.qr) { Label("Leggi QR da foto", systemImage: "qrcode.viewfinder") }
                    NavigationLink(value: SecurityRoute.hash) { Label("Verifica file SHA-256", systemImage: "doc.badge.gearshape") }
                    NavigationLink(value: SecurityRoute.photos) { Label("Foto senza metadati", systemImage: "photo.badge.checkmark") }
                }
                Section("Rete locale") {
                    NavigationLink(value: SecurityRoute.network) { Label("Controlla porte di un tuo dispositivo", systemImage: "network") }
                    Text("Un solo IPv4 privato scelto da te. Nessun accesso a dispositivi o siti avviato dall’AI.").font(.caption)
                }
                Section("Comandi dalla chat") {
                    Text("/link https://esempio.it\n/qr\n/hash\n/foto\n/rete").font(.system(.subheadline, design: .monospaced)).textSelection(.enabled)
                    Text("I comandi aprono lo strumento: connessioni ed esportazioni richiedono il tuo tocco. Questa versione non include antivirus di sistema, scoperta completa della LAN o controllo di certificati HTTPS.").font(.caption)
                }
            }.navigationTitle("Pocket Security")
                .navigationDestination(for: SecurityRoute.self) { route in
                    switch route {
                    case .links(let text): LinkAuditView(initial: text, explain: explain)
                    case .qr: PhotoSecurityView(mode: .qr, explain: explain)
                    case .photos: PhotoSecurityView(mode: .clean, explain: explain)
                    case .hash: HashAuditView(explain: explain)
                    case .network: NetworkAuditView(explain: explain)
                    }
                }
        }.tint(.mint)
    }
}

private struct SecurityShareItem: Identifiable {
    let id = UUID()
    let values: [Any]
}
private struct SecurityShare: UIViewControllerRepresentable {
    let values: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: values, applicationActivities: nil)
    }
    func updateUIViewController(_ view: UIActivityViewController, context: Context) {}
}

struct SecurityReportView: View {
    let report: String
    let explain: (String) -> Void
    @State private var share: SecurityShareItem?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Risultati misurati").font(.headline)
            Text(report).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
            Button("Prepara spiegazione con Qwen") { explain(SecurityRules.explanationPrompt(report)) }.buttonStyle(.borderedProminent)
            Text("Prepara una bozza nella chat con un estratto di massimo 700 caratteri del report. Rivedilo e premi Invia. Non vengono avviate altre verifiche.").font(.caption).foregroundStyle(.secondary)
            Button("Condividi report") { share = SecurityShareItem(values: ["Pocket Security · \(Date().formatted())\n\n" + report]) }.buttonStyle(.bordered)
            Text("I report possono contenere indirizzi e dettagli privati: scegli tu se condividerli.").font(.caption).foregroundStyle(.secondary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.mint.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .sheet(item: $share) { SecurityShare(values: $0.values) }
    }
}

struct LinkAuditView: View {
    let initial: String
    let explain: (String) -> Void
    @State private var input = ""
    @State private var result: LinkAudit?
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Leggi il dominio prima di aprire.").font(.title2.bold())
                TextField("https://esempio.it/percorso", text: $input, axis: .vertical)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                Button("Analizza senza aprire") {
                    do { result = try SecurityRules.auditLink(input); error = nil }
                    catch { result = nil; self.error = error.localizedDescription }
                }.buttonStyle(.borderedProminent)
                if let error = error { Text(error).foregroundStyle(.orange) }
                if let result = result {
                    Text("HOST EFFETTIVO").font(.caption.bold()).foregroundStyle(.mint)
                    Text(result.host).font(.title3.monospaced()).textSelection(.enabled)
                    Text("URL interpretato").font(.caption)
                    Text(result.destination).font(.footnote.monospaced()).textSelection(.enabled)
                    SecurityReportView(report: result.report, explain: explain)
                }
                Text("Nessuna richiesta Internet viene effettuata. Questo controllo non conosce reputazione, redirect o contenuti del sito.").font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.navigationTitle("Analisi link").onAppear { input = initial }
    }
}

struct HashAuditView: View {
    let explain: (String) -> Void
    @State private var importing = false
    @State private var busy = false
    @State private var progress: Double = 0
    @State private var digest: FileDigest?
    @State private var expected = ""
    @State private var error: String?
    @State private var cancellation = WorkCancellation()
    private var report: String {
        guard let d = digest else { return "" }
        let supplied = expected.trimmingCharacters(in: .whitespacesAndNewlines)
        let comparison: String
        if supplied.isEmpty { comparison = "Nessuna impronta di riferimento fornita." }
        else if let normalized = SecurityRules.normalizedSHA256(supplied) {
            comparison = normalized == d.sha256 ? "Impronta corrispondente al riferimento fornito." : "Impronta DIFFERENTE dal riferimento fornito."
        } else { comparison = "Riferimento non valido: servono 64 cifre esadecimali SHA-256." }
        return "FILE: \(d.name)\nByte letti: \(d.bytes)\nSHA-256: \(d.sha256)\n\(comparison)\nLimiti: un hash corrispondente verifica l’identità rispetto al riferimento, non l’assenza di malware. Usa una fonte ufficiale affidabile."
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Confronta il file con la fonte originale.").font(.title2.bold())
                Button("Scegli un file") { importing = true }.buttonStyle(.borderedProminent).disabled(busy)
                if busy {
                    ProgressView(value: progress)
                    Button("Annulla lettura") { cancellation.cancel() }
                }
                TextField("SHA-256 ufficiale facoltativo", text: $expected, axis: .vertical)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                if let error = error { Text(error).foregroundStyle(.orange) }
                if digest != nil { SecurityReportView(report: report, explain: explain) }
                Text("Il file viene letto a blocchi sul telefono, senza upload. Il limite del prototipo è 2 GB. Per file in iCloud può servire prima il download.").font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.navigationTitle("SHA-256 file")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.data, .content]) { result in
                switch result {
                case .success(let url):
                    busy = true; progress = 0; digest = nil; error = nil
                    let operation = WorkCancellation(); cancellation = operation
                    SecurityFiles.digest(url, cancellation: operation, progress: { progress = $0 }) { result in
                        busy = false
                        switch result {
                        case .success(let value): digest = value; progress = 1
                        case .failure(let failure): error = failure.localizedDescription
                        }
                    }
                case .failure(let failure): error = failure.localizedDescription
                }
            }
            .onDisappear { cancellation.cancel() }
    }
}

struct PhotoSecurityView: View {
    enum Mode: Equatable { case qr, clean }
    let mode: Mode
    let explain: (String) -> Void
    @State private var selection: PhotosPickerItem?
    @State private var busy = false
    @State private var output: [String] = []
    @State private var cleaned: URL?
    @State private var error: String?
    @State private var share: SecurityShareItem?
    private var report: String {
        if mode == .clean {
            return "COPIA FOTO\nImmagine ricodificata JPEG, lato massimo 4096 px.\nControllo sul file risultante: dizionario GPS assente; dizionario EXIF assente.\nL’originale resta invariato. Possibili perdita di qualità, animazione e HDR. Questo non rimuove informazioni visibili nella foto, come volti, targhe o indirizzi."
        }
        let descriptions = output.enumerated().map { index, value -> String in
            if value.uppercased().hasPrefix("WIFI:") { return "QR \(index + 1): configurazione Wi-Fi. Credenziali escluse dal report." }
            if let audit = try? SecurityRules.auditLink(value) { return "QR \(index + 1): URL, schema \(audit.scheme), host \(audit.host). Nessuna apertura." }
            return "QR \(index + 1): testo o formato non URL, \(value.count) caratteri. Contenuto escluso dal report."
        }
        return "LETTURA QR LOCALE\n" + descriptions.joined(separator: "\n") + "\nLimiti: una decodifica non autentica il mittente o la sicurezza. Nessun URL o azione viene aperto automaticamente."
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(mode == .qr ? "Ispeziona il QR prima di usarlo." : "Condividi una copia, non i metadati.").font(.title2.bold())
                PhotosPicker(selection: $selection, matching: .images) {
                    Label("Scegli una foto", systemImage: "photo")
                }.buttonStyle(.borderedProminent).disabled(busy)
                if busy { ProgressView("Elaborazione locale…") }
                if let error = error { Text(error).foregroundStyle(.orange) }
                if mode == .qr {
                    ForEach(output.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QR \(index + 1)").font(.headline)
                            Text(output[index]).font(.footnote.monospaced()).textSelection(.enabled)
                            if let audit = try? SecurityRules.auditLink(output[index]) {
                                Text("Host: \(audit.host)").foregroundStyle(.mint)
                                NavigationLink("Analizza questo URL") { LinkAuditView(initial: output[index], explain: explain) }
                            }
                        }.padding().background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                if let cleaned = cleaned {
                    Button("Esporta copia JPEG") { share = SecurityShareItem(values: [cleaned]) }.buttonStyle(.bordered)
                }
                if !output.isEmpty || cleaned != nil { SecurityReportView(report: report, explain: explain) }
                Text("Elaborazione locale. Il selettore può scaricare foto da iCloud. Non modifica l’originale e non invia l’immagine a Qwen. Per QR difficili scegli un’immagine nitida e ritagliata.").font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.navigationTitle(mode == .qr ? "Ispeziona QR" : "Rimuovi metadati")
            .task(id: selection) { await process() }
            .sheet(item: $share) { SecurityShare(values: $0.values) }
    }
    @MainActor private func process() async {
        guard let selection = selection else { return }
        busy = true; error = nil; output = []; cleaned = nil
        defer { busy = false }
        do {
            guard let raw = try await selection.loadTransferable(type: Data.self) else { throw SecurityFiles.FileError.badImage }
            try Task.checkCancellation()
            if mode == .qr {
                let values = try await Task.detached(priority: .userInitiated) { () -> [String] in
                    let image = try SecurityFiles.image(raw)
                    let request = VNDetectBarcodesRequest()
                    request.symbologies = [.qr]
                    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                    return (request.results ?? []).compactMap(\.payloadStringValue)
                }.value
                try Task.checkCancellation()
                output = values
                if values.isEmpty { error = "Nessun QR leggibile rilevato nell’immagine. Non significa che sia sicura o priva di altri codici." }
            } else {
                let result = try await Task.detached(priority: .userInitiated) { try SecurityFiles.cleanedPhoto(raw) }.value
                try Task.checkCancellation()
                cleaned = result.0
            }
        } catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}

struct NetworkAuditView: View {
    let explain: (String) -> Void
    @StateObject private var probe = LocalPortProbe()
    @Environment(\.scenePhase) private var phase
    @State private var ip = ""
    @State private var selected: Set<UInt16> = [80, 443]
    @State private var authorized = false
    @State private var checkedHost = ""
    private let ports: [UInt16] = [22, 80, 443, 445, 3389, 8080]
    private var report: String {
        "CONNESSIONI TCP\nHost scelto: \(checkedHost)\n" + probe.results.map { "\($0.port): \($0.status)" }.joined(separator: "\n") + "\n\(probe.message)\nLimiti: una porta raggiungibile non dimostra una vulnerabilità o quale servizio la usi. Timeout e fallimenti possono dipendere da firewall, permessi iOS o rete. Nessuna autenticazione o scansione dell’intera rete."
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Un dispositivo, le porte che scegli.").font(.title2.bold())
                TextField("IPv4 privato, es. 192.168.1.1", text: $ip).keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder).disabled(probe.running)
                Text("Accetta soltanto indirizzi privati 10.x.x.x, 172.16–31.x.x e 192.168.x.x. Nessuna ricerca automatica di bersagli.").font(.caption).foregroundStyle(.secondary)
                ForEach(ports, id: \.self) { port in
                    Toggle("Porta TCP \(port)", isOn: Binding(get: { selected.contains(port) }, set: { value in
                        if value { selected.insert(port) } else { selected.remove(port) }
                    })).disabled(probe.running)
                }
                Toggle("È un dispositivo mio o ho autorizzazione a verificarlo", isOn: $authorized).disabled(probe.running)
                if probe.running {
                    ProgressView()
                    Button("Ferma controllo") { probe.stop() }.buttonStyle(.bordered)
                } else {
                    Button("Avvia connessioni selezionate") {
                        guard let target = SecurityRules.privateIPv4(ip) else { return }
                        checkedHost = target
                        probe.start(host: target, ports: Array(selected))
                    }.buttonStyle(.borderedProminent)
                        .disabled(!authorized || selected.isEmpty || SecurityRules.privateIPv4(ip) == nil)
                }
                Text(probe.message).font(.caption)
                if !probe.results.isEmpty { SecurityReportView(report: report, explain: explain) }
                Text("Serve il permesso Rete locale. Il primo tentativo può scadere mentre autorizzi: dopo aver consentito, ripeti. Le connessioni non inviano credenziali o comandi applicativi.").font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.navigationTitle("Controllo rete locale")
            .onDisappear { probe.stop() }
            .onChange(of: phase) { if $0 == .background { probe.stop() } }
    }
}
