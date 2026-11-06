import SwiftUI
import MapKit
#if canImport(GoogleMaps)
import GoogleMaps
#endif

enum GoogleSetup {
    static var available: Bool {
        #if canImport(GoogleMaps)
        return !key.isEmpty
        #else
        return false
        #endif
    }
    static var key: String {
        guard let url = Bundle.main.url(forResource: "GoogleMapsConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else { return "" }
        return (dict["GoogleMapsAPIKey"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    #if canImport(GoogleMaps)
    static let initialized: Bool = GMSServices.provideAPIKey(key)
    #endif
}

struct MapPanel: View {
    let coordinate: CLLocationCoordinate2D
    let radius: Double?
    let gpsAccuracy: Double
    @AppStorage("myg.googleConsent") private var googleConsent = false
    @State private var useGoogle = false
    @State private var recenter = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(useGoogle && googleConsent ? "Google Maps" : "Mappa Apple").font(.headline)
                Spacer()
                Button("Centra A") { recenter += 1 }
            }
            if GoogleSetup.available {
                Toggle("Usa Google Maps", isOn: $useGoogle)
                if useGoogle && !googleConsent {
                    Text("Google riceverà richieste di mappa e l’area visualizzata. Non inviamo identificativi Bluetooth al servizio.").font(.caption)
                    Button("Consenti e mostra Google Maps") { googleConsent = true }
                }
            } else {
                Text("Google Maps opzionale: chiave non configurata. Mappa Apple disponibile senza chiave Google.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            map.frame(height: 300).clipShape(RoundedRectangle(cornerRadius: 16))
            Label("A · il tuo iPhone", systemImage: "location.fill").foregroundStyle(.mint)
            Text("Cerchio verde: raggio teorico RSSI, non una zona certa. Nessuna direzione o coordinata del dispositivo B. Il cerchio grigio indica l’incertezza GPS.")
                .font(.caption).foregroundStyle(.secondary)
            if radius == nil { Text("Cerchio RSSI nascosto: servono ricerca attiva, segnale recente e posizione aggiornata.").font(.caption) }
            Link("Apri A in Google Maps", destination: URL(string:
                "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)")!)
                .font(.subheadline)
        }
    }
    @ViewBuilder private var map: some View {
        #if canImport(GoogleMaps)
        if useGoogle && googleConsent && GoogleSetup.available && GoogleSetup.initialized {
            GoogleCircleMap(coordinate: coordinate, radius: radius, gpsAccuracy: gpsAccuracy, recenter: recenter)
        } else {
            AppleCircleMap(coordinate: coordinate, radius: radius, gpsAccuracy: gpsAccuracy, recenter: recenter)
        }
        #else
        AppleCircleMap(coordinate: coordinate, radius: radius, gpsAccuracy: gpsAccuracy, recenter: recenter)
        #endif
    }
}

struct AppleCircleMap: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let radius: Double?
    let gpsAccuracy: Double
    let recenter: Int
    final class Coordinator: NSObject, MKMapViewDelegate {
        var centered = false
        var token = -1
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circle = overlay as? MKCircle else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKCircleRenderer(circle: circle)
            let signal = circle.title == "RSSI"
            renderer.strokeColor = signal ? .systemMint : .systemGray
            renderer.fillColor = (signal ? UIColor.systemMint : UIColor.systemGray).withAlphaComponent(signal ? 0.14 : 0.08)
            renderer.lineWidth = signal ? 2 : 1
            return renderer
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        return map
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations)
        let a = MKPointAnnotation(); a.coordinate = coordinate; a.title = "A · il tuo iPhone"
        map.addAnnotation(a)
        map.removeOverlays(map.overlays)
        let gps = MKCircle(center: coordinate, radius: max(1, gpsAccuracy)); gps.title = "GPS"
        map.addOverlay(gps)
        if let radius = radius {
            let circle = MKCircle(center: coordinate, radius: radius); circle.title = "RSSI"
            map.addOverlay(circle)
        }
        if !context.coordinator.centered || context.coordinator.token != recenter {
            let span = max(100, max(radius ?? 0, gpsAccuracy) * 3)
            map.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: span, longitudinalMeters: span), animated: false)
            context.coordinator.centered = true; context.coordinator.token = recenter
        }
    }
}

#if canImport(GoogleMaps)
struct GoogleCircleMap: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let radius: Double?
    let gpsAccuracy: Double
    let recenter: Int
    final class Coordinator { var centered = false; var token = -1 }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> GMSMapView {
        let map = GMSMapView(frame: .zero)
        map.overrideUserInterfaceStyle = .dark
        return map
    }
    func updateUIView(_ map: GMSMapView, context: Context) {
        map.clear()
        let marker = GMSMarker(position: coordinate); marker.title = "A · il tuo iPhone"; marker.map = map
        let gps = GMSCircle(position: coordinate, radius: max(1, gpsAccuracy))
        gps.strokeColor = .systemGray; gps.fillColor = UIColor.systemGray.withAlphaComponent(0.08); gps.map = map
        if let radius = radius {
            let circle = GMSCircle(position: coordinate, radius: radius)
            circle.strokeColor = .systemMint; circle.fillColor = UIColor.systemMint.withAlphaComponent(0.14)
            circle.strokeWidth = 2; circle.map = map
        }
        if !context.coordinator.centered || context.coordinator.token != recenter {
            let meters = max(100, max(radius ?? 0, gpsAccuracy) * 3)
            let zoom = Float(max(2, min(20, log2(40075016 * max(0.01, cos(coordinate.latitude * .pi / 180)) / meters))))
            map.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: zoom)
            context.coordinator.centered = true; context.coordinator.token = recenter
        }
    }
}
#endif
