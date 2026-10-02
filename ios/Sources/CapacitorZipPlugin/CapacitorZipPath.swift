import Foundation

enum CapacitorZipPath {
    /// Resolves `file://` URLs and percent-encoded path segments to a filesystem path.
    static func resolveFilesystemPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("file:") {
            if let url = URL(string: trimmed), url.isFileURL {
                return url.path
            }
            if let url = URL(string: trimmed) {
                let path = url.path
                if !path.isEmpty {
                    return path
                }
            }
        }
        if trimmed.contains("%") {
            return trimmed.removingPercentEncoding ?? trimmed
        }
        return trimmed
    }
}
