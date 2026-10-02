import Foundation

enum CapacitorZipPath {
    /// Resolves `file://` URLs and percent-encoded path segments to a filesystem path.
    static func resolveFilesystemPath(_ path: String) -> String {
        if path.lowercased().hasPrefix("file:") {
            if let url = URL(string: path), url.isFileURL {
                return url.path
            }
            return stripFileScheme(path)
        }
        if !path.lowercased().hasPrefix("content:") && path.contains("%") {
            return decodePercentEncoded(path)
        }
        return path
    }

    static func stripFileScheme(_ path: String) -> String {
        var withoutScheme = path
        if withoutScheme.lowercased().hasPrefix("file://") {
            withoutScheme = String(withoutScheme.dropFirst(7))
        } else if withoutScheme.lowercased().hasPrefix("file:") {
            withoutScheme = String(withoutScheme.dropFirst(5))
        }
        if withoutScheme.hasPrefix("//") {
            let pathStart = withoutScheme.dropFirst(2).firstIndex(of: "/")
            withoutScheme = pathStart.map { String(withoutScheme[$0...]) } ?? "/"
        }
        if !withoutScheme.hasPrefix("/") {
            withoutScheme = "/" + withoutScheme
        }
        if withoutScheme.contains("%") {
            return decodePercentEncoded(withoutScheme)
        }
        return withoutScheme
    }

    static func decodePercentEncoded(_ path: String) -> String {
        var bytes = [UInt8]()
        var index = path.startIndex
        while index < path.endIndex {
            let c = path[index]
            if c == "%" {
                let next = path.index(after: index)
                let afterNext = path.index(next, offsetBy: 1, limitedBy: path.endIndex)
                if let afterNext = afterNext,
                   afterNext < path.endIndex,
                   let hi = hexValue(path[next]),
                   let lo = hexValue(path[afterNext]) {
                    bytes.append(UInt8((hi << 4) + lo))
                    index = path.index(after: afterNext)
                    continue
                }
            }
            for byte in String(c).utf8 {
                bytes.append(byte)
            }
            index = path.index(after: index)
        }
        return String(bytes: bytes, encoding: .utf8) ?? path
    }

    private static func hexValue(_ c: Character) -> Int? {
        switch c {
        case "0"..."9":
            return Int(c.asciiValue! - Character("0").asciiValue!)
        case "a"..."f":
            return Int(c.asciiValue! - Character("a").asciiValue!) + 10
        case "A"..."F":
            return Int(c.asciiValue! - Character("A").asciiValue!) + 10
        default:
            return nil
        }
    }
}
