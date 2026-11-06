import Foundation

struct SignalFilter {
    private(set) var value: Double?
    private(set) var history: [Double] = []
    private var lastSample: Date?

    mutating func add(_ raw: Int, at now: Date) -> Bool {
        guard (-110 ... -10).contains(raw) else { return false }
        if let last = lastSample {
            if now.timeIntervalSince(last) < 0.5 { return false }
            if now.timeIntervalSince(last) > 12 { value = nil; history = [] }
        }
        let smoothed = value.map { $0 * 0.75 + Double(raw) * 0.25 } ?? Double(raw)
        value = smoothed
        history.append(smoothed)
        if history.count > 10 { history.removeFirst() }
        lastSample = now
        return true
    }

    var trend: String {
        guard history.count >= 8 else { return "Raccolta letture…" }
        let first = history.prefix(3).reduce(0, +) / 3
        let last = history.suffix(3).reduce(0, +) / 3
        if last - first > 3 { return "Segnale più forte · possibile avvicinamento" }
        if last - first < -3 { return "Segnale più debole · possibile allontanamento" }
        return "Segnale stabile"
    }

    static func distance(rssi: Double, reference: Double, exponent: Double) -> Double? {
        guard rssi.isFinite, reference.isFinite, exponent.isFinite,
              (-110 ... -10).contains(rssi), (-100 ... -20).contains(reference),
              (1.5 ... 4.0).contains(exponent) else { return nil }
        return pow(10, (reference - rssi) / (10 * exponent))
    }
}
