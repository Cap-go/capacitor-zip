import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipProgressThrottleTests: XCTestCase {
    func testThrottleMatchesAndroidDefaults() throws {
        let throttle = CapacitorZipProgressThrottle()
        XCTAssertTrue(throttle.shouldEmit(progress: 0.1, force: false))
        throttle.recordEmit(progress: 0.1)
        XCTAssertFalse(throttle.shouldEmit(progress: 0.1001, force: false))
        XCTAssertTrue(throttle.shouldEmit(progress: 0.1, force: true))
    }
}
