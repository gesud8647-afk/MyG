import Foundation
import CoreBluetooth
import Combine

struct NearbyDevice: Identifiable {
    let id: UUID
    var name: String
    var rssi: Int?
    var lastSeen: Date
    var services: [String]
}

// All callbacks and published mutations run on the main queue.
final class BluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published private(set) var devices: [NearbyDevice] = []
    @Published private(set) var scanning = false
    @Published private(set) var status = "Tocca Avvia per autorizzare il Bluetooth."
    private var manager: CBCentralManager?
    private var wantsScan = false
    private var deadline: Timer?

    func start() {
        wantsScan = true
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: .main)
        } else if manager?.state == .poweredOn {
            beginScan()
        } else {
            updateStatus()
        }
    }

    func stop() {
        wantsScan = false
        manager?.stopScan()
        scanning = false
        deadline?.invalidate()
        deadline = nil
        if manager?.state == .poweredOn { status = "Scansione ferma. I risultati possono non essere più presenti." }
    }

    func clear() { devices.removeAll() }

    private func beginScan() {
        guard !scanning, manager?.state == .poweredOn else { return }
        manager?.scanForPeripherals(withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        scanning = true
        status = "Scansione BLE attiva · arresto automatico dopo 60 secondi"
        deadline?.invalidate()
        deadline = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
            self?.stop()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            scanning = false
            deadline?.invalidate()
            deadline = nil
        }
        updateStatus()
        if central.state == .poweredOn && wantsScan { beginScan() }
    }

    private func updateStatus() {
        switch manager?.state {
        case .poweredOn: status = "Bluetooth pronto."
        case .poweredOff: status = "Attiva il Bluetooth nelle Impostazioni dell’iPhone."
        case .unauthorized: status = "Consenti il Bluetooth in Impostazioni → Privacy e sicurezza → Bluetooth."
        case .unsupported: status = "Bluetooth LE non disponibile. Usa un iPhone fisico."
        case .resetting: status = "Bluetooth in riavvio…"
        default: status = "Inizializzazione Bluetooth…"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard scanning else { return }
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? "Dispositivo senza nome"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map { $0.uuidString }
        let signal: Int? = RSSI.intValue == 127 ? nil : RSSI.intValue
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].name = name
            devices[index].rssi = signal
            devices[index].lastSeen = Date()
            if !services.isEmpty { devices[index].services = services }
        } else {
            devices.append(NearbyDevice(id: peripheral.identifier, name: name, rssi: signal,
                                        lastSeen: Date(), services: services))
        }
    }
}
