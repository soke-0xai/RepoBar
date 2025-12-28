import Foundation

/// Persists simple user settings in UserDefaults.
public struct SettingsStore {
    private let defaults: UserDefaults
    static let storageKey = "com.steipete.repobar.settings"
    private let key = Self.storageKey
    private static let currentVersion = 1

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> UserSettings {
        guard let data = defaults.data(forKey: key) else {
            return UserSettings()
        }
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(SettingsEnvelope.self, from: data) {
            var settings = envelope.settings
            if envelope.version < Self.currentVersion {
                Self.applyMigrations(to: &settings, fromVersion: envelope.version)
                save(settings)
            }
            return settings
        }
        if let legacy = try? decoder.decode(LegacyUserSettings.self, from: data) {
            let settings = Self.migrateLegacySettings(from: legacy)
            save(settings)
            return settings
        }
        return UserSettings()
    }

    public func save(_ settings: UserSettings) {
        let envelope = SettingsEnvelope(version: Self.currentVersion, settings: settings)
        if let data = try? JSONEncoder().encode(envelope) {
            self.defaults.set(data, forKey: self.key)
        }
    }

    private static func applyMigrations(to settings: inout UserSettings, fromVersion: Int) {
        guard fromVersion < currentVersion else { return }
    }

    private static func migrateLegacySettings(from legacy: LegacyUserSettings) -> UserSettings {
        var settings = UserSettings()
        settings.showContributionHeader = legacy.showContributionHeader ?? settings.showContributionHeader
        settings.repoDisplayLimit = legacy.repoDisplayLimit ?? settings.repoDisplayLimit
        settings.showForks = legacy.showForks ?? settings.showForks
        settings.showArchived = legacy.showArchived ?? settings.showArchived
        settings.refreshInterval = legacy.refreshInterval ?? settings.refreshInterval
        settings.launchAtLogin = legacy.launchAtLogin ?? settings.launchAtLogin
        settings.heatmapSpan = legacy.heatmapSpan ?? settings.heatmapSpan
        settings.cardDensity = legacy.cardDensity ?? settings.cardDensity
        settings.accentTone = legacy.accentTone ?? settings.accentTone
        settings.menuSortKey = legacy.menuSortKey ?? settings.menuSortKey
        settings.debugPaneEnabled = legacy.debugPaneEnabled ?? settings.debugPaneEnabled
        settings.diagnosticsEnabled = legacy.diagnosticsEnabled ?? settings.diagnosticsEnabled
        settings.githubHost = legacy.githubHost ?? settings.githubHost
        settings.enterpriseHost = legacy.enterpriseHost ?? settings.enterpriseHost
        settings.loopbackPort = legacy.loopbackPort ?? settings.loopbackPort
        settings.pinnedRepositories = legacy.pinnedRepositories ?? settings.pinnedRepositories
        settings.hiddenRepositories = legacy.hiddenRepositories ?? settings.hiddenRepositories

        if let showHeatmap = legacy.showHeatmap {
            settings.heatmapDisplay = showHeatmap ? .inline : .submenu
        } else if let heatmapDisplay = legacy.heatmapDisplay {
            settings.heatmapDisplay = heatmapDisplay
        }

        return settings
    }
}

private struct SettingsEnvelope: Codable {
    let version: Int
    let settings: UserSettings
}

private struct LegacyUserSettings: Codable {
    var showContributionHeader: Bool?
    var repoDisplayLimit: Int?
    var showForks: Bool?
    var showArchived: Bool?
    var refreshInterval: RefreshInterval?
    var launchAtLogin: Bool?
    var heatmapDisplay: HeatmapDisplay?
    var heatmapSpan: HeatmapSpan?
    var cardDensity: CardDensity?
    var accentTone: AccentTone?
    var menuSortKey: RepositorySortKey?
    var debugPaneEnabled: Bool?
    var diagnosticsEnabled: Bool?
    var githubHost: URL?
    var enterpriseHost: URL?
    var loopbackPort: Int?
    var pinnedRepositories: [String]?
    var hiddenRepositories: [String]?
    var showHeatmap: Bool?
}
