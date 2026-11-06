import SwiftUI
import UIKit
import CoreLocation
import PhotosUI
import ImageIO

struct CreatePlaceView: View {
    @ObservedObject var store: EcoStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @StateObject private var location = EcoLocation()
    @State private var name = ""
    @State private var mood = EcoMood.calma
    @State private var useGPS = false
    @State private var failure: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Il tuo luogo") {
                    TextField("Un nome, ad esempio La piazza",text:$name)
                    Picker("Sensazione",selection:$mood) { ForEach(EcoMood.allCases) { Text($0.rawValue).tag($0) } }
                    Text("Il luogo e i ricordi saranno privati. Non scegliere una posizione che vuoi rendere pubblica: ECO non ha una mappa condivisa.").font(.caption)
                }
                Section("Posizione facoltativa") {
                    Button(location.busy ? "Cerco…" : "Usa la mia posizione attuale") { location.request() }.disabled(location.busy)
                    Text(location.status).font(.caption)
                    Toggle("Salva la posizione di questo luogo",isOn:$useGPS)
                    Text("Senza posizione il luogo è manuale e non comparirà sulla mappa. Una posizione GPS è una stima, non un confine preciso.").font(.caption)
                }
                Section {
                    Button("Fai nascere la tua eco") {
                        let coordinate = useGPS ? location.coordinate : nil
                        if useGPS && coordinate == nil { failure = "Richiedi una posizione recente oppure disattiva il salvataggio della posizione."; return }
                        if store.addPlace(name:name,mood:mood,coordinate:coordinate) != nil { dismiss() }
                        else { failure = store.error; store.error = nil }
                    }.disabled(name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || store.readOnly)
                }
            }.navigationTitle("Un nuovo legame")
                .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Annulla") { dismiss() } } }
                .onReceive(location.$fix) { fix in if fix != nil { useGPS = true } }
                .onDisappear { location.cancel() }
                .onChange(of:phase) { if $0 == .background { location.cancel() } }
                .alert("Nuovo luogo",isPresented:Binding(get:{failure != nil},set:{if !$0 { failure = nil }})) {
                    Button("OK",role:.cancel) { failure = nil }
                } message: { Text(failure ?? "") }
        }.tint(.ecoAccent)
    }
}

struct PlaceDetailView: View {
    @ObservedObject var store: EcoStore
    let id: UUID
    @State private var record = false
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    private var place: EcoPlace? { store.places.first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let place = place {
                let progress = EcoRules.progress(place)
                VStack(alignment:.leading,spacing:20) {
                    CreatureView(stage:progress.stage,mood:place.mood,sleeping:EcoRules.sleeping(place,now:Date()))
                    Text(EcoRules.stages[progress.stage]).font(.largeTitle.bold()).foregroundStyle(place.mood.tint)
                    Text(EcoRules.story(place,now:Date())).font(.body)
                    VStack(alignment:.leading,spacing:12) {
                        Text("Il tuo legame").font(.headline)
                        HStack { metric("Ritorni",progress.familiarity); Spacer(); metric("Novità",progress.curiosity); Spacer(); metric("Memorie",progress.memories) }
                        if let threshold = progress.nextThreshold {
                            ProgressView(value:Double(progress.score),total:Double(threshold)).tint(place.mood.tint)
                            Text("\(progress.score) / \(threshold) passi di legame verso la prossima forma").font(.caption)
                        } else { Text("Ultima forma raggiunta. I ricordi possono continuare.").font(.caption) }
                        Text("Un ritorno e una memoria al giorno contano per la crescita. Ogni missione diversa aggiunge curiosità una sola volta.").font(.caption).foregroundStyle(.secondary)
                    }.ecoCard()
                    VStack(alignment:.leading,spacing:12) {
                        Text("LA PROPOSTA DI OGGI").font(.caption.bold()).tracking(2).foregroundStyle(Color.ecoAccent)
                        Text(EcoRules.mission(place,now:Date()).title).font(.title2.bold())
                        Text(EcoRules.mission(place,now:Date()).prompt)
                        Button("Aggiungi presenza o ricordo") { record = true }.buttonStyle(.borderedProminent).disabled(store.readOnly)
                        if !EcoRules.canComplete(place,now:Date()) { Text("Missione di oggi già registrata. Puoi comunque aggiungere ricordi.").font(.caption) }
                    }.ecoCard()
                    Text(place.coordinate == nil ? "Luogo manuale · nessuna posizione salvata" : "Luogo con posizione salvata · visite GPS o manuali")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Ultimi ricordi").font(.title3.bold())
                    ForEach(Array(place.entries.sorted { $0.date > $1.date }.prefix(5))) { entry in
                        EntryCard(entry:entry,placeName:place.name)
                    }
                    Button("Elimina questo luogo e i suoi ricordi",role:.destructive) { deleting = true }.font(.footnote)
                }.padding()
            }
        }.background(Color.ecoBackground).navigationTitle(place?.name ?? "Luogo").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$record) { if let place = place { RecordView(store:store,place:place) } }
            .confirmationDialog("Eliminare definitivamente il luogo e tutti i suoi ricordi?",isPresented:$deleting,titleVisibility:.visible) {
                Button("Elimina",role:.destructive) {
                    store.remove(id)
                    if store.places.first(where:{$0.id == id}) == nil { dismiss() }
                }
            }
    }
    private func metric(_ title:String,_ number:Int) -> some View {
        VStack(alignment:.leading) { Text("\(number)").font(.title2.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }
    }
}

struct RecordView: View {
    @ObservedObject var store: EcoStore
    let place: EcoPlace
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @StateObject private var location = EcoLocation()
    @State private var mood = EcoMood.calma
    @State private var note = ""
    @State private var completeMission = false
    @State private var selection: PhotosPickerItem?
    @State private var photo: Data?
    @State private var loadingPhoto = false
    @State private var feedback: String?
    @State private var manualConfirmed = false
    private var near: Bool { location.isNear(place.coordinate) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Come ti senti qui?") {
                    Picker("Sensazione",selection:$mood) { ForEach(EcoMood.allCases) { Text($0.rawValue).tag($0) } }
                    TextEditor(text:$note).frame(minHeight:120).accessibilityLabel("Il tuo ricordo")
                    Text("\(note.count) / 2000 caratteri").font(.caption)
                    PhotosPicker(selection:$selection,matching:.images) { Label("Scegli una tua foto",systemImage:"photo") }
                    if loadingPhoto { ProgressView("Preparo la foto…") }
                    if let photo = photo, let image = UIImage(data:photo) {
                        Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:160)
                        Button("Rimuovi foto",role:.destructive) { selection = nil; self.photo = nil }
                    }
                }
                Section("La proposta di oggi") {
                    Text(EcoRules.mission(place,now:Date()).title).font(.headline)
                    Text(EcoRules.mission(place,now:Date()).prompt)
                    Toggle("Ho svolto questa proposta",isOn:$completeMission).disabled(!EcoRules.canComplete(place,now:Date()))
                    Text("È una tua dichiarazione, non un’attività riconosciuta dall’AI. Per registrarla servono almeno 12 caratteri o una foto. Una missione al giorno per luogo.").font(.caption)
                }
                Section("Presenza") {
                    if place.coordinate != nil {
                        Button(location.busy ? "Verifica in corso…" : "Verifica la vicinanza con GPS") { location.request() }.disabled(location.busy)
                        Text(location.status).font(.caption)
                    }
                    if near { Label("Rilevamento GPS compatibile con il luogo (entro 100 m)",systemImage:"location.fill").foregroundStyle(Color.ecoAccent) }
                    else {
                        Toggle("Registro manualmente questo momento",isOn:$manualConfirmed)
                        Text("Il diario indicherà modalità manuale. Non è una prova che fossi fisicamente nel luogo.").font(.caption)
                    }
                }
                Section {
                    Button("Conserva il momento") {
                        let current = store.places.first { $0.id == place.id } ?? place
                        let mission = completeMission ? EcoRules.mission(current,now:Date()).id : nil
                        if store.record(id:place.id,mood:mood,note:note,photo:photo,missionID:mission,presence:near) { dismiss() }
                        else { feedback = store.error; store.error = nil }
                    }.disabled(loadingPhoto || (!near && !manualConfirmed) || note.count > 2000 || store.readOnly)
                    Text("Tieni il telefono fermo mentre scrivi. Nessuna missione richiede di guidare, attraversare ostacoli o entrare in luoghi vietati.").font(.caption)
                }
            }.navigationTitle("Un nuovo ricordo")
                .toolbar { ToolbarItem(placement:.cancellationAction) { Button("Annulla") { dismiss() } } }
                .onAppear { mood = place.mood }
                .task(id:selection) { await loadPhoto() }
                .onDisappear { location.cancel() }
                .onChange(of:phase) { if $0 == .background { location.cancel() } }
                .alert("Ricordo",isPresented:Binding(get:{feedback != nil},set:{if !$0 { feedback = nil }})) {
                    Button("OK",role:.cancel) { feedback = nil }
                } message: { Text(feedback ?? "") }
        }.tint(.ecoAccent)
    }
    @MainActor private func loadPhoto() async {
        guard let selection = selection else { photo = nil; return }
        loadingPhoto = true
        defer { loadingPhoto = false }
        do {
            guard let raw = try await selection.loadTransferable(type:Data.self) else { throw CocoaError(.fileReadUnknown) }
            try Task.checkCancellation()
            guard raw.count <= 30_000_000,
                  let source = CGImageSourceCreateWithData(raw as CFData,nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source,0,[
                    kCGImageSourceCreateThumbnailFromImageAlways:true,
                    kCGImageSourceCreateThumbnailWithTransform:true,
                    kCGImageSourceThumbnailMaxPixelSize:1024
                  ] as CFDictionary),
                  let jpeg = UIImage(cgImage:thumbnail).jpegData(compressionQuality:0.75), jpeg.count <= 2_000_000 else {
                throw CocoaError(.fileReadTooLarge)
            }
            photo = jpeg
        } catch is CancellationError { }
        catch { photo = nil; feedback = "Non riesco a caricare questa foto. Prova una foto più piccola già disponibile sul telefono." }
    }
}
