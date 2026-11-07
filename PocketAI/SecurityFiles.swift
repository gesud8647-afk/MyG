import Foundation
import CryptoKit
import ImageIO
import UniformTypeIdentifiers

struct FileDigest {
    let name: String
    let bytes: Int
    let sha256: String
}

final class WorkCancellation {
    private let lock = NSLock()
    private var value = false
    func cancel() { lock.lock(); value = true; lock.unlock() }
    var cancelled: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

enum SecurityFiles {
    static func digest(_ url: URL, cancellation: WorkCancellation,
                       progress: @escaping (Double) -> Void, completion: @escaping (Result<FileDigest, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size >= 0, size <= 2_000_000_000 else { throw FileError.tooLarge }
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                var hash = SHA256(); var total = 0; var lastProgress = 0
                while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
                    if cancellation.cancelled { throw FileError.cancelled }
                    total += chunk.count
                    guard total <= 2_000_000_000 else { throw FileError.tooLarge }
                    hash.update(data: chunk)
                    if total - lastProgress >= 16_777_216 {
                        lastProgress = total
                        let fraction = size > 0 ? min(1, Double(total) / Double(size)) : 0
                        DispatchQueue.main.async { progress(fraction) }
                    }
                }
                if cancellation.cancelled { throw FileError.cancelled }
                let hex = hash.finalize().map { String(format: "%02x", $0) }.joined()
                let result = FileDigest(name: url.lastPathComponent, bytes: total, sha256: hex)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch { DispatchQueue.main.async { completion(.failure(error)) } }
        }
    }
    static func image(_ raw: Data) throws -> CGImage {
        guard raw.count <= 30_000_000,
              let source = CGImageSourceCreateWithData(raw as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 4096
              ] as CFDictionary) else { throw FileError.badImage }
        return image
    }
    static func cleanedPhoto(_ raw: Data) throws -> (URL, Bool) {
        let image = try image(raw)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SecurityPhotos", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("Foto-senza-metadati-\(UUID().uuidString.prefix(8)).jpg")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { throw FileError.badImage }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FileError.badImage }
        guard let check = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(check, 0, nil) as? [String: Any] else { throw FileError.badImage }
        let noGPS = properties[kCGImagePropertyGPSDictionary as String] == nil
        let noEXIF = properties[kCGImagePropertyExifDictionary as String] == nil
        guard noGPS && noEXIF else { try? FileManager.default.removeItem(at: url); throw FileError.metadata }
        return (url, true)
    }
    enum FileError: LocalizedError {
        case tooLarge, cancelled, badImage, metadata
        var errorDescription: String? {
            switch self {
            case .tooLarge: return "Limite file di questa versione: 2 GB."
            case .cancelled: return "Operazione annullata."
            case .badImage: return "Immagine non leggibile o troppo grande (massimo 30 MB)."
            case .metadata: return "La copia conserva metadati inattesi: esportazione bloccata."
            }
        }
    }
}
