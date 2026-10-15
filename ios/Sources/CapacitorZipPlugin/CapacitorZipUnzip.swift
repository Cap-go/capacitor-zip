import Foundation

/// Unzips with the in-repo `ZipArchiveReader`, updater-style path guards, and byte-level progress.
enum CapacitorZipUnzip {
    static func unzipItem(at sourceURL: URL, to destinationURL: URL, progress: CapacitorZipProgressHandler? = nil) throws {
        let fileManager = FileManager.default
        guard (try? sourceURL.checkResourceIsReachable()) == true else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }

        let bufferSize = CapacitorZipIO.bufferBytes
        let archive = try ZipArchiveReader(url: sourceURL)

        var stats = ProgressStats()
        for entry in archive.entries {
            stats.filesTotal += 1
            if entry.type == .file {
                stats.totalBytes += Int64(entry.uncompressedSize)
            }
        }

        let tracker = ProgressTracker(operation: "unzip", stats: stats, handler: progress)

        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }

        for entry in archive.entries {
            try autoreleasepool {
                tracker.emitCurrentFile(entry.path)
                let destPath: URL
                do {
                    destPath = try CapacitorZipSecurePath.resolvePathInsideDirectory(
                        baseDirectory: destinationURL,
                        relativePath: entry.path
                    )
                } catch {
                    throw CocoaError(.fileReadInvalidFileName, userInfo: [NSFilePathErrorKey: entry.path])
                }

                try CapacitorZipSecurePath.assertPhysicallyInsideDirectory(
                    destPath.deletingLastPathComponent(),
                    root: destinationURL
                )

                try extractZipEntry(
                    archive: archive,
                    entry: entry,
                    to: destPath,
                    bufferSize: bufferSize,
                    tracker: tracker
                )
                tracker.completeFile()
            }
        }

        tracker.emitComplete()
    }

    private static func extractZipEntry(
        archive: ZipArchiveReader,
        entry: ZipEntry,
        to destPath: URL,
        bufferSize: Int,
        tracker: ProgressTracker
    ) throws {
        let fileManager = FileManager.default

        switch entry.type {
        case .directory:
            try fileManager.createDirectory(at: destPath, withIntermediateDirectories: true, attributes: nil)
        case .file:
            let parentDir = destPath.deletingLastPathComponent()
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)

            if CapacitorZipSecurePath.itemExistsWithoutFollowingLink(at: destPath) {
                try fileManager.removeItem(at: destPath)
            }

            guard fileManager.createFile(atPath: destPath.path, contents: nil) else {
                throw CapacitorZipError.unzipEntryFailed
            }

            let fileHandle = try FileHandle(forWritingTo: destPath)
            defer {
                fileHandle.closeFile()
            }

            try archive.extract(entry, bufferSize: bufferSize) { data in
                if !data.isEmpty {
                    fileHandle.write(data)
                    tracker.addLoaded(Int64(data.count))
                }
            }
        case .symlink:
            let linkData = try archive.readSmallEntry(
                entry,
                maxBytes: CapacitorZipSecurePath.maxZipSymlinkTargetBytes,
                bufferSize: bufferSize
            )

            guard let linkPath = String(data: linkData, encoding: .utf8),
                  CapacitorZipSecurePath.isSafeZipSymlinkTarget(linkPath) else {
                throw CapacitorZipError.unsafeSymlinkTarget
            }

            let parentDir = destPath.deletingLastPathComponent()
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)

            let isAbsolutePath = (linkPath as NSString).isAbsolutePath
            let linkURL = URL(fileURLWithPath: linkPath, relativeTo: isAbsolutePath ? nil : parentDir)
            let canonicalPath = linkURL.standardizedFileURL.path
            let canonicalDir = parentDir.standardizedFileURL.path
            let normalizedDir = canonicalDir.hasSuffix("/") ? canonicalDir : "\(canonicalDir)/"

            if canonicalPath != canonicalDir && !canonicalPath.hasPrefix(normalizedDir) {
                throw CapacitorZipError.unsafeSymlinkTarget
            }

            if CapacitorZipSecurePath.itemExistsWithoutFollowingLink(at: destPath) {
                try fileManager.removeItem(at: destPath)
            }

            try fileManager.createSymbolicLink(atPath: destPath.path, withDestinationPath: linkPath)
        }
    }
}
