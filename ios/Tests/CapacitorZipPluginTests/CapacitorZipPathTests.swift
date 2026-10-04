import XCTest
@testable import CapacitorZipPlugin

class CapacitorZipPathTests: XCTestCase {

    func testResolveFilesystemPath_leavesAbsolutePathUnchanged() {
        XCTAssertEqual("/tmp/archive.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/archive.zip"))
    }

    func testResolveFilesystemPath_convertsFileUrl() {
        let resolved = CapacitorZipPath.resolveFilesystemPath("file:///tmp/archive.zip")
        XCTAssertEqual("/tmp/archive.zip", resolved)
    }

    func testResolveFilesystemPath_decodesPercentEncoding() {
        XCTAssertEqual("/tmp/my folder/file.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/my%20folder/file.zip"))
        XCTAssertEqual(
            "/tmp/my folder/file.zip",
            CapacitorZipPath.resolveFilesystemPath("file:///tmp/my%20folder/file.zip")
        )
    }

    func testResolveFilesystemPath_preservesPlusSignInPlainPath() {
        XCTAssertEqual("/sdcard/a+b.zip", CapacitorZipPath.resolveFilesystemPath("/sdcard/a+b.zip"))
        XCTAssertEqual(
            "/sdcard/a+b.zip",
            CapacitorZipPath.resolveFilesystemPath("file:///sdcard/a%2Bb.zip")
        )
    }

    func testResolveFilesystemPath_decodesPercentInFileUrlWithoutDoubleDecoding() {
        XCTAssertEqual(
            "/sdcard/100%.zip",
            CapacitorZipPath.resolveFilesystemPath("file:///sdcard/100%25.zip")
        )
    }

    func testResolveFilesystemPath_leavesLiteralPercentInPlainPath() {
        XCTAssertEqual("/sdcard/100%/a.zip", CapacitorZipPath.resolveFilesystemPath("/sdcard/100%/a.zip"))
    }

    func testResolveFilesystemPath_decodesUtf8PercentSequences() {
        XCTAssertEqual("/tmp/Música/file.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/M%C3%BAsica/file.zip"))
    }

    func testResolveFilesystemPath_preservesNonAsciiAfterPercentLiterally() {
        XCTAssertEqual("/tmp/%5\u{301}x.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/%5\u{301}x.zip"))
    }

    func testResolveFilesystemPath_preservesNonBmpCharacterWhenDecoding() {
        XCTAssertEqual("/tmp/\u{1F600} a.zip", CapacitorZipPath.resolveFilesystemPath("/tmp/\u{1F600}%20a.zip"))
    }

    func testResolveFilesystemPath_stripsFileSchemeWhenUrlParseFails() {
        XCTAssertEqual(
            "/tmp/my folder/file.zip",
            CapacitorZipPath.resolveFilesystemPath("file:///tmp/my folder/file.zip")
        )
    }

    func testResolveFilesystemPath_stripsLocalhostAuthorityOnFallback() {
        XCTAssertEqual(
            "/tmp/my archive.zip",
            CapacitorZipPath.resolveFilesystemPath("file://localhost/tmp/my archive.zip")
        )
    }

    func testResolveFilesystemPath_preservesRelativeFileSchemePath() {
        XCTAssertEqual("/my archive.zip", CapacitorZipPath.resolveFilesystemPath("file:my archive.zip"))
    }

    func testZipUnzip_acceptsFileUrlPaths() throws {
        let fileManager = FileManager.default
        let temp = fileManager.temporaryDirectory
        let sourceFile = temp.appendingPathComponent("zip-source-\(UUID().uuidString).txt")
        try "hello".write(to: sourceFile, atomically: true, encoding: .utf8)

        let zipFile = temp.appendingPathComponent("out-\(UUID().uuidString).zip")
        let extractDir = temp.appendingPathComponent("extract-\(UUID().uuidString)", isDirectory: true)

        let implementation = CapacitorZip()
        try implementation.zip(
            source: sourceFile.absoluteURL.absoluteString,
            destination: zipFile.absoluteURL.absoluteString
        )
        try implementation.unzip(
            source: zipFile.absoluteURL.absoluteString,
            destination: extractDir.absoluteURL.absoluteString
        )

        let extracted = extractDir.appendingPathComponent(sourceFile.lastPathComponent)
        XCTAssertTrue(fileManager.fileExists(atPath: extracted.path))
        XCTAssertEqual("hello", try String(contentsOf: extracted, encoding: .utf8))
    }
}
