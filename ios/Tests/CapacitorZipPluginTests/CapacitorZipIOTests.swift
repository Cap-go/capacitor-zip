import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipIOTests: XCTestCase {
    func testBufferBytesMatchesUpdaterCryptoCipher() {
        XCTAssertEqual(CapacitorZipIO.bufferBytes, 256 * 1024)
    }
}
