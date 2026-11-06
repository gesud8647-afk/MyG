import SwiftUI
import CoreLocation

struct DeviceDetailView: View {
    @ObservedObject var scanner: BluetoothScanner
    @ObservedObject var store: DeviceStore
    let id: UUID
    @StateObject private var location = LocationModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showCalibration = false
    @State private var showAccessory = false
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var confirmedBattery = false
    @State private var calibrationMessage = ""

    private var device: NearbyDevice? { scanner.devices.first { $0.id == id } }
    private var calibration: Calibration { store.calibration(id) }
    private var distance: Double? {
        guard let signal = device?.rssi else { return nil }
        return SignalFilter.distance(rssi: signal, reference: calibration.reference, exponent: calibration.exponent)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(device?.name ?? "Dispositivo").font(.title.bold())
                Text(id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    signalPanel(now: context.date)
                }
                HStack {
                    Button(scanner.scanning && scanner.following == id ? "Ferma" : "Segui segnale") {
                        if scanner.scanning && scanner.following == id { scanner.stop() }
                        else { scanner.start(follow: id) }
                    }.buttonStyle(.borderedProminent)
                    Button("Calibrazione") { showCalibration = true }.buttonStyle(.bordered)
                }
                Button("Abilita posizione per la mappa") { location.request() }
                    .buttonStyle(.bordered)
                Text(location.status).font(.caption).foregroundStyle(.secondary)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let fix = location.location {
                        let signalFresh = device?.lastSignal.map { context.date.timeIntervalSince($0) < 12 } ?? false
                        let fixFresh = context.date.timeIntervalSince(fix.timestamp) < 15
                        let valid = scanner.scanning && signalFresh && fixFresh
                        MapPanel(coordinate: fix.coordinate,
                                 radius: valid ? distance : nil, gpsAccuracy: fix.horizontalAccuracy)
                        HStack { Text("Posizione A aggiornata alle"); Text(fix.timestamp, style: .time) }
                            .font(.caption)
                        if !fixFresh { Text("Posizione A non aggiornata: riabilita la posizione.").font(.caption).foregroundStyle(.orange) }
                    }
                }
                Text("La distanza RSSI è un modello teorico. Pareti, orientamento, persone e potenza del trasmettitore possono alterarla anche di molto. Il cerchio non garantisce dove si trova B.")
                    .font(.footnote).foregroundStyle(.secondary)
                if device?.connectable == true {
                    Button("Aggiungi per lettura batteria BLE") { showAccessory = true }
                        .buttonStyle(.bordered)
                } else {
                    Text("Questo advertising non segnala una periferica collegabile.").font(.caption)
                }
                Text("Per un telecomando servono marca, modello e protocollo documentato. Non sono presenti comandi universali di accensione o spegnimento.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle("Segui segnale").navigationBarTitleDisplayMode(.inline)
        .background(Color.mygBackground)
        .onChange(of: scenePhase) { phase in if phase != .active { location.stop() } }
        .onDisappear {
            location.stop()
            if scanner.following == id { scanner.stop() }
        }
        .sheet(isPresented: $showCalibration) { calibrationSheet }
        .sheet(isPresented: $showAccessory) { accessorySheet }
    }

    @ViewBuilder private func signalPanel(now: Date) -> some View {
        let last = device?.lastSignal
        let age = last.map { max(0, now.timeIntervalSince($0)) }
        let fresh = age.map { $0 < 12 } ?? false
        VStack(alignment: .leading, spacing: 12) {
            Text(!scanner.scanning ? "DATI FERMI" : fresh ? "SEGNALE RECENTE" : "SEGNALE PERSO / NON DISPONIBILE")
                .font(.caption.bold()).foregroundStyle(fresh && scanner.scanning ? Color.mint : Color.orange)
            Text(device?.rssi.map { String(format: "%.0f dBm", $0) } ?? "RSSI non disponibile")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            if let d = distance {
                Text(d > 500 ? "Stima teorica oltre 500 m · poco attendibile" : String(format: "Distanza indicativa: circa %.1f m", d))
                    .font(.title3)
            } else { Text("Distanza non disponibile") }
            Text(calibration.calibrated ? "Calibrazione personale a 1 m" : "Modello generico, non calibrato")
                .font(.caption).foregroundStyle(.secondary)
            if let signal = device?.rssi {
                ProgressView(value: min(1, max(0, (signal + 100) / 65))).tint(.mint)
                    .accessibilityLabel("Intensità del segnale")
            }
            Text(scanner.scanning && fresh ? (device?.trend ?? "Raccolta letture…") : "Avvia o riprendi Segui segnale per aggiornare")
            if let last = last {
                HStack { Text("Ultima lettura valida"); Text(last, style: .time) }.font(.caption)
            }
            Text("Un segnale perso può dipendere da distanza, advertising sospeso o ostacoli: non prova che il dispositivo sia spento.")
                .font(.caption).foregroundStyle(.secondary)
        }.mygCard()
    }

    private var calibrationSheet: some View {
        NavigationStack {
            Form {
                Section("Calibrazione a un metro") {
                    Text("Posiziona manualmente il dispositivo a 1 metro dall’iPhone, avvia Segui segnale e attendi almeno 8 letture stabili. La calibrazione non determina la direzione.")
                    Button("Salva il segnale attuale come riferimento a 1 m") {
                        guard scanner.scanning, let d = device, let last = d.lastSignal,
                              Date().timeIntervalSince(last) < 3, let reference = scanner.calibrationReference(id),
                              (-100 ... -20).contains(reference) else {
                            calibrationMessage = "Servono almeno 8 letture recenti e valide. Riprendi Segui segnale e attendi."; return
                        }
                        var c = calibration; c.reference = reference; c.calibrated = true
                        store.setCalibration(id, c)
                        calibrationMessage = "Riferimento salvato: \(Int(reference)) dBm a 1 m."
                    }
                    Text("Riferimento: \(Int(calibration.reference)) dBm")
                    Stepper(value: Binding(get: { calibration.exponent }, set: { value in
                        var c = calibration; c.exponent = value; store.setCalibration(id, c)
                    }), in: 1.5 ... 4, step: 0.25) {
                        Text(String(format: "Fattore ambiente: %.2f", calibration.exponent))
                    }
                    Text("2 è il valore iniziale. Un fattore più alto modella maggiore attenuazione; non rende la stima precisa.")
                    Button("Ripristina modello generico", role: .destructive) {
                        store.setCalibration(id, Calibration()); calibrationMessage = "Calibrazione ripristinata."
                    }
                    Text(calibrationMessage)
                }
            }.navigationTitle("Calibrazione")
                .toolbar { Button("Fine") { showCalibration = false } }
        }
    }

    private var accessorySheet: some View {
        NavigationStack {
            Form {
                Section("Identifica il tuo accessorio") {
                    TextField("Marca", text: $manufacturer)
                    TextField("Modello", text: $model)
                    Toggle("È mio o sono autorizzato a collegarlo", isOn: $confirmedBattery)
                }
                Section("Protocollo disponibile") {
                    Text("Solo Battery Service standard BLE (180F / 2A19). La compatibilità sarà verificata al collegamento. Nessun comando di accensione o spegnimento.")
                    Button("Salva accessorio da verificare") {
                        store.add(SavedAccessory(id: id, name: device?.name ?? "Accessorio",
                                                 manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
                                                 model: model.trimmingCharacters(in: .whitespacesAndNewlines)))
                        showAccessory = false
                    }.disabled(!confirmedBattery || manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.navigationTitle("Aggiungi accessorio")
                .toolbar { Button("Annulla") { showAccessory = false } }
        }
    }
}
