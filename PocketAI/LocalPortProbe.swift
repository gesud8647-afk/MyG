import Foundation
import Network
import Combine

struct ProbeResult: Identifiable {
    let port: UInt16
    let status: String
    var id: UInt16 { port }
}

final class LocalPortProbe: ObservableObject {
    @Published private(set) var results: [ProbeResult] = []
    @Published private(set) var running = false
    @Published private(set) var message = "Nessuna connessione effettuata."
    private let queue = DispatchQueue(label: "usi.security.probe")
    private var connection: NWConnection?
    private var timer: DispatchWorkItem?
    private var runID = UUID()
    private var currentToken: UUID?
    private var pending: [UInt16] = []
    private var host = ""
    // Public methods called from UI/main. Network work is serialized.
    func start(host: String, ports: [UInt16]) {
        guard !running, let target = SecurityRules.privateIPv4(host), !ports.isEmpty, ports.count <= 8 else { return }
        results = []; running = true; message = "Provo le porte selezionate, senza inviare credenziali o comandi."
        let id = UUID()
        queue.async {
            self.runID = id; self.host = target; self.pending = Array(Set(ports)).sorted()
            self.next(id)
        }
    }
    func stop() {
        guard running else { return }
        queue.async {
            self.runID = UUID(); self.currentToken = nil
            self.timer?.cancel(); self.connection?.cancel(); self.connection = nil; self.pending = []
            DispatchQueue.main.async { self.running = false; self.message = "Controllo fermato: risultati parziali." }
        }
    }
    private func next(_ id: UUID) {
        guard runID == id else { return }
        guard !pending.isEmpty else {
            DispatchQueue.main.async { self.running = false; self.message = "Controllo terminato. Nessun tentativo di autenticazione." }; return
        }
        let port = pending.removeFirst()
        guard let endpoint = NWEndpoint.Port(rawValue: port) else { next(id); return }
        let token = UUID(); currentToken = token
        let conn = NWConnection(host: NWEndpoint.Host(host), port: endpoint, using: .tcp)
        connection = conn
        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self, self.runID == id, self.currentToken == token else { return }
            switch state {
            case .ready: self.finish(id, token, port, "TCP raggiungibile")
            case .failed(let error): self.finish(id, token, port, "Non connesso: \(error.localizedDescription)")
            case .waiting: DispatchQueue.main.async { self.message = "Attendo rete locale o autorizzazione iOS. Se necessario, consenti l’accesso e ripeti." }
            default: break
            }
        }
        let timeout = DispatchWorkItem { [weak self] in self?.finish(id, token, port, "Nessuna risposta entro 4 s: esito inconcludente") }
        timer = timeout
        queue.asyncAfter(deadline: .now() + 4, execute: timeout)
        conn.start(queue: queue)
    }
    private func finish(_ id: UUID, _ token: UUID, _ port: UInt16, _ status: String) {
        guard runID == id, currentToken == token else { return }
        currentToken = nil; timer?.cancel(); connection?.cancel(); connection = nil
        DispatchQueue.main.async { self.results.append(ProbeResult(port: port, status: status)) }
        next(id)
    }
}
