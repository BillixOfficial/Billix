import Foundation

/// Centralized logging utility for Billix
/// Logs are only printed in DEBUG builds to keep production clean
enum Logger {

    /// Log levels to control verbosity
    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
    }

    /// Enable/disable all logging (set to false to silence everything)
    static var isEnabled: Bool = true

    /// Minimum level to log (set to .error to only see errors, etc.)
    static var minimumLevel: Level = .debug

    // MARK: - Logging Methods

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    // MARK: - Private

    private static func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        #if DEBUG
        guard isEnabled else { return }

        // Check minimum level
        guard shouldLog(level) else { return }

        let fileName = (file as NSString).lastPathComponent
        let output = "[\(level.rawValue)] \(fileName):\(line) \(function) - \(message)"
        print(output)
        #endif
    }

    private static func shouldLog(_ level: Level) -> Bool {
        let levels: [Level] = [.debug, .info, .warning, .error]
        guard let currentIndex = levels.firstIndex(of: level),
              let minimumIndex = levels.firstIndex(of: minimumLevel) else {
            return true
        }
        return currentIndex >= minimumIndex
    }
}

// MARK: - Quick Silence Extension
extension Logger {
    /// Temporarily silence all logs
    static func silence() {
        isEnabled = false
    }

    /// Re-enable logs
    static func enable() {
        isEnabled = true
    }

    /// Only show warnings and errors
    static func quietMode() {
        minimumLevel = .warning
    }

    /// Show all logs
    static func verboseMode() {
        minimumLevel = .debug
    }
}
