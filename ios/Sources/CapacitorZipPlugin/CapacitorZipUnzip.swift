import Foundation
import ZIPFoundation

/// Unzips with per-entry autorelease pools, symlink hardening, and byte-level progress.
enum CapacitorZipUnzip {
    static func unzipItem(at sourceURL: URL, to destinationURL: URL, progress: CapacitorZipProgressHandler? = nil) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }

        let bufferSize = CapacitorZipIO.bufferBytes
        let archive = try Archive(url: sourceURL, accessMode: .read)

        var stats = ProgressStats()
        for entry in archive {
            stats.filesTotal += 1
            if entry.type == .file {
                stats.totalBytes += Int64(entry.uncompressedSize)
            }
        }

        let tracker = ProgressTracker(operation: "unzip", stats: stats, handler: progress)

        for entry in archive {
            try autoreleasepool {
                tracker.emitCurrentFile(entry.path)
                let entryURL = destinationURL.appendingPathComponent(entry.path)
                guard entryURL.isContained(in: destinationURL) else {
                    throw CocoaError(.fileReadInvalidFileName, userInfo: [NSFilePathErrorKey: entryURL.path])
                }

                switch entry.type {
                case .directory:
                    try fileManager.createDirectory(at: entryURL, withIntermediateDirectories: true, attributes: nil)
                    tracker.completeFile()
                case .file:
                    let crc32 = try extractFile(
                        archive: archive,
                        entry: entry,
                        to: entryURL,
                        bufferSize: bufferSize,
                        tracker: tracker
                    )
                    if crc32 != entry.checksum {
                        throw Archive.ArchiveError.invalidCRC32
                    }
                    tracker.completeFile()
                case .symlink:
                    try extractSymlink(archive: archive, entry: entry, to: entryURL, bufferSize: bufferSize)
                    tracker.completeFile()
                }
            }
        }

        tracker.emitComplete()
    }

    private static func extractFile(
        archive: Archive,
        entry: Entry,
        to entryURL: URL,
        bufferSize: Int,
        tracker: ProgressTracker
    ) throws -> CRC32 {
        let fileManager = FileManager.default
        if CapacitorZipUnzip.itemExistsWithoutFollowingLink(at: entryURL) {
            try fileManager.removeItem(at: entryURL)
        }
        try fileManager.createParentDirectoryStructure(for: entryURL)

        guard fileManager.createFile(atPath: entryURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: entryURL.path])
        }

        let fileHandle = try FileHandle(forWritingTo: entryURL)
        defer {
            fileHandle.closeFile()
        }

        let crc32 = try archive.extract(entry, bufferSize: bufferSize) { data in
            if !data.isEmpty {
                fileHandle.write(data)
                tracker.addLoaded(Int64(data.count))
            }
        }
        try fileManager.transferAttributes(from: entry, toItemAtURL: entryURL)
        return crc32
    }

    private static func extractSymlink(
        archive: Archive,
        entry: Entry,
        to destPath: URL,
        bufferSize: Int
    ) throws {
        let fileManager = FileManager.default
        var linkData = Data()

        _ = try archive.extract(entry, bufferSize: bufferSize) { chunk in
            guard linkData.count + chunk.count <= CapacitorZipSymlinkSafety.maxZipSymlinkTargetBytes else {
                throw CapacitorZipError.symlinkTargetTooLarge
            }
            linkData.append(chunk)
        }

        guard let linkPath = String(data: linkData, encoding: .utf8) else {
            throw CapacitorZipError.unsafeSymlinkTarget
        }

        let parentDir = destPath.deletingLastPathComponent()
        try CapacitorZipSymlinkSafety.validateSymlinkTarget(linkPath, parentDir: parentDir)
        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)

        if itemExistsWithoutFollowingLink(at: destPath) {
            try fileManager.removeItem(at: destPath)
        }

        try fileManager.createSymbolicLink(atPath: destPath.path, withDestinationPath: linkPath)
    }

    private static func itemExistsWithoutFollowingLink(at url: URL) -> Bool {
        return (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil
    }
}

private extension FileManager {
    func itemExists(at url: URL) -> Bool {
        (try? url.checkResourceIsReachable()) == true
    }
}
