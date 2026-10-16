import XCTest
@testable import CapacitorZipPlugin

final class CapacitorZipUnzipSymlinkTests: XCTestCase {
    private var root = URL(fileURLWithPath: NSTemporaryDirectory())

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("capzip-unzip-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testUnzipRejectsEscapingSymlinks() throws {
        let targets = ["../../outside", "/etc/passwd"]
        for (index, target) in targets.enumerated() {
            var writer = TestZipWriter()
            writer.addFile("index.html", Data("<html></html>".utf8))
            writer.addSymlink("assets/link", target: target)
            let zipURL = root.appendingPathComponent("symlink-\(index).zip")
            try writer.write(to: zipURL)
            let dest = root.appendingPathComponent("dest-\(index)", isDirectory: true)
            try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)

            XCTAssertThrowsError(try CapacitorZipUnzip.unzipItem(at: zipURL, to: dest))
        }
    }

    func testUnzipExtractsSafeSymlink() throws {
        var writer = TestZipWriter()
        writer.addFile("assets/app.js", Data("js".utf8))
        writer.addSymlink("assets/alias.js", target: "app.js")
        let zipURL = root.appendingPathComponent("safe-symlink.zip")
        try writer.write(to: zipURL)
        let dest = root.appendingPathComponent("dest-safe", isDirectory: true)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)

        try CapacitorZipUnzip.unzipItem(at: zipURL, to: dest)
        let linkPath = dest.appendingPathComponent("assets/alias.js")
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: linkPath.path), "app.js")
    }
}
