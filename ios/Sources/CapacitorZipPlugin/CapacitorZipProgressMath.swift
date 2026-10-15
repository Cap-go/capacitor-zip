import Foundation

enum CapacitorZipProgressMath {
    static func progressRatio(
        loaded: Int64,
        totalBytes: Int64,
        filesCompleted: Int,
        filesTotal: Int,
        operationComplete: Bool
    ) -> Double {
        if totalBytes > 0 {
            return min(1.0, Double(loaded) / Double(totalBytes))
        }
        if filesTotal > 0 {
            return min(1.0, Double(filesCompleted) / Double(filesTotal))
        }
        if operationComplete {
            return 1.0
        }
        return 0
    }
}
