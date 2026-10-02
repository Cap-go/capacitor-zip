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

    func testZipUnzip_acceptsFileUrlPaths() throws {
        let fileManager = FileManager.default
        let temp = fileManager.temporaryDirectory
        let sourceFile = temp.appendingPathComponent("zip-source-\(UUID().uuidString).txt")
        try "hello".write(to: sourceFile, atomically: true, encoding: .utf8)

        let zipFile = temp.appendingPathComponent("out-\(UUID().uuidString).zip")
        let extractDir = temp.appendingPathComponent("extract-\(UUID().uuidString)", isDirectory: true)

        let implementation = CapacitorZip()
        try implementation.zip(source: sourceFile.path, destination: zipFile.path)
        try implementation.unzip(
            source: zipFile.absoluteURL.absoluteString,
            destination: extractDir.absoluteURL.absoluteString
        )

        let extracted = extractDir.appendingPathComponent(sourceFile.lastPathComponent)
        XCTAssertTrue(fileManager.fileExists(atPath: extracted.path))
        XCTAssertEqual("hello", try String(contentsOf: extracted, encoding: .utf8))
    }
}
