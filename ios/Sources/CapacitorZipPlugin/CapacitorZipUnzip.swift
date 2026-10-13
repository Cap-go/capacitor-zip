import Foundation
import ZIPFoundation

/// Unzips using the same behavior as `FileManager.unzipItem`, with an `autoreleasepool` per entry
/// to avoid retaining autoreleased objects across many small files (ZIPFoundation #391, Cap-go/capacitor-zip #11).
enum CapacitorZipUnzip {
    static func unzipItem(at sourceURL: URL, to destinationURL: URL, progress: CapacitorZipProgressHandler? = nil) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }

        let archive = try Archive(url: sourceURL, accessMode: .read)
        let entries = Array(archive)
        var stats = ProgressStats()
        stats.filesTotal = entries.count
        for entry in entries {
            if entry.type == .file {
                stats.totalBytes += Int64(entry.uncompressedSize)
            }
        }

        var tracker = ProgressTracker(operation: "unzip", stats: stats, handler: progress)

        for entry in entries {
            try autoreleasepool {
                tracker.emitCurrentFile(entry.path)
                let entryURL = destinationURL.appendingPathComponent(entry.path)
                guard entryURL.isContained(in: destinationURL) else {
                    throw CocoaError(.fileReadInvalidFileName, userInfo: [NSFilePathErrorKey: entryURL.path])
                }

                let crc32 = try archive.extract(entry, to: entryURL)
                if crc32 != entry.checksum {
                    throw Archive.ArchiveError.invalidCRC32
                }

                let bytes: Int64 = entry.type == .file ? Int64(entry.uncompressedSize) : 0
                tracker.completeFile(bytes: bytes)
            }
        }

        tracker.emitComplete()
    }
}

private extension FileManager {
    func itemExists(at url: URL) -> Bool {
        (try? url.checkResourceIsReachable()) == true
    }
}
