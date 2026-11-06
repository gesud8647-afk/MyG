import Foundation
import Combine

final class EcoStore: ObservableObject {
    @Published private(set) var archive = EcoArchive()
    @Published var error: String?
    @Published private(set) var readOnly = false
    private let url: URL
    var places: [EcoPlace] { archive.places }

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        url = fileURL ?? base.appendingPathComponent("ECO", isDirectory: true).appendingPathComponent("eco-v1.json")
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let saved = try JSONDecoder().decode(EcoArchive.self, from: Data(contentsOf: url))
                guard saved.version == 1, saved.places.count <= 3 else { throw CocoaError(.fileReadCorruptFile) }
                archive = saved
            }
        } catch {
            readOnly = true
            self.error = "Il diario non è leggibile. Il file originale è conservato: non verrà sovrascritto. Esporta il backup originale dalle Info prima di un eventuale ripristino."
        }
    }
    private func commit(_ next: EcoArchive) throws {
        guard !readOnly else { throw CocoaError(.fileWriteNoPermission) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(next)
        guard data.count <= 64_000_000 else { throw CocoaError(.fileWriteOutOfSpace) }
        var options: Data.WritingOptions = [.atomic]
        #if os(iOS)
        options.insert(.completeFileProtectionUnlessOpen)
        #endif
        try data.write(to: url, options: options)
        archive = next
    }
    func addPlace(name: String, mood: EcoMood, coordinate: EcoCoordinate?) -> UUID? {
        guard places.count < 3 else { error = "Questa prima versione contiene al massimo tre luoghi."; return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60 else { error = "Scegli un nome da 1 a 60 caratteri."; return nil }
        if let coordinate = coordinate, !coordinate.valid { error = "Posizione non valida."; return nil }
        let now = Date()
        let entry = EcoEntry(date: now, mood: mood, note: "", missionID: nil, photo: nil, presenceConfirmed: coordinate != nil)
        let place = EcoPlace(name: trimmed, createdAt: now, coordinate: coordinate, seed: Int.random(in: 0..<10), entries: [entry])
        var next = archive; next.places.append(place)
        do { try commit(next); return place.id } catch { self.error = "Salvataggio non riuscito: \(error.localizedDescription)"; return nil }
    }
    @discardableResult func record(id: UUID, mood: EcoMood, note: String, photo: Data?, missionID: Int?, presence: Bool) -> Bool {
        guard let index = archive.places.firstIndex(where: { $0.id == id }) else { return false }
        let now = Date()
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 2000 else { error = "Il ricordo può contenere al massimo 2000 caratteri."; return false }
        if let photo = photo, photo.count > 2_000_000 { error = "Foto troppo grande."; return false }
        if let missionID = missionID {
            guard missionID == EcoRules.mission(places[index], now: now).id,
                  EcoRules.canComplete(places[index], now: now), trimmed.count >= 12 || photo != nil else {
                error = "Puoi completare una missione al giorno per luogo, aggiungendo una foto o almeno 12 caratteri."; return false
            }
        }
        if missionID == nil && trimmed.isEmpty && photo == nil && EcoRules.hasVisited(places[index], now: now) {
            error = "Hai già registrato la presenza di oggi. Puoi aggiungere un ricordo o tornare domani."; return false
        }
        var next = archive
        next.places[index].entries.append(EcoEntry(date: now, mood: mood, note: trimmed, missionID: missionID, photo: photo, presenceConfirmed: presence))
        do { try commit(next); return true } catch { self.error = "Salvataggio non riuscito: \(error.localizedDescription)"; return false }
    }
    func remove(_ id: UUID) {
        var next = archive; next.places.removeAll { $0.id == id }
        do { try commit(next) } catch { self.error = "Eliminazione non riuscita: \(error.localizedDescription)" }
    }
    func export() -> URL? {
        do {
            let target = FileManager.default.temporaryDirectory.appendingPathComponent("ECO-backup.json")
            let data: Data
            if FileManager.default.fileExists(atPath: url.path) { data = try Data(contentsOf: url) }
            else { data = try JSONEncoder().encode(archive) }
            var options: Data.WritingOptions = [.atomic]
            #if os(iOS)
            options.insert(.completeFileProtectionUnlessOpen)
            #endif
            try data.write(to: target, options: options)
            return target
        } catch { self.error = "Backup non riuscito: \(error.localizedDescription)"; return nil }
    }
    @discardableResult func importBackup(_ source: URL) -> Bool {
        do {
            let size = try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 64_000_000 else { throw CocoaError(.fileReadTooLarge) }
            let candidate = try JSONDecoder().decode(EcoArchive.self, from: Data(contentsOf: source))
            guard candidate.version == 1, candidate.places.count <= 3,
                  Set(candidate.places.map(\.id)).count == candidate.places.count else { throw CocoaError(.fileReadCorruptFile) }
            for place in candidate.places {
                guard !place.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, place.name.count <= 60,
                      place.coordinate == nil || place.coordinate?.valid == true,
                      (0..<10).contains(place.seed), !place.entries.isEmpty,
                      Set(place.entries.map(\.id)).count == place.entries.count else { throw CocoaError(.fileReadCorruptFile) }
                for entry in place.entries {
                    guard entry.note.count <= 2000, (entry.photo?.count ?? 0) <= 2_000_000,
                          entry.missionID == nil || (0..<10).contains(entry.missionID!) else { throw CocoaError(.fileReadCorruptFile) }
                }
            }
            let wasReadOnly = readOnly
            readOnly = false
            do { try commit(candidate); return true }
            catch { readOnly = wasReadOnly; throw error }
        } catch { self.error = "Backup non valido o non salvabile: \(error.localizedDescription)"; return false }
    }

    func erase() {
        do {
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("ECO-backup.json"))
            archive = EcoArchive(); readOnly = false
        } catch { self.error = "Cancellazione non riuscita: \(error.localizedDescription)" }
    }
}
