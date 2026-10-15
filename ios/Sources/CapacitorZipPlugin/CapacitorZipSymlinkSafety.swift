import Foundation

/// Symlink target validation aligned with Cap-go/capacitor-updater `extractZipEntry`.
enum CapacitorZipSymlinkSafety {
    static let maxZipSymlinkTargetBytes = 64 * 1024

    static func isSafeZipSymlinkTarget(_ target: String) -> Bool {
        if target.isEmpty || target.contains("\0") || target.contains("\\") {
            return false
        }
        if (target as NSString).isAbsolutePath {
            return false
        }
        return !containsPathTraversalSegment(target)
    }

    static func containsPathTraversalSegment(_ relativePath: String) -> Bool {
        for segment in relativePath.split(separator: "/", omittingEmptySubsequences: false) {
            if segment == ".." {
                return true
            }
        }
        return false
    }

    static func validateSymlinkTarget(_ linkPath: String, parentDir: URL) throws {
        guard isSafeZipSymlinkTarget(linkPath) else {
            throw CapacitorZipError.unsafeSymlinkTarget
        }

        let isAbsolutePath = (linkPath as NSString).isAbsolutePath
        let linkURL = URL(fileURLWithPath: linkPath, relativeTo: isAbsolutePath ? nil : parentDir)
        let canonicalPath = linkURL.standardizedFileURL.path
        let canonicalDir = parentDir.standardizedFileURL.path
        let normalizedDir = canonicalDir.hasSuffix("/") ? canonicalDir : "\(canonicalDir)/"

        if canonicalPath != canonicalDir && !canonicalPath.hasPrefix(normalizedDir) {
            throw CapacitorZipError.unsafeSymlinkTarget
        }
    }
}
