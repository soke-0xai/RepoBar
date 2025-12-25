import Foundation
import RepoBarCore

struct RepoRow {
    let repo: Repository
    let activityDate: Date?
    let activityLabel: String
    let activityLine: String
}

struct RepoOutput: Codable {
    let fullName: String
    let owner: String
    let name: String
    let openIssues: Int
    let openPulls: Int
    let stars: Int
    let pushedAt: Date?
    let activityDate: Date?
    let activityTitle: String?
    let activityActor: String?
    let activityUrl: URL?
    let error: String?
}

struct StatusOutput: Codable {
    let authenticated: Bool
    let host: String?
    let expiresAt: Date?
    let expiresIn: String?
    let expired: Bool?
}

func prepareRows(repos: [Repository], now: Date = Date()) -> [RepoRow] {
    repos.map { repo in
        let activityDate = repo.activityDate
        let activityLabel = activityDate.map { RelativeFormatter.string(from: $0, relativeTo: now) } ?? "-"
        let activityLine = repo.activityLine(fallbackToPush: true) ?? "-"
        return RepoRow(repo: repo, activityDate: activityDate, activityLabel: activityLabel, activityLine: activityLine)
    }
}

func sortRows(_ rows: [RepoRow], sortKey: SortKey) -> [RepoRow] {
    rows.sorted { lhs, rhs in
        if let preferred = compare(lhs: lhs, rhs: rhs, sortKey: sortKey) { return preferred }
        let leftDate = lhs.activityDate ?? .distantPast
        let rightDate = rhs.activityDate ?? .distantPast
        if leftDate != rightDate { return leftDate > rightDate }
        if lhs.repo.openIssues != rhs.repo.openIssues { return lhs.repo.openIssues > rhs.repo.openIssues }
        if lhs.repo.openPulls != rhs.repo.openPulls { return lhs.repo.openPulls > rhs.repo.openPulls }
        if lhs.repo.stars != rhs.repo.stars { return lhs.repo.stars > rhs.repo.stars }
        return lhs.repo.fullName.localizedCaseInsensitiveCompare(rhs.repo.fullName) == .orderedAscending
    }
}

private func compare(lhs: RepoRow, rhs: RepoRow, sortKey: SortKey) -> Bool? {
    switch sortKey {
    case .activity:
        let leftDate = lhs.activityDate ?? .distantPast
        let rightDate = rhs.activityDate ?? .distantPast
        if leftDate != rightDate { return leftDate > rightDate }
        return nil
    case .issues:
        if lhs.repo.openIssues != rhs.repo.openIssues { return lhs.repo.openIssues > rhs.repo.openIssues }
        return nil
    case .pulls:
        if lhs.repo.openPulls != rhs.repo.openPulls { return lhs.repo.openPulls > rhs.repo.openPulls }
        return nil
    case .stars:
        if lhs.repo.stars != rhs.repo.stars { return lhs.repo.stars > rhs.repo.stars }
        return nil
    case .repo:
        let order = lhs.repo.fullName.localizedCaseInsensitiveCompare(rhs.repo.fullName)
        if order != .orderedSame { return order == .orderedAscending }
        return nil
    case .event:
        let left = lhs.activityLine.singleLine
        let right = rhs.activityLine.singleLine
        if left != right { return left.localizedCaseInsensitiveCompare(right) == .orderedAscending }
        return nil
    }
}

func renderTable(_ rows: [RepoRow], useColor: Bool) {
    let activityHeader = "ACTIVITY"
    let issuesHeader = "ISSUES"
    let pullsHeader = "PR"
    let starsHeader = "STAR"
    let repoHeader = "REPO"
    let eventHeader = "EVENT"

    let issuesWidth = max(issuesHeader.count, rows.map { String($0.repo.openIssues).count }.max() ?? 1)
    let pullsWidth = max(pullsHeader.count, rows.map { String($0.repo.openPulls).count }.max() ?? 1)
    let starsWidth = max(starsHeader.count, rows.map { String($0.repo.stars).count }.max() ?? 1)
    let activityWidth = max(activityHeader.count, rows.map(\.activityLabel.count).max() ?? 1)

    let header = [
        padRight(activityHeader, to: activityWidth),
        padLeft(issuesHeader, to: issuesWidth),
        padLeft(pullsHeader, to: pullsWidth),
        padLeft(starsHeader, to: starsWidth),
        repoHeader,
        eventHeader
    ].joined(separator: "  ")
    print(useColor ? Ansi.bold.wrap(header) : header)

    for row in rows {
        let issues = padLeft(String(row.repo.openIssues), to: issuesWidth)
        let pulls = padLeft(String(row.repo.openPulls), to: pullsWidth)
        let stars = padLeft(String(row.repo.stars), to: starsWidth)
        let activity = padRight(row.activityLabel, to: activityWidth)
        let repoName = row.repo.fullName
        let line = row.activityLine.singleLine

        let coloredActivity = useColor ? Ansi.gray.wrap(activity) : activity
        let coloredIssues = useColor ? (row.repo.openIssues > 0 ? Ansi.red.wrap(issues) : Ansi.gray.wrap(issues)) : issues
        let coloredPulls = useColor ? (row.repo.openPulls > 0 ? Ansi.magenta.wrap(pulls) : Ansi.gray.wrap(pulls)) : pulls
        let coloredStars = useColor ? (row.repo.stars > 0 ? Ansi.yellow.wrap(stars) : Ansi.gray.wrap(stars)) : stars
        let coloredRepo = useColor ? Ansi.cyan.wrap(repoName) : repoName
        let coloredLine = useColor && row.repo.error != nil ? Ansi.red.wrap(line) : line

        let output = [
            coloredActivity,
            coloredIssues,
            coloredPulls,
            coloredStars,
            coloredRepo,
            coloredLine
        ].joined(separator: "  ")
        print(output)

        if let error = row.repo.error {
            let message = "  ! \(error)"
            print(useColor ? Ansi.red.wrap(message) : message)
        }
    }
}

func renderJSON(_ rows: [RepoRow]) throws {
    let items = rows.map { row in
        RepoOutput(
            fullName: row.repo.fullName,
            owner: row.repo.owner,
            name: row.repo.name,
            openIssues: row.repo.openIssues,
            openPulls: row.repo.openPulls,
            stars: row.repo.stars,
            pushedAt: row.repo.pushedAt,
            activityDate: row.activityDate,
            activityTitle: row.repo.latestActivity?.title,
            activityActor: row.repo.latestActivity?.actor,
            activityUrl: row.repo.latestActivity?.url,
            error: row.repo.error
        )
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(items)
    if let json = String(data: data, encoding: .utf8) {
        print(json)
    }
}

func padLeft(_ value: String, to width: Int) -> String {
    let pad = max(0, width - value.count)
    return String(repeating: " ", count: pad) + value
}

func padRight(_ value: String, to width: Int) -> String {
    let pad = max(0, width - value.count)
    return value + String(repeating: " ", count: pad)
}
