import SwiftUI
import MapKit

struct PlacesMapView: View {
    @ObservedObject var store: EcoStore
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("La tua geografia personale.").font(.title.bold())
                if store.places.contains(where:{$0.coordinate != nil}) {
                    EcoMap(places:store.places).frame(height:340).clipShape(RoundedRectangle(cornerRadius:24))
                    Text("I punti indicano la posizione salvata alla creazione. Non registriamo i tuoi spostamenti. Le mappe Apple richiedono rete per caricare nuove aree.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Label("Nessuna posizione salvata. I tuoi luoghi manuali restano qui sotto.",systemImage:"map").ecoCard()
                }
                ForEach(store.places) { place in
                    NavigationLink { PlaceDetailView(store:store,id:place.id) } label: {
                        HStack {
                            Image(systemName:place.coordinate == nil ? "book.closed" : "mappin.and.ellipse").foregroundStyle(place.mood.tint)
                            VStack(alignment:.leading,spacing:4) {
                                Text(place.name).font(.headline)
                                Text(place.coordinate == nil ? "Luogo manuale" : "Posizione salvata").font(.caption).foregroundStyle(.secondary)
                                if let c = place.coordinate { Text("Precisione iniziale ±\(Int(c.accuracy)) m").font(.caption2).foregroundStyle(.secondary) }
                            }
                            Spacer(); Image(systemName:"chevron.right")
                        }.ecoCard()
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.background(Color.ecoBackground).navigationTitle("I tuoi luoghi")
    }
}

struct EcoMap: UIViewRepresentable {
    let places: [EcoPlace]
    final class Coordinator { var ids: Set<UUID> = [] }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context:Context) -> MKMapView {
        let map = MKMapView(); map.overrideUserInterfaceStyle = .dark; return map
    }
    func updateUIView(_ map:MKMapView,context:Context) {
        let mapped = places.filter { $0.coordinate?.valid == true }
        let ids = Set(mapped.map(\.id))
        guard ids != context.coordinator.ids else { return }
        map.removeAnnotations(map.annotations)
        for place in mapped {
            guard let c = place.coordinate else { continue }
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude:c.latitude,longitude:c.longitude)
            pin.title = place.name; pin.subtitle = EcoRules.stages[EcoRules.progress(place).stage]
            map.addAnnotation(pin)
        }
        if mapped.count == 1, let c = mapped.first?.coordinate {
            map.setRegion(MKCoordinateRegion(center:CLLocationCoordinate2D(latitude:c.latitude,longitude:c.longitude),latitudinalMeters:max(500,c.accuracy*3),longitudinalMeters:max(500,c.accuracy*3)),animated:false)
        } else { map.showAnnotations(map.annotations,animated:false) }
        context.coordinator.ids = ids
    }
}
