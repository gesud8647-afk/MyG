import SwiftUI
import UIKit

private struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ContentView: View {
    @StateObject private var scanner = BluetoothScanner()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("myg.signature") private var signature = ""
    @State private var message = ""
    @State private var selected: UUID?
    @State private var shareFile: ShareFile?
    @State private var error: String?
    @State private var shareStatus = ""
    @State private var query = ""

    private var devices: [NearbyDevice] {
        scanner.devices.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)
        }.sorted { ($0.rssi ?? -999) > ($1.rssi ?? -999) }
    }
    private var selectedDevice: NearbyDevice? {
        scanner.devices.first { $0.id == selected }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.largeTitle).foregroundStyle(.mint)
                        VStack(alignment: .leading) {
                            Text("MY G").font(.largeTitle.bold())
                            Text("Segnali vicini. Parole tue.").foregroundStyle(.secondary)
                        }
                    }
                    scanCard
                    deviceList
                    composer
                    Text("La scansione mostra solo periferiche BLE rilevabili, non tutti i telefoni. I nomi non verificano l’identità. Il segnale non indica direzione o distanza precisa. Nessuna connessione ai dispositivi viene effettuata.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }
            .background(Color(red: 0.035, green: 0.055, blue: 0.085))
            .navigationTitle("My G").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $shareFile, onDismiss: { shareFile = nil }) { file in
                SystemShare(url: file.url) { completed in
                    shareStatus = completed ? "Condivisione completata secondo iOS." : "Condivisione annullata o non completata."
                }
            }
            .alert("Impossibile preparare il messaggio", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) { error = nil }
                } message: { Text(error ?? "") }
            .onChange(of: scenePhase) { phase in
                if phase != .active { scanner.stop() }
            }
        }.tint(.mint)
    }

    private var scanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(scanner.scanning ? "IN ASCOLTO" : "SCANNER BLUETOOTH",
                  systemImage: scanner.scanning ? "waveform" : "antenna.radiowaves.left.and.right")
                .font(.headline).foregroundStyle(.mint)
            Text(scanner.status).font(.subheadline)
            HStack {
                Button(scanner.scanning ? "Ferma" : "Avvia scansione") {
                    if scanner.scanning { scanner.stop() } else { scanner.start() }
                }.buttonStyle(.borderedProminent)
                Button("Cancella risultati") { scanner.clear(); selected = nil }
                    .buttonStyle(.bordered).disabled(scanner.devices.isEmpty)
            }
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dispositivi rilevati · \(scanner.devices.count)").font(.title3.bold())
            TextField("Filtra per nome", text: $query).textFieldStyle(.roundedBorder)
            if devices.isEmpty {
                Text(scanner.scanning ? "In attesa di segnali BLE…" : "Nessun risultato. Avvia la scansione vicino a una periferica BLE accesa.")
                    .foregroundStyle(.secondary).padding(.vertical)
            }
            ForEach(devices) { device in
                Button { selected = device.id } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: selected == device.id ? "checkmark.circle.fill" : "circle")
                            Text(device.name).font(.headline).multilineTextAlignment(.leading)
                            Spacer()
                            Text(device.rssi.map { "\($0) dBm" } ?? "N/D").font(.caption.monospaced())
                        }
                        Text(device.id.uuidString).font(.caption2.monospaced()).foregroundStyle(.secondary)
                        HStack {
                            Text("Ultimo segnale")
                            Text(device.lastSeen, style: .time)
                        }.font(.caption).foregroundStyle(.secondary)
                        if !device.services.isEmpty {
                            Text("Servizi: " + device.services.joined(separator: ", "))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected == device.id ? Color.mint.opacity(0.12) : Color.white.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain)
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Il tuo messaggio").font(.title3.bold())
            if let device = selectedDevice {
                Label("Riferimento BLE: \(device.name)", systemImage: "dot.radiowaves.right")
                    .font(.subheadline).foregroundStyle(.mint)
            }
            Text("Il riferimento BLE non seleziona il destinatario AirDrop. Lo sceglierai nel pannello Apple.")
                .font(.footnote).foregroundStyle(.secondary)
            TextEditor(text: $message).frame(height: 140).padding(8)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Testo del messaggio")
            TextField("Firma o tuo numero (facoltativo)", text: $signature)
                .textFieldStyle(.roundedBorder).textContentType(.telephoneNumber)
            Text("Firma dichiarata da te, senza verifica del numero. Viene inclusa nel file condiviso.")
                .font(.caption).foregroundStyle(.secondary)
            Button(action: prepareShare) {
                Label("Condividi → AirDrop", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity).padding(.vertical, 5)
            }.buttonStyle(.borderedProminent)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("Nel pannello di condivisione scegli AirDrop e poi il destinatario. Riceverà un file di testo da accettare. Puoi anche scegliere altre app.")
                .font(.footnote).foregroundStyle(.secondary)
            if !shareStatus.isEmpty { Text(shareStatus).font(.footnote) }
            Button("Elimina firma e bozza", role: .destructive) {
                signature = ""; message = ""; shareStatus = ""
            }.font(.footnote)
        }.padding().background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    private func prepareShare() {
        let body = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let signed = signature.trimmingCharacters(in: .whitespacesAndNewlines)
        let contents = body + (signed.isEmpty ? "" : "\n\nFirma dichiarata dal mittente: " + signed)
        do {
            scanner.stop()
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MyG-Shares", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            // Delete only files produced by this app on earlier shares.
            for old in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                try? FileManager.default.removeItem(at: old)
            }
            let url = folder.appendingPathComponent("MyG-messaggio-\(UUID().uuidString.prefix(8)).txt")
            try contents.write(to: url, atomically: true, encoding: .utf8)
            shareStatus = ""
            shareFile = ShareFile(url: url)
        } catch { self.error = error.localizedDescription }
    }
}

private struct SystemShare: UIViewControllerRepresentable {
    let url: URL
    let completion: (Bool) -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            DispatchQueue.main.async { completion(completed) }
        }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
