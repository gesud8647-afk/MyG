import Foundation
import Combine

struct Calibration: Codable {
    var reference: Double = -59
    var exponent: Double = 2
    var calibrated = false
}

struct SavedAccessory: Codable, Identifiable {
    let id: UUID
    var name: String
    var manufacturer: String
    var model: String
    // Protocol is fixed: no arbitrary Bluetooth writes can be configured.
    var protocolName = "Battery Service BLE · sola lettura"
}

final class DeviceStore: ObservableObject {
    @Published private(set) var accessories: [SavedAccessory] = []
    @Published private(set) var calibrations: [String: Calibration] = [:]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "myg.accessories.v2"),
           let value = try? JSONDecoder().decode([SavedAccessory].self, from: data) { accessories = value }
        if let data = defaults.data(forKey: "myg.calibration.v2"),
           let value = try? JSONDecoder().decode([String: Calibration].self, from: data) { calibrations = value }
    }
    func calibration(_ id: UUID) -> Calibration { calibrations[id.uuidString] ?? Calibration() }
    func setCalibration(_ id: UUID, _ value: Calibration) {
        calibrations[id.uuidString] = value
        defaults.set(try? JSONEncoder().encode(calibrations), forKey: "myg.calibration.v2")
    }
    func add(_ accessory: SavedAccessory) {
        accessories.removeAll { $0.id == accessory.id }
        accessories.append(accessory)
        save()
    }
    func remove(_ id: UUID) { accessories.removeAll { $0.id == id }; save() }
    private func save() {
        defaults.set(try? JSONEncoder().encode(accessories), forKey: "myg.accessories.v2")
    }
    func erase() {
        accessories = []; calibrations = [:]
        defaults.removeObject(forKey: "myg.accessories.v2")
        defaults.removeObject(forKey: "myg.calibration.v2")
    }
}
