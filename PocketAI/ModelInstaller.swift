import Foundation
import CryptoKit

struct ModelInstaller {
    static let expectedSHA256 = "9465e63a22add5354d9bb4b99e90117043c7124007664907259bd16d043bb031"
    static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PocketModels", isDirectory: true)
    }
    static func install(_ source: URL, progress: @escaping (String) -> Void,
                        completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let allowed = source.startAccessingSecurityScopedResource()
            defer { if allowed { source.stopAccessingSecurityScopedResource() } }
            var copied: URL?
            do {
                let sourceSize = try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard sourceSize > 100_000_000, sourceSize < 900_000_000 else { throw InstallError.wrongModel }
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let destination = folder.appendingPathComponent(UUID().uuidString + ".gguf")
                copied = destination
                try FileManager.default.copyItem(at: source, to: destination)
                var excluded = destination
                var resourceValues = URLResourceValues(); resourceValues.isExcludedFromBackup = true
                try excluded.setResourceValues(resourceValues)
                let size = try destination.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size > 100_000_000, size < 900_000_000 else { throw InstallError.wrongModel }
                let file = try FileHandle(forReadingFrom: destination)
                defer { try? file.close() }
                let first = try file.read(upToCount: 4) ?? Data()
                guard first == Data("GGUF".utf8) else { throw InstallError.wrongModel }
                try file.seek(toOffset: 0)
                var hash = SHA256()
                var total = 0
                while let chunk = try file.read(upToCount: 1_048_576), !chunk.isEmpty {
                    hash.update(data: chunk); total += chunk.count
                    if total % (32 * 1_048_576) == 0 {
                        let percent = Int(Double(total) / Double(size) * 100)
                        DispatchQueue.main.async { progress("Verifica modello: \(percent)%") }
                    }
                }
                let actual = hash.finalize().map { String(format: "%02x", $0) }.joined()
                guard actual == expectedSHA256 else { throw InstallError.wrongModel }
                DispatchQueue.main.async { completion(.success(destination)) }
            } catch {
                if let copied = copied { try? FileManager.default.removeItem(at: copied) }
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    enum InstallError: LocalizedError {
        case wrongModel
        var errorDescription: String? {
            "Serve il file ufficiale completo Qwen3-0.6B-Q8_0.gguf. La dimensione, firma GGUF o impronta SHA-256 non corrisponde. Scaricalo dal collegamento indicato nell’app."
        }
    }
}
