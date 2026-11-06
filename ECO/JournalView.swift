import SwiftUI
import UIKit

private struct JournalMoment: Identifiable {
    let placeName: String
    let entry: EcoEntry
    var id: UUID { entry.id }
}

struct JournalView: View {
    @ObservedObject var store: EcoStore
    @State private var query = ""
    private var entries: [JournalMoment] {
        store.places.flatMap { place in
            place.entries.map { JournalMoment(placeName: place.name, entry: $0) }
        }.filter {
            query.isEmpty || $0.placeName.localizedCaseInsensitiveContains(query) || $0.entry.note.localizedCaseInsensitiveContains(query)
        }.sorted { $0.entry.date > $1.entry.date }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:16) {
                Text("Le cose che hai scelto di ricordare.").font(.title.bold())
                TextField("Cerca un luogo o una parola",text:$query).textFieldStyle(.roundedBorder)
                if entries.isEmpty { Text("Il diario aspetta il tuo primo momento.").foregroundStyle(.secondary).ecoCard() }
                ForEach(entries) { moment in EntryCard(entry:moment.entry,placeName:moment.placeName) }
            }.padding()
        }.background(Color.ecoBackground).navigationTitle("Il tuo diario")
    }
}

struct EntryCard: View {
    let entry: EcoEntry
    let placeName: String
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            HStack { Text(placeName).font(.headline); Spacer(); Image(systemName:entry.mood.symbol).foregroundStyle(entry.mood.tint) }
            Text(entry.date,format:.dateTime.day().month().year().hour().minute()).font(.caption).foregroundStyle(.secondary)
            if !entry.note.isEmpty { Text(entry.note).textSelection(.enabled) }
            else if entry.photo == nil { Text("Un momento di presenza.").foregroundStyle(.secondary) }
            if let data = entry.photo, let image = UIImage(data:data) {
                Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:260).clipShape(RoundedRectangle(cornerRadius:14))
            }
            if let id = entry.missionID, let mission = EcoMission.all.first(where:{$0.id == id}) {
                Label(mission.title,systemImage:"sparkles").font(.caption).foregroundStyle(Color.ecoAccent)
            }
            Text(entry.presenceConfirmed ? "Vicinanza GPS indicativa" : "Ricordo manuale · posizione non verificata")
                .font(.caption2).foregroundStyle(.secondary)
        }.ecoCard()
    }
}
