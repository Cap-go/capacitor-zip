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
        var tracker = ProgressTracker(operation: "zip", stats: stats, handler: progress)

        if isDirectory.boolValue && !includeParentFolder {
            try zipDirectoryContents(at: sourceURL, to: destinationURL, tracker: &tracker)
        } else {
            let archive = try Archive(url: destinationURL, accessMode: .create)
            try addItemToArchive(itemURL: sourceURL, archive: archive, basePath: "", tracker: &tracker)
        }

        tracker.emitComplete()
    }

    private func zipDirectoryContents(at sourceURL: URL, to destinationURL: URL, tracker: inout ProgressTracker) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)

        if contents.isEmpty {
            _ = try Archive(url: destinationURL, accessMode: .create)
            return
        }

        let sortedContents = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let archive = try Archive(url: destinationURL, accessMode: .create)

        for itemURL in sortedContents {
            try addItemToArchive(itemURL: itemURL, archive: archive, basePath: "", tracker: &tracker)
        }
    }

    private func addItemToArchive(itemURL: URL, archive: Archive, basePath: String, tracker: inout ProgressTracker) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory)

        let itemName = itemURL.lastPathComponent
        let archivePath = basePath.isEmpty ? itemName : "\(basePath)/\(itemName)"

        let attributes = try? fileManager.attributesOfItem(atPath: itemURL.path)
        let modificationDate = (attributes?[.modificationDate] as? Date) ?? Date()

        tracker.emitCurrentFile(archivePath)

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
                try addItemToArchive(itemURL: subItemURL, archive: archive, basePath: archivePath, tracker: &tracker)
            }
        } else {
            let fileSize = (try? fileManager.attributesOfItem(atPath: itemURL.path)[.size] as? NSNumber)?.int64Value ?? 0
            try archive.addEntry(with: archivePath, fileURL: itemURL)
            tracker.completeFile(bytes: fileSize)
        }
    }

    public func unzip(
        source: String,
        destination: String,
        password: String? = nil,
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

        try CapacitorZipUnzip.unzipItem(at: sourceURL, to: destinationURL, progress: progress)
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

struct ProgressTracker {
    let operation: String
    let stats: ProgressStats
    let handler: CapacitorZipProgressHandler?

    var loaded: Int64 = 0
    var filesCompleted: Int = 0
    var currentFile: String?

    mutating func emitCurrentFile(_ file: String) {
        currentFile = file
        emit()
    }

    mutating func completeFile(bytes: Int64) {
        loaded += bytes
        filesCompleted += 1
        emit()
    }

    mutating func emitComplete() {
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
        let lengthComputable = stats.totalBytes > 0 || stats.filesTotal > 0

        var payload: [String: Any] = [
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
