import Foundation

/// Stable error codes surfaced to JavaScript via plugin rejections (messages stay unchanged).
enum CapacitorZipErrorCode {
    static let sourceRequired = "ZIP_SOURCE_REQUIRED"
    static let destinationRequired = "ZIP_DESTINATION_REQUIRED"
    static let zipFailed = "ZIP_FAILED"
    static let unzipFailed = "ZIP_UNZIP_FAILED"
}

enum CapacitorZipError: Error {
    case unsafeSymlinkTarget
    case symlinkTargetTooLarge
}
