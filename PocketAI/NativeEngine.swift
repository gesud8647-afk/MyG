import Foundation

private final class GenerationSink {
    var data = Data()
    var lastUpdate: TimeInterval = 0
    let partial: (String) -> Void
    init(partial: @escaping (String) -> Void) { self.partial = partial }
    func append(_ bytes: UnsafePointer<CChar>, length: Int) {
        data.append(UnsafeRawPointer(bytes).assumingMemoryBound(to: UInt8.self), count: length)
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastUpdate > 0.1 {
            lastUpdate = now
            let text = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async { self.partial(text) }
        }
    }
}

final class NativeEngine {
    private let queue = DispatchQueue(label: "usi.pocket.inference", qos: .userInitiated)
    private let lock = NSLock()
    private var handle: OpaquePointer?

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        if let handle = handle { pocket_cancel(handle) }
    }
    private func destroyCurrent() {
        lock.lock(); defer { lock.unlock() }
        if let handle = handle { pocket_destroy(handle) }
        handle = nil
    }
    func unload(completion: @escaping () -> Void) {
        cancel()
        queue.async {
            self.destroyCurrent()
            DispatchQueue.main.async { completion() }
        }
    }
    func load(path: String, completion: @escaping (String?) -> Void) {
        queue.async {
            self.destroyCurrent()
            var buffer = [CChar](repeating: 0, count: 512)
            let created = path.withCString { pocket_create($0, &buffer, 512) }
            self.lock.lock(); self.handle = created; self.lock.unlock()
            let error: String? = created == nil ? String(cString: buffer) : nil
            DispatchQueue.main.async { completion(error) }
        }
    }
    func generate(prompt: String, limit: Int, partial: @escaping (String) -> Void,
                  completion: @escaping (String, Int32, String?) -> Void) {
        // Reset cancellation before dispatch, so an immediate Stop is not lost.
        lock.lock()
        if let handle = handle { pocket_prepare(handle) }
        lock.unlock()
        queue.async {
            self.lock.lock(); let engine = self.handle; self.lock.unlock()
            guard let engine = engine else {
                DispatchQueue.main.async { completion("", -1, "Carica prima il modello.") }; return
            }
            let sink = GenerationSink(partial: partial)
            let opaque = Unmanaged.passUnretained(sink).toOpaque()
            let callback: @convention(c) (UnsafePointer<CChar>?, Int32, UnsafeMutableRawPointer?) -> Bool = { bytes, count, context in
                guard let bytes = bytes, let context = context, count >= 0 else { return false }
                let sink = Unmanaged<GenerationSink>.fromOpaque(context).takeUnretainedValue()
                sink.append(bytes, length: Int(count))
                return true
            }
            var errorBuffer = [CChar](repeating: 0, count: 512)
            let code = prompt.withCString {
                pocket_generate(engine, $0, Int32(limit), callback, opaque, &errorBuffer, 512)
            }
            let final = String(decoding: sink.data, as: UTF8.self)
            let error: String? = code < 0 ? String(cString: errorBuffer) : nil
            DispatchQueue.main.async { completion(final, code, error) }
        }
    }
}
