import Foundation

/// Path and symlink validation aligned with Cap-go/capacitor-updater zip extraction.
enum CapacitorZipSecurePath {
    enum SecurePathError: Error {
        case emptyPath
        case windowsPath
        case absolutePath
        case pathTraversal
    }

    static let maxZipSymlinkTargetBytes = 64 * 1024

    static func containsPathTraversalSegment(_ relativePath: String) -> Bool {
        return relativePath.split(separator: "/").contains(where: { $0 == ".." })
    }

    static func resolvePathInsideDirectory(baseDirectory: URL, relativePath: String) throws -> URL {
        if relativePath.isEmpty {
            throw SecurePathError.emptyPath
        }
        if relativePath.contains("\\") || relativePath.contains("\0") {
            throw SecurePathError.windowsPath
        }
        if containsPathTraversalSegment(relativePath) {
            throw SecurePathError.pathTraversal
        }
        if (relativePath as NSString).isAbsolutePath {
            throw SecurePathError.absolutePath
        }

        let canonicalBase = baseDirectory.standardizedFileURL
        let canonicalBasePath = canonicalBase.path
        let normalizedBasePath = canonicalBasePath.hasSuffix("/") ? canonicalBasePath : "\(canonicalBasePath)/"
        let canonicalTarget = canonicalBase.appendingPathComponent(relativePath).standardizedFileURL
        let canonicalTargetPath = canonicalTarget.path

        if !canonicalTargetPath.hasPrefix(normalizedBasePath) {
            throw SecurePathError.pathTraversal
        }

        return canonicalTarget
    }

    static func isSafeZipSymlinkTarget(_ target: String) -> Bool {
        if target.isEmpty || target.contains("\0") || target.contains("\\") {
            return false
        }
        if (target as NSString).isAbsolutePath {
            return false
        }
        return !containsPathTraversalSegment(target)
    }

    private static func realPath(_ path: String) -> String? {
        guard let resolved = Darwin.realpath(path, nil) else {
            return nil
        }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    static func assertPhysicallyInsideDirectory(_ url: URL, root: URL) throws {
        guard let rootPath = realPath(root.path) else {
            throw SecurePathError.pathTraversal
        }
        let normalizedRoot = rootPath.hasSuffix("/") ? rootPath : "\(rootPath)/"
        var candidate = url.standardizedFileURL.path
        while true {
            if let resolved = realPath(candidate) {
                if resolved != rootPath && !resolved.hasPrefix(normalizedRoot) {
                    throw SecurePathError.pathTraversal
                }
                return
            }
            let parent = (candidate as NSString).deletingLastPathComponent
            if parent == candidate || parent.isEmpty {
                throw SecurePathError.pathTraversal
            }
            candidate = parent
        }
    }

    static func itemExistsWithoutFollowingLink(at url: URL) -> Bool {
        return (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil
    }
}
