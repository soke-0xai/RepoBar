import OSLog

/// Lightweight opt-in logger controlled by user settings.
actor DiagnosticsLogger {
    static let shared = DiagnosticsLogger()
    private var enabled = false
    private let log = Logger(subsystem: "com.steipete.repobar", category: "diagnostics")

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    func message(_ text: String) {
        guard self.enabled else { return }
        self.log.info("\(text, privacy: .public)")
    }
}
