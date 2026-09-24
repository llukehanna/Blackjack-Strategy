import os

/// App-wide loggers (subsystem = bundle id).
enum AppLog {
    static let persistence = Logger(subsystem: "com.bjs.app", category: "persistence")
    static let settings = Logger(subsystem: "com.bjs.app", category: "settings")
}
