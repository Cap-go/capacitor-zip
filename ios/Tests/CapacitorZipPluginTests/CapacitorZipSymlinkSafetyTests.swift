import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipSymlinkSafetyTests: XCTestCase {
    func testRejectsEscapingSymlinkTargets() {
        let unsafe = ["../../outside", "/etc/passwd", "..\\escape", ""]
        for target in unsafe {
            XCTAssertFalse(CapacitorZipSymlinkSafety.isSafeZipSymlinkTarget(target), "expected reject: \(target)")
        }
    }

    func testAcceptsRelativeSymlinkTargets() {
        XCTAssertTrue(CapacitorZipSymlinkSafety.isSafeZipSymlinkTarget("app.js"))
        XCTAssertTrue(CapacitorZipSymlinkSafety.isSafeZipSymlinkTarget("nested/file.txt"))
    }
}
