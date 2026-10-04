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
        } else if !withoutScheme.hasPrefix("/") {
            if let slashIndex = withoutScheme.firstIndex(of: "/"), slashIndex > withoutScheme.startIndex {
                let authority = String(withoutScheme[..<slashIndex])
                if isFileUrlAuthority(authority) {
                    withoutScheme = String(withoutScheme[slashIndex...])
                } else {
                    withoutScheme = "/" + withoutScheme
                }
            } else {
                withoutScheme = "/" + withoutScheme
            }
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

    private static func isFileUrlAuthority(_ segment: String) -> Bool {
        if segment.lowercased() == "localhost" {
            return true
        }
        let parts = segment.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else {
            return false
        }
        return parts.allSatisfy { part in
            guard let value = Int(part), value >= 0, value <= 255 else {
                return false
            }
            return true
        }
    }

    private static func hexValue(_ c: Character) -> Int? {
        // Reject non-ASCII first: combining marks (e.g. "5\u{301}") fall inside the
        // Character ranges below but have no asciiValue.
        guard let ascii = c.asciiValue else {
            return nil
        }
        switch ascii {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return Int(ascii - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "f"):
            return Int(ascii - UInt8(ascii: "a")) + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"):
            return Int(ascii - UInt8(ascii: "A")) + 10
        default:
            return nil
        }
    }
}
