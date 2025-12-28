import Foundation

@MainActor
final class SettingsOpener {
    static let shared = SettingsOpener()
    private var openHandler: (() -> Void)?

    private init() {}

    func configure(open: @escaping () -> Void) {
        self.openHandler = open
    }

    func open() {
        self.openHandler?()
    }
}
