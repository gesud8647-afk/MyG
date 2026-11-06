import Foundation
import CoreBluetooth
import Combine

struct NearbyDevice: Identifiable {
    let id: UUID
    var name: String
    var rssi: Double?
    var lastSeen: Date
    var lastSignal: Date?
    var connectable: Bool
    var services: [String]
    var trend: String
}

// Owned by SwiftUI on the main thread; CoreBluetooth delegates use .main.
final class BluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var devices: [NearbyDevice] = []
    @Published private(set) var scanning = false
    @Published private(set) var status = "Avvia la ricerca per autorizzare il Bluetooth."
    @Published private(set) var following: UUID?
    @Published private(set) var connectionStatus: [UUID: String] = [:]
    @Published private(set) var battery: [UUID: Int] = [:]
    @Published private(set) var connected: Set<UUID> = []
    private var manager: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var filters: [UUID: SignalFilter] = [:]
    private var wantsScan = false
    private var deadline: Timer?
    private var poller: Timer?
    private var connectionDeadlines: [UUID: Timer] = [:]

    func start(follow id: UUID? = nil) {
        stop()
        following = id
        wantsScan = true
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: .main)
        } else if manager?.state == .poweredOn { beginScan() }
        else { updateStatus() }
    }

    func stop() {
        wantsScan = false
        manager?.stopScan()
        scanning = false
        deadline?.invalidate(); deadline = nil
        poller?.invalidate(); poller = nil
        if manager?.state == .poweredOn { status = "Ricerca ferma · dati non aggiornati" }
    }

    func pauseForBackground() {
        stop()
        for id in Array(connectionDeadlines.keys) { disconnect(id) }
        for id in Array(connected) { disconnect(id) }
    }

    func clear() {
        guard !scanning else { return }
        devices.removeAll(); filters.removeAll(); following = nil
    }

    func calibrationReference(_ id: UUID) -> Double? {
        guard let filter = filters[id], filter.history.count >= 8 else { return nil }
        return filter.history.suffix(8).reduce(0, +) / 8
    }

    private func beginScan() {
        guard !scanning, manager?.state == .poweredOn else { return }
        manager?.scanForPeripherals(withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        scanning = true
        status = following == nil ? "Ricerca attiva · fino a 60 secondi" : "Segui segnale attivo · fino a 10 minuti"
        deadline = Timer.scheduledTimer(withTimeInterval: following == nil ? 60 : 600, repeats: false) { [weak self] _ in self?.stop() }
        poller = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self = self, self.scanning, let id = self.following,
                  self.connected.contains(id) else { return }
            self.peripherals[id]?.readRSSI()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            let pendingScan = wantsScan
            stop()
            wantsScan = pendingScan
            for id in connected { connectionStatus[id] = "Bluetooth non disponibile" }
            connected.removeAll()
            for timer in connectionDeadlines.values { timer.invalidate() }
            connectionDeadlines.removeAll()
        }
        updateStatus()
        if central.state == .poweredOn && wantsScan { beginScan() }
    }

    private func updateStatus() {
        switch manager?.state {
        case .poweredOn: status = "Bluetooth pronto"
        case .poweredOff: status = "Attiva il Bluetooth nelle Impostazioni"
        case .unauthorized: status = "Consenti Bluetooth in Impostazioni → Privacy e sicurezza"
        case .unsupported: status = "BLE non disponibile: usa un iPhone fisico"
        case .resetting: status = "Bluetooth in riavvio…"
        default: status = "Inizializzazione Bluetooth…"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard scanning else { return }
        let id = peripheral.identifier
        peripherals[id] = peripheral
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Dispositivo senza nome"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map { $0.uuidString }
        let connectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index].name = name
            devices[index].lastSeen = Date()
            devices[index].connectable = connectable
            if !services.isEmpty { devices[index].services = services }
        } else {
            devices.append(NearbyDevice(id: id, name: name, rssi: nil, lastSeen: Date(),
                                        lastSignal: nil, connectable: connectable, services: services, trend: "Raccolta letture…"))
        }
        ingest(RSSI.intValue, id: id)
    }

    private func ingest(_ raw: Int, id: UUID) {
        guard scanning, let index = devices.firstIndex(where: { $0.id == id }) else { return }
        var filter = filters[id] ?? SignalFilter()
        guard filter.add(raw, at: Date()) else { return }
        filters[id] = filter
        devices[index].rssi = filter.value
        devices[index].lastSignal = Date()
        devices[index].trend = filter.trend
    }

    // Only the documented, read-only Bluetooth SIG Battery Service is implemented.
    // There is deliberately no generic write or power-off operation.
    func connectBattery(_ id: UUID) {
        guard manager?.state == .poweredOn else {
            connectionStatus[id] = "Avvia il Bluetooth prima di collegare"; return
        }
        guard let peripheral = peripherals[id] ?? manager?.retrievePeripherals(withIdentifiers: [id]).first else {
            connectionStatus[id] = "Non disponibile: ripeti la ricerca vicino all’accessorio"; return
        }
        peripherals[id] = peripheral
        guard peripheral.state == .disconnected else { return }
        battery[id] = nil
        peripheral.delegate = self
        connectionStatus[id] = "Collegamento e verifica protocollo…"
        manager?.connect(peripheral, options: nil)
        connectionDeadlines[id]?.invalidate()
        connectionDeadlines[id] = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            self?.fail(id, "Timeout: accessorio non raggiungibile o servizio non disponibile")
        }
    }

    func disconnect(_ id: UUID) {
        connectionDeadlines.removeValue(forKey: id)?.invalidate()
        if let p = peripherals[id] { manager?.cancelPeripheralConnection(p) }
        connected.remove(id)
        battery[id] = nil
        connectionStatus[id] = "Scollegato"
    }

    private func fail(_ id: UUID, _ message: String) {
        disconnect(id)
        connectionStatus[id] = message
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard connectionDeadlines[peripheral.identifier] != nil else {
            central.cancelPeripheralConnection(peripheral); return
        }
        connected.insert(peripheral.identifier)
        connectionStatus[peripheral.identifier] = "Connesso · verifica Battery Service…"
        peripheral.discoverServices([CBUUID(string: "180F")])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        fail(peripheral.identifier, "Connessione fallita: \(error?.localizedDescription ?? "nessun dettaglio")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier
        connectionDeadlines.removeValue(forKey: id)?.invalidate()
        let wasConnected = connected.contains(id)
        connected.remove(id); battery[id] = nil
        if let error = error { connectionStatus[id] = "Connessione persa: \(error.localizedDescription)" }
        else if wasConnected || connectionStatus[id]?.contains("…") == true { connectionStatus[id] = "Scollegato" }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
              let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: "180F") }) else {
            fail(peripheral.identifier, "Battery Service standard non supportato o inaccessibile"); return
        }
        peripheral.discoverCharacteristics([CBUUID(string: "2A19")], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let c = service.characteristics?.first(where: {
            $0.uuid == CBUUID(string: "2A19") && $0.properties.contains(.read)
        }) else { fail(peripheral.identifier, "Lettura batteria non supportata"); return }
        peripheral.readValue(for: c)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == CBUUID(string: "2A19") else { return }
        let id = peripheral.identifier
        guard error == nil, let data = characteristic.value, data.count == 1, let level = data.first, level <= 100 else {
            fail(id, "Lettura batteria fallita o valore non valido"); return
        }
        connectionDeadlines.removeValue(forKey: id)?.invalidate()
        battery[id] = Int(level)
        connectionStatus[id] = "Compatibile · batteria letta"
    }

    func refreshBattery(_ id: UUID) {
        guard connected.contains(id), let p = peripherals[id],
              let c = p.services?.flatMap({ $0.characteristics ?? [] }).first(where: {
                  $0.uuid == CBUUID(string: "2A19") && $0.properties.contains(.read)
              }) else { return }
        p.readValue(for: c)
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        ingest(RSSI.intValue, id: peripheral.identifier)
    }
}
