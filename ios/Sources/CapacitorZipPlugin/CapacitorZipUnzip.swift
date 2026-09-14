import Foundation
import ZIPFoundation

/// Unzips using the same behavior as `FileManager.unzipItem`, with an `autoreleasepool` per entry
/// to avoid retaining autoreleased objects across many small files (ZIPFoundation #391, Cap-go/capacitor-zip #11).
enum CapacitorZipUnzip {
    static func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }

        let archive = try Archive(url: sourceURL, accessMode: .read)

        for entry in archive {
            try autoreleasepool {
                let entryURL = destinationURL.appendingPathComponent(entry.path)
                guard entryURL.isContained(in: destinationURL) else {
                    throw CocoaError(.fileReadInvalidFileName, userInfo: [NSFilePathErrorKey: entryURL.path])
                }

                let crc32 = try archive.extract(entry, to: entryURL)
                if crc32 != entry.checksum {
                    throw Archive.ArchiveError.invalidCRC32
                }
            }
        }
    }
}

private extension FileManager {
    func itemExists(at url: URL) -> Bool {
        (try? url.checkResourceIsReachable()) == true
    }
}
