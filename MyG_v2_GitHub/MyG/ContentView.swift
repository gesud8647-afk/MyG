import SwiftUI

extension Color {
    static let mygBackground = Color(red: 0.035, green: 0.055, blue: 0.085)
}
extension View {
    func mygCard() -> some View {
        self.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ContentView: View {
    @StateObject private var scanner = BluetoothScanner()
    @StateObject private var store = DeviceStore()
    @Environment(\.scenePhase) private var phase
    @State private var query = ""
    @State private var erase = false
    @AppStorage("myg.googleConsent") private var googleConsent = false

    private var visible: [NearbyDevice] {
        scanner.devices.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
            .sorted { ($0.rssi ?? -999) > ($1.rssi ?? -999) }
    }
    var body: some View {
        TabView {
            NavigationStack { nearby }.tabItem { Label("Vicini", systemImage: "dot.radiowaves.left.and.right") }
            NavigationStack { accessories }.tabItem { Label("Accessori", systemImage: "switch.2") }
            NavigationStack { MessageView() }.tabItem { Label("Messaggio", systemImage: "paperplane") }
            NavigationStack { settings }.tabItem { Label("Info", systemImage: "info.circle") }
        }.tint(.mint)
            .onChange(of: phase) { value in if value != .active { scanner.pauseForBackground() } }
    }

    private var nearby: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image("MyGLogo").resizable().scaledToFit().frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading) {
                        Text("MY G / 02").font(.title.bold())
                        Text("Esplora. Scegli. Segui il segnale.").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text(scanner.status)
                    HStack {
                        Button(scanner.scanning ? "Ferma ricerca" : "Cerca dispositivi") {
                            if scanner.scanning { scanner.stop() } else { scanner.start() }
                        }.buttonStyle(.borderedProminent)
                        Button("Svuota") { scanner.clear() }
                            .disabled(scanner.scanning || scanner.devices.isEmpty)
                    }
                }.mygCard()
                TextField("Cerca per nome", text: $query).textFieldStyle(.roundedBorder)
                Text("Dispositivi vicini · \(scanner.devices.count)").font(.title3.bold())
                if visible.isEmpty {
                    Text("Avvia la ricerca vicino a un dispositivo BLE che trasmette advertising. Non tutti i telefoni e accessori sono rilevabili.")
                        .foregroundStyle(.secondary).mygCard()
                }
                ForEach(visible) { d in
                    NavigationLink {
                        DeviceDetailView(scanner: scanner, store: store, id: d.id)
                    } label: { DeviceRow(device: d, calibration: store.calibration(d.id)) }
                    .buttonStyle(.plain)
                }
                Text("Nomi non verificati. Distanza stimata dal segnale, senza direzione. Tocca un risultato per aprire Segui segnale e la mappa.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.background(Color.mygBackground).navigationTitle("Dispositivi vicini").navigationBarTitleDisplayMode(.inline)
    }

    private var accessories: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("I tuoi accessori").font(.title.bold())
                Text("Aggiungi un accessorio dalla sua scheda. È disponibile solo la lettura della batteria BLE standard, con verifica al collegamento.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if store.accessories.isEmpty {
                    Label("Nessun accessorio configurato", systemImage: "switch.2").mygCard()
                }
                ForEach(store.accessories) { a in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(a.name).font(.headline)
                        Text("\(a.manufacturer) · \(a.model)")
                        Text(a.protocolName).font(.caption).foregroundStyle(.secondary)
                        Text(scanner.connectionStatus[a.id] ?? "Compatibilità da verificare")
                            .font(.subheadline)
                        if let level = scanner.battery[a.id], scanner.connected.contains(a.id) {
                            Label("Batteria: \(level)%", systemImage: "battery.100percent")
                            Button("Aggiorna batteria") { scanner.refreshBattery(a.id) }
                        }
                        HStack {
                            Button("Collega") { scanner.connectBattery(a.id) }
                                .disabled(scanner.connected.contains(a.id))
                            Button("Scollega") { scanner.disconnect(a.id) }
                        }.buttonStyle(.bordered)
                        Button("Rimuovi accessorio", role: .destructive) {
                            scanner.disconnect(a.id); store.remove(a.id)
                        }.font(.caption)
                    }.mygCard()
                }
                Text("Telecomando accendi/spegni: serve marca, modello e documentazione del protocollo del tuo accessorio. Nessun pulsante di comando finto.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.background(Color.mygBackground).navigationTitle("Accessori configurati").navigationBarTitleDisplayMode(.inline)
    }

    private var settings: some View {
        Form {
            Section("My G 2.0") {
                Image("MyGLogo").resizable().scaledToFit().frame(width: 96, height: 96)
                Text("RSSI ≠ GPS. La mappa mostra il tuo iPhone e un raggio teorico. Non localizza precisamente altri dispositivi.")
                Text("La ricerca termina dopo 60 secondi; Segui segnale dopo 10 minuti. Quando l’app lascia il primo piano, scansione e connessioni si fermano.")
            }
            Section("Mappe e privacy") {
                Text(GoogleSetup.available ? "Google Maps configurato, attivabile nella scheda dispositivo." : "Google Maps non configurato: mappa Apple disponibile.")
                Toggle("Consenso Google Maps", isOn: $googleConsent)
                Text("Le mappe richiedono rete e contattano il fornitore dell’area visualizzata. Identificativi BLE non inviati. Scansioni e coordinate non sono salvate su un nostro server.")
                Text("Accessori, calibrazioni e firma sono conservati nelle preferenze dell’app e possono rientrare nei backup iOS. Elenco rilevato e bozza restano in memoria.")
            }
            Section {
                Button("Cancella accessori e calibrazioni", role: .destructive) { erase = true }
            }
        }.navigationTitle("Info e dati")
            .confirmationDialog("Cancellare accessori e calibrazioni salvati?", isPresented: $erase, titleVisibility: .visible) {
                Button("Cancella", role: .destructive) { scanner.pauseForBackground(); store.erase() }
            }
    }
}

private struct DeviceRow: View {
    let device: NearbyDevice
    let calibration: Calibration
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(device.name).font(.headline)
                Spacer()
                Text(device.rssi.map { String(format: "%.0f dBm", $0) } ?? "N/D").font(.caption.monospaced())
            }
            Text(device.id.uuidString).font(.caption2.monospaced()).foregroundStyle(.secondary)
            if let rssi = device.rssi, let distance = SignalFilter.distance(rssi: rssi, reference: calibration.reference, exponent: calibration.exponent) {
                Text(distance > 500 ? "Stima oltre 500 m · poco attendibile" : String(format: "Ultima stima ≈ %.1f m · non GPS", distance))
                    .font(.subheadline).foregroundStyle(.mint)
            }
            HStack { Text("Rilevato"); Text(device.lastSeen, style: .time); Spacer(); Text("Segui segnale →") }
                .font(.caption)
        }.mygCard()
    }
}
