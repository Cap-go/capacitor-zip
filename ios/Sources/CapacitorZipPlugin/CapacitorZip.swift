import Foundation
import ZIPFoundation

public typealias CapacitorZipProgressHandler = ([String: Any]) -> Void

public class CapacitorZip: NSObject {

    /**
     * Creates a zip archive from a source file or directory
     * Note: Password protection is not supported on iOS with ZIPFoundation
     */
    public func zip(
        source: String,
        destination: String,
        password: String? = nil,
        includeParentFolder: Bool = true,
        progress: CapacitorZipProgressHandler? = nil
    ) throws {
        let progressMetadata = CapacitorZipProgressMetadata(
            operationId: "",
            source: source,
            destination: destination
        )
        try self.zip(
            source: source,
            destination: destination,
            password: password,
            includeParentFolder: includeParentFolder,
            progressMetadata: progressMetadata,
            progress: progress
        )
    }

    public func zip(
        source: String,
        destination: String,
        password: String? = nil,
        includeParentFolder: Bool = true,
        progressMetadata: CapacitorZipProgressMetadata,
        progress: CapacitorZipProgressHandler? = nil
    ) throws {
        let sourcePath = CapacitorZipPath.resolveFilesystemPath(source)
        let destinationPath = CapacitorZipPath.resolveFilesystemPath(destination)
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath)

        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw NSError(domain: "CapacitorZip", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source path does not exist"])
        }

        if password != nil && !password!.isEmpty {
            print("Warning: Password protection is not supported on iOS")
        }

        let parentDir = destinationURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
        }

        if FileManager.default.fileExists(atPath: destinationPath) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: sourcePath, isDirectory: &isDirectory)

        let stats = try computeSourceStats(at: sourceURL, includeParentFolder: includeParentFolder, isDirectory: isDirectory.boolValue)
        let tracker = ProgressTracker(operation: "zip", stats: stats, metadata: progressMetadata, handler: progress)

        if isDirectory.boolValue && !includeParentFolder {
            try zipDirectoryContents(at: sourceURL, to: destinationURL, tracker: tracker)
        } else {
            let archive = try Archive(url: destinationURL, accessMode: .create)
            try addItemToArchive(itemURL: sourceURL, archive: archive, basePath: "", tracker: tracker)
        }

        tracker.emitComplete()
    }

    private func zipDirectoryContents(at sourceURL: URL, to destinationURL: URL, tracker: ProgressTracker) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)

        if contents.isEmpty {
            _ = try Archive(url: destinationURL, accessMode: .create)
            return
        }

        let sortedContents = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let archive = try Archive(url: destinationURL, accessMode: .create)

        for itemURL in sortedContents {
            try addItemToArchive(itemURL: itemURL, archive: archive, basePath: "", tracker: tracker)
        }
    }

    private func addItemToArchive(itemURL: URL, archive: Archive, basePath: String, tracker: ProgressTracker) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory)

        let itemName = itemURL.lastPathComponent
        let archivePath = basePath.isEmpty ? itemName : "\(basePath)/\(itemName)"

        let attributes = try? fileManager.attributesOfItem(atPath: itemURL.path)
        let modificationDate = (attributes?[.modificationDate] as? Date) ?? Date()

        tracker.emitCurrentFile(archivePath)

        let isSymlink = (try? itemURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false

        if isSymlink {
            try archive.addEntry(with: archivePath, fileURL: itemURL, bufferSize: CapacitorZipIO.bufferBytes)
            tracker.completeFile()
            return
        }

        if isDirectory.boolValue {
            let dirPath = archivePath + "/"
            let permissions = (attributes?[.posixPermissions] as? NSNumber)?.uint16Value
            try archive.addEntry(
                with: dirPath,
                type: .directory,
                uncompressedSize: Int64(0),
                modificationDate: modificationDate,
                permissions: permissions,
                provider: { _, _ in
                    return Data()
                }
            )

            let contents = try fileManager.contentsOfDirectory(at: itemURL, includingPropertiesForKeys: nil)
            let sortedContents = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
            for subItemURL in sortedContents {
                try addItemToArchive(itemURL: subItemURL, archive: archive, basePath: archivePath, tracker: tracker)
            }
        } else {
            let fileSize = (try? fileManager.attributesOfItem(atPath: itemURL.path)[.size] as? NSNumber)?.int64Value ?? 0
            let bufferSize = CapacitorZipIO.bufferBytes
            let progress = Progress(totalUnitCount: max(fileSize, 1))
            let entryStart = tracker.loaded
            let observation = progress.observe(\.completedUnitCount, options: [.new]) { prog, _ in
                let entryLoaded = min(fileSize, prog.completedUnitCount)
                tracker.setLoaded(entryStart + entryLoaded)
            }
            defer {
                observation.invalidate()
            }
            try archive.addEntry(
                with: archivePath,
                fileURL: itemURL,
                compressionMethod: .deflate,
                bufferSize: bufferSize,
                progress: progress
            )
            tracker.completeFile()
        }
    }

    public func unzip(
        source: String,
        destination: String,
        password: String? = nil,
        progress: CapacitorZipProgressHandler? = nil
    ) throws {
        let progressMetadata = CapacitorZipProgressMetadata(
            operationId: "",
            source: source,
            destination: destination
        )
        try self.unzip(
            source: source,
            destination: destination,
            password: password,
            progressMetadata: progressMetadata,
            progress: progress
        )
    }

    public func unzip(
        source: String,
        destination: String,
        password: String? = nil,
        progressMetadata: CapacitorZipProgressMetadata,
        progress: CapacitorZipProgressHandler? = nil
    ) throws {
        let sourcePath = CapacitorZipPath.resolveFilesystemPath(source)
        let destinationPath = CapacitorZipPath.resolveFilesystemPath(destination)
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath)

        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw NSError(domain: "CapacitorZip", code: 2, userInfo: [NSLocalizedDescriptionKey: "Source zip file does not exist"])
        }

        if password != nil && !password!.isEmpty {
            print("Warning: Password protection is not supported on iOS")
        }

        if !FileManager.default.fileExists(atPath: destinationPath) {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }

        try CapacitorZipUnzip.unzipItem(at: sourceURL, to: destinationURL, metadata: progressMetadata, progress: progress)
    }

    private func computeSourceStats(at sourceURL: URL, includeParentFolder: Bool, isDirectory: Bool) throws -> ProgressStats {
        var stats = ProgressStats()
        if isDirectory {
            if includeParentFolder {
                accumulateDirectory(at: sourceURL, into: &stats)
            } else {
                let contents = try FileManager.default.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: [.fileSizeKey])
                for item in contents {
                    var isDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir)
                    if isDir.boolValue {
                        accumulateDirectory(at: item, into: &stats)
                    } else {
                        stats.filesTotal += 1
                        stats.totalBytes += fileSize(at: item)
                    }
                }
            }
        } else {
            stats.filesTotal = 1
            stats.totalBytes = fileSize(at: sourceURL)
        }
        return stats
    }

    private func accumulateDirectory(at url: URL, into stats: inout ProgressStats) {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey]) else {
            return
        }
        for case let fileURL as URL in enumerator {
            let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                continue
            }
            stats.filesTotal += 1
            stats.totalBytes += fileSize(at: fileURL)
        }
    }

    private func fileSize(at url: URL) -> Int64 {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return Int64(size)
    }
}

struct ProgressStats {
    var totalBytes: Int64 = 0
    var filesTotal: Int = 0
}

final class ProgressTracker {
    let operation: String
    let stats: ProgressStats
    let metadata: CapacitorZipProgressMetadata
    let handler: CapacitorZipProgressHandler?

    private let throttle = CapacitorZipProgressThrottle()

    var loaded: Int64 = 0
    var filesCompleted: Int = 0
    var currentFile: String?

    init(operation: String, stats: ProgressStats, metadata: CapacitorZipProgressMetadata, handler: CapacitorZipProgressHandler?) {
        self.operation = operation
        self.stats = stats
        self.metadata = metadata
        self.handler = handler
    }

    func emitCurrentFile(_ file: String) {
        currentFile = file
        emit()
    }

    func addLoaded(_ bytes: Int64) {
        loaded += bytes
        emit()
    }

    func setLoaded(_ bytes: Int64) {
        loaded = bytes
        emit()
    }

    func completeFile() {
        filesCompleted += 1
        emit()
    }

    func emitComplete() {
        if stats.totalBytes > 0 {
            loaded = stats.totalBytes
        }
        if stats.filesTotal > 0 {
            filesCompleted = stats.filesTotal
        }
        emit(operationComplete: true)
    }

    private func emit(operationComplete: Bool = false) {
        guard let handler = handler else { return }

        let progress = CapacitorZipProgressMath.progressRatio(
            loaded: loaded,
            totalBytes: stats.totalBytes,
            filesCompleted: filesCompleted,
            filesTotal: stats.filesTotal,
            operationComplete: operationComplete
        )
        if !throttle.shouldEmit(progress: progress, force: operationComplete) {
            return
        }
        throttle.recordEmit(progress: progress)

        let lengthComputable = stats.totalBytes > 0 || stats.filesTotal > 0

        var payload: [String: Any] = [
            "operationId": metadata.operationId,
            "source": metadata.source,
            "destination": metadata.destination,
            "operation": operation,
            "loaded": loaded,
            "total": stats.totalBytes,
            "progress": progress,
            "lengthComputable": lengthComputable,
            "filesCompleted": filesCompleted,
            "filesTotal": stats.filesTotal,
        ]
        if let currentFile = currentFile {
            payload["currentFile"] = currentFile
        }
        handler(payload)
    }
}
