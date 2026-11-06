import SwiftUI

extension Color {
    static let ecoBackground = Color(red: 0.045, green: 0.065, blue: 0.11)
    static let ecoAccent = Color(red: 0.55, green: 0.94, blue: 0.75)
}
extension View {
    func ecoCard() -> some View {
        self.padding(18).frame(maxWidth:.infinity,alignment:.leading)
            .background(Color.white.opacity(0.055),in:RoundedRectangle(cornerRadius:24))
    }
}

struct RootView: View {
    @StateObject private var store = EcoStore()
    @State private var create = false
    @State private var showIntro = false
    @State private var showSettings = false
    @AppStorage("eco.onboarding.v1") private var onboarded = false
    var body: some View {
        TabView {
            NavigationStack { today }.tabItem { Label("Oggi",systemImage:"sparkles") }
            NavigationStack { PlacesMapView(store:store) }.tabItem { Label("Luoghi",systemImage:"map") }
            NavigationStack { JournalView(store:store) }.tabItem { Label("Diario",systemImage:"book.closed") }
            NavigationStack { collection }.tabItem { Label("Forme",systemImage:"leaf") }
        }.tint(.ecoAccent)
            .sheet(isPresented:$create) { CreatePlaceView(store:store) }
            .sheet(isPresented:$showSettings) { SettingsView(store:store) }
            .sheet(isPresented:$showIntro) { introduction }
            .onAppear { if !onboarded { showIntro = true } }
            .alert("ECO",isPresented:Binding(get:{store.error != nil},set:{if !$0 { store.error = nil }})) {
                Button("OK",role:.cancel) { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
    private var today: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {
                    VStack(alignment:.leading,spacing:5) {
                        Text("PRIMO LEGAME").font(.caption.weight(.semibold)).tracking(3).foregroundStyle(Color.ecoAccent)
                        Text("Il mondo ti risponde.").font(.largeTitle.bold())
                    }
                    Spacer()
                    Button { showSettings = true } label: { Image(systemName:"gearshape").font(.title2) }.accessibilityLabel("Info, backup e dati")
                }
                if store.places.isEmpty {
                    VStack(alignment:.leading,spacing:12) {
                        CreatureView(stage:0)
                        Text("Ogni luogo può diventare una storia.").font(.title2.bold())
                        Text("Scegli un posto che senti tuo. La tua eco crescerà attraverso ritorni, dettagli nuovi e ricordi.").foregroundStyle(.secondary)
                        Button("Crea la tua prima eco") { create = true }.buttonStyle(.borderedProminent)
                    }.ecoCard()
                } else {
                    ForEach(store.places) { place in
                        NavigationLink { PlaceDetailView(store:store,id:place.id) } label: { PlaceCard(place:place) }.buttonStyle(.plain)
                    }
                    if store.places.count < 3 {
                        Button { create = true } label: { Label("Lascia una nuova eco",systemImage:"plus.circle.fill").frame(maxWidth:.infinity).padding(.vertical,6) }
                            .buttonStyle(.borderedProminent)
                    }
                }
                VStack(alignment:.leading,spacing:8) {
                    Text("La regola di ECO").font(.headline)
                    Text("La ripetizione crea il legame. La differenza crea l’evoluzione.").foregroundStyle(.secondary)
                    Text("Nessuna fretta, nessuna penalità se ti assenti.").font(.caption).foregroundStyle(.secondary)
                }.ecoCard()
            }.padding()
        }.background(Color.ecoBackground).navigationTitle("ECO").navigationBarTitleDisplayMode(.inline)
    }
    private var collection: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("Una creatura, cinque modi di crescere.").font(.title.bold())
                Text("Questa prima famiglia si chiama Lume. Le forme si sbloccano attraverso i tuoi luoghi.").foregroundStyle(.secondary)
                ForEach(0..<5,id:\.self) { stage in
                    let unlocked = store.places.contains { EcoRules.progress($0).stage >= stage }
                    VStack(alignment:.leading) {
                        CreatureView(stage:stage,silhouette:!unlocked)
                        HStack { Text(EcoRules.stages[stage]).font(.title3.bold()); Spacer(); Text(unlocked ? "Scoperta" : "Da scoprire").font(.caption) }
                    }.ecoCard()
                }
            }.padding()
        }.background(Color.ecoBackground).navigationTitle("Le forme di Lume")
    }
    private var introduction: some View {
        VStack(alignment:.leading,spacing:22) {
            Spacer()
            Text("ECO").font(.system(size:64,weight:.bold,design:.rounded)).foregroundStyle(Color.ecoAccent)
            Text("Un legame con i luoghi che vivi.").font(.largeTitle.bold())
            Text("Crea fino a tre eco. Torna quando vuoi, osserva qualcosa di nuovo e conserva un ricordo. Non devi camminare guardando lo schermo.")
            Text("Posizione facoltativa, nessun account e nessun acquisto. I ricordi restano sul tuo telefono. Puoi usare luoghi manuali senza GPS.").foregroundStyle(.secondary)
            Spacer()
            Button("Cominciamo") { onboarded = true; showIntro = false }.buttonStyle(.borderedProminent).controlSize(.large)
        }.padding(28).background(Color.ecoBackground).interactiveDismissDisabled()
    }
}

struct PlaceCard: View {
    let place: EcoPlace
    var body: some View {
        let progress = EcoRules.progress(place)
        VStack(alignment:.leading,spacing:12) {
            HStack { Text(place.name).font(.title2.bold()); Spacer(); Image(systemName:place.mood.symbol).foregroundStyle(place.mood.tint) }
            CreatureView(stage:progress.stage,mood:place.mood,sleeping:EcoRules.sleeping(place,now:Date()))
            HStack { Text(EcoRules.stages[progress.stage]).font(.headline); Spacer(); Text("Apri il legame →").font(.caption) }
            Text(EcoRules.sleeping(place,now:Date()) ? "Riposa: nessun progresso è stato perso." : EcoRules.mission(place,now:Date()).title)
                .font(.subheadline).foregroundStyle(.secondary)
        }.ecoCard()
    }
}
