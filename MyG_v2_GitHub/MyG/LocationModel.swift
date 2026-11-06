import Foundation
import CoreLocation
import Combine

final class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var status = "La posizione è facoltativa: abilitala per la mappa."
    private let manager = CLLocationManager()
    private var requested = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
    }
    func request() {
        requested = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.startUpdatingLocation()
        default: status = "Posizione negata: il segnale Bluetooth resta disponibile. Puoi abilitarla nelle Impostazioni."
        }
    }
    func stop() { requested = false; manager.stopUpdatingLocation() }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            status = manager.accuracyAuthorization == .reducedAccuracy ? "Posizione approssimativa iOS" : "Posizione autorizzata"
            if requested { manager.startUpdatingLocation() }
        case .denied, .restricted:
            location = nil; status = "Posizione non consentita · segnale BLE utilizzabile"
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last, fix.horizontalAccuracy >= 0,
              abs(fix.timestamp.timeIntervalSinceNow) < 15 else { return }
        location = fix
        status = "Precisione GPS indicativa ±\(Int(fix.horizontalAccuracy.rounded())) m"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Posizione temporaneamente non disponibile"
    }
}
