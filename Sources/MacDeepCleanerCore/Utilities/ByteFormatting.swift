import Foundation
import OSLog

public enum ByteFormatting {
    public static func string(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

public enum CleanerLog {
    public static let subsystem = "app.macdeepcleaner"
}

public enum CleanerLogger {
    public static let scanner = Logger(subsystem: CleanerLog.subsystem, category: "scanner")
    public static let trash = Logger(subsystem: CleanerLog.subsystem, category: "trash")
    public static let permissions = Logger(subsystem: CleanerLog.subsystem, category: "permissions")
}
