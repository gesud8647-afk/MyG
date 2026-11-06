import SwiftUI
import UniformTypeIdentifiers
import UIKit

private struct BackupFile: Identifiable { let id = UUID(); let url:URL }

struct SettingsView: View {
    @ObservedObject var store: EcoStore
    @Environment(\.dismiss) private var dismiss
    @State private var backup: BackupFile?
    @State private var erase = false
    @State private var exportConfirm = false
    @State private var importConfirm = false
    @State private var importing = false
    @State private var feedback: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("ECO · Primo Legame 0.1") {
                    Text("Tre luoghi, la famiglia Lume e cinque trasformazioni. Il prototipo non contiene acquisti, abbonamenti, pubblicità o account.")
                    Text("Le missioni sono proposte creative e la loro esecuzione è dichiarata da te. Non usiamo un’AI per verificare comportamenti o emozioni.")
                }
                Section("I tuoi dati") {
                    Text("Diario, foto e luoghi sono salvati nella sandbox dell’app. Possono essere inclusi nei backup del tuo iPhone. Non ci sono server ECO e non vendiamo le tue posizioni.")
                    Text("La posizione è richiesta solo dopo un tuo tocco, con app aperta. Il GPS può essere impreciso. La mappa contatta Apple per l’area visualizzata. Il selettore foto può scaricare da iCloud le immagini che scegli.")
                    if store.readOnly { Text("Diario non leggibile: esporta il file originale prima di ripristinare.").foregroundStyle(.orange) }
                    Button("Esporta backup completo") { exportConfirm = true }
                    Button("Importa e sostituisci da backup") { importConfirm = true }
                    Text("Il backup include foto, testi e coordinate. Salvalo in un posto privato. Le copie esportate non vengono cancellate dall’app.").font(.caption)
                }
                Section("Regole") {
                    Text("Ritorni: massimo un punto per giorno e luogo. Memorie: massimo un punto al giorno se conservi testo o foto. Curiosità: due punti per ciascuna delle dieci missioni diverse, una volta sola. Soglie: 0, 4, 9, 16 e 25.")
                    Text("Puoi aggiungere più ricordi senza moltiplicare i punti della giornata. Dopo sette giorni senza visite l’eco riposa, senza perdere progressi. I giorni seguono il calendario locale del telefono; questo prototipo non ha un sistema anti-manomissione.")
                }
                Section {
                    Button("Cancella tutti i dati ECO",role:.destructive) { erase = true }
                }
            }.navigationTitle("Info e backup")
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Fine") { dismiss() } } }
                .sheet(item:$backup) { ShareBackup(url:$0.url) }
                .confirmationDialog("Il backup contiene i tuoi ricordi, foto e coordinate. Vuoi esportarlo?",isPresented:$exportConfirm,titleVisibility:.visible) {
                    Button("Esporta") {
                        if let url = store.export() { backup = BackupFile(url:url) }
                        else { feedback = store.error; store.error = nil }
                    }
                }
                .confirmationDialog("L’importazione sostituirà il diario attuale. Esporta prima un backup se vuoi conservarlo.",isPresented:$importConfirm,titleVisibility:.visible) {
                    Button("Scegli backup da importare",role:.destructive) { importing = true }
                }
                .fileImporter(isPresented:$importing,allowedContentTypes:[.json]) { result in
                    switch result {
                    case .success(let url):
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        if store.importBackup(url) { feedback = "Backup importato." }
                        else { feedback = store.error; store.error = nil }
                    case .failure(let error): feedback = error.localizedDescription
                    }
                }
                .confirmationDialog("Eliminare definitivamente luoghi, foto e diario da questa app?",isPresented:$erase,titleVisibility:.visible) {
                    Button("Elimina tutto",role:.destructive) { store.erase() }
                }
                .alert("Backup",isPresented:Binding(get:{feedback != nil},set:{if !$0 { feedback = nil }})) {
                    Button("OK",role:.cancel) { feedback = nil }
                } message: { Text(feedback ?? "") }
        }.tint(.ecoAccent)
    }
}

private struct ShareBackup: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context:Context) -> UIActivityViewController {
        UIActivityViewController(activityItems:[url],applicationActivities:nil)
    }
    func updateUIViewController(_ controller:UIActivityViewController,context:Context) {}
}
