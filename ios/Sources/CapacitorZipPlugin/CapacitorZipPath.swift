import Foundation

enum CapacitorZipPath {
    /// Resolves `file://` URLs and percent-encoded path segments to a filesystem path.
    static func resolveFilesystemPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("file:") {
            if let url = URL(string: trimmed), url.isFileURL {
                return url.path
            }
            if let url = URL(string: trimmed) {
                let path = url.path
                if !path.isEmpty {
                    return path
                }
            }
        }
        if trimmed.contains("%") {
            return decodePercentEncoded(trimmed)
        }
        return trimmed
    }

    static func decodePercentEncoded(_ path: String) -> String {
        var out = ""
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
                    let code = (hi << 4) + lo
                    out.append(Character(UnicodeScalar(code)!))
                    index = path.index(after: afterNext)
                    continue
                }
            }
            out.append(c)
            index = path.index(after: index)
        }
        return out
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
