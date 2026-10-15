import Foundation

/// Limits how often progress listeners are notified during chunked I/O (matches Android).
final class CapacitorZipProgressThrottle {
    private let minEmitIntervalMs: Int64 = 50
    private let minProgressDelta = 0.005

    private var lastEmitMs: Int64 = 0
    private var lastProgress: Double = -1

    func shouldEmit(progress: Double, force: Bool) -> Bool {
        if force {
            return true
        }
        if lastProgress < 0 {
            return true
        }
        if progress >= 1.0 {
            return true
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        if now - lastEmitMs >= minEmitIntervalMs {
            return true
        }
        return abs(progress - lastProgress) >= minProgressDelta
    }

    func recordEmit(progress: Double) {
        lastEmitMs = Int64(Date().timeIntervalSince1970 * 1000)
        lastProgress = progress
    }
}
