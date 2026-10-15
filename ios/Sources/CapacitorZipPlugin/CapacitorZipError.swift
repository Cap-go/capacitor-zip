import Foundation

/// Stable error codes surfaced to JavaScript via plugin rejections (messages stay unchanged).
enum CapacitorZipErrorCode {
    static let sourceRequired = "ZIP_SOURCE_REQUIRED"
    static let destinationRequired = "ZIP_DESTINATION_REQUIRED"
    static let zipFailed = "ZIP_FAILED"
    static let unzipFailed = "ZIP_UNZIP_FAILED"
}

enum CapacitorZipError: LocalizedError {
    case unsafeSymlinkTarget
    case symlinkTargetTooLarge
    case unzipEntryFailed
    case invalidZipPath

    var errorDescription: String? {
        switch self {
        case .unsafeSymlinkTarget:
            return "Symlink target escapes the destination directory"
        case .symlinkTargetTooLarge:
            return "Symlink target is too large"
        case .unzipEntryFailed:
            return "Failed to extract zip entry"
        case .invalidZipPath:
            return "Entry is outside of the target directory"
        }
    }
}
