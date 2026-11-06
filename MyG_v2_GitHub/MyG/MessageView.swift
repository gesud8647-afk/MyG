import SwiftUI
import UIKit

private struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct MessageView: View {
    @AppStorage("myg.signature") private var signature = ""
    @State private var message = ""
    @State private var shareFile: ShareFile?
    @State private var error: String?
    @State private var shareStatus = ""
    var body: some View {
        ScrollView { composer.padding() }
            .background(Color.mygBackground).navigationTitle("Messaggio e AirDrop")
            .sheet(item: $shareFile) { file in
                SystemShare(url: file.url) { completed in
                    shareStatus = completed ? "Condivisione completata secondo iOS." : "Condivisione annullata o non completata."
                }
            }
            .alert("Impossibile preparare il messaggio", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) { error = nil }
                } message: { Text(error ?? "") }
    }
    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Il tuo messaggio").font(.title3.bold())
            Text("Scegli il destinatario nel pannello Apple. La scansione BLE non seleziona un destinatario AirDrop.")
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
