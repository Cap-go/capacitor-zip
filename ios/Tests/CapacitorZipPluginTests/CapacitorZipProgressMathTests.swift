import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipProgressMathTests: XCTestCase {
    func testEmptyArchiveCompleteReportsFullProgress() {
        XCTAssertEqual(CapacitorZipProgressMath.progressRatio(loaded: 0, totalBytes: 0, filesCompleted: 0, filesTotal: 0, operationComplete: true), 1.0)
        XCTAssertEqual(CapacitorZipProgressMath.progressRatio(loaded: 0, totalBytes: 0, filesCompleted: 0, filesTotal: 0, operationComplete: false), 0.0)
    }
}
