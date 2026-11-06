import Foundation
import CoreLocation
import Combine

final class EcoLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var fix: CLLocation?
    @Published private(set) var status = "La posizione è facoltativa. Puoi usare anche luoghi manuali."
    @Published private(set) var busy = false
    private let manager = CLLocationManager()
    private var deadline: Timer?
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyBest }
    func request() {
        fix = nil; busy = true; status = "Cerco la posizione…"
        deadline?.invalidate()
        deadline = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
            self?.cancel(); self?.status = "Posizione non disponibile. Puoi riprovare o usare la modalità manuale."
        }
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: busy = false; deadline?.invalidate(); status = "Posizione non consentita. La modalità manuale resta disponibile."
        }
    }
    func cancel() { manager.stopUpdatingLocation(); deadline?.invalidate(); busy = false }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: if busy { manager.requestLocation() }
        case .denied, .restricted: cancel(); fix = nil; status = "Posizione negata. Puoi continuare manualmente."
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) < 20 else { return }
        fix = location; cancel()
        status = "Posizione ricevuta · precisione ±\(Int(location.horizontalAccuracy)) m"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        cancel(); status = "Posizione non disponibile: riprova all’aperto o usa la modalità manuale."
    }
    var coordinate: EcoCoordinate? {
        guard let fix = fix, abs(fix.timestamp.timeIntervalSinceNow) < 60 else { return nil }
        return EcoCoordinate(latitude: fix.coordinate.latitude, longitude: fix.coordinate.longitude,
                             accuracy: fix.horizontalAccuracy, measuredAt: fix.timestamp)
    }
    func isNear(_ coordinate: EcoCoordinate?) -> Bool {
        guard let c = coordinate, let fix = fix, abs(fix.timestamp.timeIntervalSinceNow) < 30,
              fix.horizontalAccuracy <= 60, c.accuracy <= 60 else { return false }
        return fix.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude)) <= 100
    }
}
