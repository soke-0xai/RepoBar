import Foundation

public struct LocalRepoStatus: Equatable, Sendable {
    public let path: URL
    public let name: String
    public let fullName: String?
    public let branch: String
    public let isClean: Bool
    public let aheadCount: Int?
    public let behindCount: Int?
    public let syncState: LocalSyncState

    public init(
        path: URL,
        name: String,
        fullName: String?,
        branch: String,
        isClean: Bool,
        aheadCount: Int?,
        behindCount: Int?,
        syncState: LocalSyncState
    ) {
        self.path = path
        self.name = name
        self.fullName = fullName
        self.branch = branch
        self.isClean = isClean
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.syncState = syncState
    }

    public var displayName: String { self.fullName ?? self.name }

    public var syncDetail: String {
        switch self.syncState {
        case .synced:
            "Up to date"
        case .behind:
            self.behindCount.map { "Behind \($0)" } ?? "Behind"
        case .ahead:
            self.aheadCount.map { "Ahead \($0)" } ?? "Ahead"
        case .diverged:
            "Diverged"
        case .dirty:
            "Dirty"
        case .unknown:
            "No upstream"
        }
    }

    public var canAutoSync: Bool {
        self.isClean
            && self.syncState == .behind
            && (self.aheadCount ?? 0) == 0
            && self.branch != "detached"
    }
}

public enum LocalSyncState: String, Equatable, Sendable {
    case synced
    case behind
    case ahead
    case diverged
    case dirty
    case unknown

    public static func resolve(isClean: Bool, ahead: Int?, behind: Int?) -> LocalSyncState {
        if !isClean { return .dirty }
        guard let ahead, let behind else { return .unknown }
        if ahead == 0, behind == 0 { return .synced }
        if behind > 0, ahead == 0 { return .behind }
        if ahead > 0, behind == 0 { return .ahead }
        if ahead > 0, behind > 0 { return .diverged }
        return .unknown
    }

    public var symbolName: String {
        switch self {
        case .synced: "checkmark.square"
        case .behind: "arrow.down.square"
        case .ahead: "arrow.up.square"
        case .diverged: "arrow.triangle.branch"
        case .dirty: "exclamationmark.square"
        case .unknown: "questionmark.square"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .synced: "Up to date"
        case .behind: "Behind"
        case .ahead: "Ahead"
        case .diverged: "Diverged"
        case .dirty: "Dirty"
        case .unknown: "No upstream"
        }
    }
}

public struct LocalRepoIndex: Equatable, Sendable {
    public var all: [LocalRepoStatus] = []
    public var byFullName: [String: LocalRepoStatus] = [:]
    public var byName: [String: [LocalRepoStatus]] = [:]

    public static let empty = LocalRepoIndex()

    public init() {}

    public init(statuses: [LocalRepoStatus]) {
        self.all = statuses
        self.byFullName = Dictionary(uniqueKeysWithValues: statuses.compactMap { status in
            status.fullName.map { ($0, status) }
        })
        var nameIndex: [String: [LocalRepoStatus]] = [:]
        for status in statuses {
            nameIndex[status.name, default: []].append(status)
        }
        self.byName = nameIndex
    }

    public func status(for repo: Repository) -> LocalRepoStatus? {
        if let exact = self.byFullName[repo.fullName] { return exact }
        return self.uniqueStatus(forName: repo.name)
    }

    public func status(forFullName fullName: String) -> LocalRepoStatus? {
        if let exact = self.byFullName[fullName] { return exact }
        let name = fullName.split(separator: "/").last.map(String.init)
        if let name { return self.uniqueStatus(forName: name) }
        return nil
    }

    private func uniqueStatus(forName name: String) -> LocalRepoStatus? {
        guard let matches = self.byName[name], matches.count == 1 else { return nil }
        return matches.first
    }
}
