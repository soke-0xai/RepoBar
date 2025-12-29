import Foundation
import RepoBarCore

struct LocalRepoStatus: Equatable, Sendable {
    let path: URL
    let name: String
    let fullName: String?
    let branch: String
    let isClean: Bool
    let aheadCount: Int?
    let behindCount: Int?
    let syncState: LocalSyncState

    var displayName: String { self.fullName ?? self.name }

    var syncDetail: String {
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

    var canAutoSync: Bool {
        self.isClean
            && self.syncState == .behind
            && (self.aheadCount ?? 0) == 0
            && self.branch != "detached"
    }
}

enum LocalSyncState: String, Equatable, Sendable {
    case synced
    case behind
    case ahead
    case diverged
    case dirty
    case unknown

    static func resolve(isClean: Bool, ahead: Int?, behind: Int?) -> LocalSyncState {
        if !isClean { return .dirty }
        guard let ahead, let behind else { return .unknown }
        if ahead == 0, behind == 0 { return .synced }
        if behind > 0, ahead == 0 { return .behind }
        if ahead > 0, behind == 0 { return .ahead }
        if ahead > 0, behind > 0 { return .diverged }
        return .unknown
    }

    var symbolName: String {
        switch self {
        case .synced: "checkmark.square"
        case .behind: "arrow.down.square"
        case .ahead: "arrow.up.square"
        case .diverged: "arrow.triangle.branch"
        case .dirty: "exclamationmark.square"
        case .unknown: "questionmark.square"
        }
    }

    var accessibilityLabel: String {
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

struct LocalRepoIndex: Equatable {
    var all: [LocalRepoStatus] = []
    var byFullName: [String: LocalRepoStatus] = [:]
    var byName: [String: [LocalRepoStatus]] = [:]

    static let empty = LocalRepoIndex()

    init() {}

    init(statuses: [LocalRepoStatus]) {
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

    func status(for repo: Repository) -> LocalRepoStatus? {
        if let exact = self.byFullName[repo.fullName] { return exact }
        return self.uniqueStatus(forName: repo.name)
    }

    func status(forFullName fullName: String) -> LocalRepoStatus? {
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
