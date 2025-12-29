import AppKit

enum TerminalApp: String, CaseIterable {
    case terminal = "Terminal"
    case iTerm2
    case ghostty = "Ghostty"
    case warp = "Warp"
    case alacritty = "Alacritty"
    case hyper = "Hyper"
    case wezterm = "WezTerm"
    case kitty = "Kitty"

    var bundleIdentifier: String {
        switch self {
        case .terminal: "com.apple.Terminal"
        case .iTerm2: "com.googlecode.iterm2"
        case .ghostty: "com.mitchellh.ghostty"
        case .warp: "dev.warp.Warp-Stable"
        case .alacritty: "org.alacritty"
        case .hyper: "co.zeit.hyper"
        case .wezterm: "com.github.wez.wezterm"
        case .kitty: "net.kovidgoyal.kitty"
        }
    }

    var displayName: String { self.rawValue }

    var isInstalled: Bool {
        if self == .terminal { return true }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleIdentifier) != nil
    }

    var appIcon: NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    static var installed: [TerminalApp] {
        allCases.filter(\.isInstalled)
    }

    static var defaultPreferred: TerminalApp {
        if let ghostty = installed.first(where: { $0 == .ghostty }) { return ghostty }
        return .terminal
    }

    static func resolve(_ rawValue: String?) -> TerminalApp {
        guard let rawValue, let match = TerminalApp(rawValue: rawValue), match.isInstalled else {
            return TerminalApp.defaultPreferred
        }
        return match
    }

    func open(at url: URL) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleIdentifier) else {
            NSWorkspace.shared.open(url)
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration)
    }
}
