import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipSymlinkSafetyTests: XCTestCase {
    func testRejectsEscapingSymlinkTargets() {
        let unsafe = ["../../outside", "/etc/passwd", "..\\escape", ""]
        for target in unsafe {
            XCTAssertFalse(CapacitorZipSecurePath.isSafeZipSymlinkTarget(target), "expected reject: \(target)")
        }
    }

    func testAcceptsRelativeSymlinkTargets() {
        XCTAssertTrue(CapacitorZipSecurePath.isSafeZipSymlinkTarget("app.js"))
        XCTAssertTrue(CapacitorZipSecurePath.isSafeZipSymlinkTarget("nested/file.txt"))
    }

    func testResolvePathInsideDirectoryRejectsTraversal() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("zip-base-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        XCTAssertThrowsError(
            try CapacitorZipSecurePath.resolvePathInsideDirectory(baseDirectory: base, relativePath: "../escape.txt")
        )
    }
}
