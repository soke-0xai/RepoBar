import Darwin
import Foundation
import RepoBarCore

@main
struct RepoBarCLI {
    static func main() async {
        do {
            let options = try CLIOptions.parse(CommandLine.arguments.dropFirst())
            if options.showHelp {
                Self.printHelp()
                return
            }
            try await Self.run(options: options)
        } catch {
            let message = (error as? CLIError)?.message ?? error.userFacingMessage
            Self.printError(message)
            exit(1)
        }
    }
}

private extension RepoBarCLI {
    static func run(options: CLIOptions) async throws {
        switch options.command {
        case .login:
            try await Self.login(options.login)
        case .logout:
            Self.logout()
        case .repos:
            try await Self.list(options: options)
        case .status:
            try Self.status(options: options)
        }
    }

    static func list(options: CLIOptions) async throws {
        if options.jsonOutput == false, options.colorOutput {
            print("RepoBar CLI")
        }

        guard (try? TokenStore.shared.load()) != nil else {
            throw CLIError.notAuthenticated
        }

        let settings = SettingsStore().load()
        let host = settings.enterpriseHost ?? settings.githubHost
        let apiHost: URL = if let enterprise = settings.enterpriseHost {
            enterprise.appending(path: "/api/v3")
        } else {
            RepoBarAuthDefaults.apiHost
        }

        let client = GitHubClient()
        await client.setAPIHost(apiHost)
        await client.setTokenProvider { @Sendable () async throws -> OAuthTokens? in
            try await OAuthTokenRefresher().refreshIfNeeded(host: host)
        }

        let repos = try await client.activityRepositories(limit: options.limit)
        let rows = Self.prepareRows(repos: repos)
        let sorted = Self.sortRows(rows)

        if options.jsonOutput {
            try Self.renderJSON(sorted)
        } else {
            Self.renderTable(sorted, useColor: options.colorOutput)
        }
    }

    @MainActor
    static func login(_ options: LoginOptions) async throws {
        let store = SettingsStore()
        var settings = store.load()
        let rawHost = options.host ?? settings.enterpriseHost ?? settings.githubHost
        let normalizedHost = try OAuthLoginFlow.normalizeHost(rawHost)

        let flow = OAuthLoginFlow(tokenStore: .shared) { url in
            try Self.openURL(url)
        }
        _ = try await flow.login(
            clientID: options.clientID ?? RepoBarAuthDefaults.clientID,
            clientSecret: options.clientSecret ?? RepoBarAuthDefaults.clientSecret,
            host: normalizedHost,
            loopbackPort: options.loopbackPort ?? settings.loopbackPort
        )

        settings.loopbackPort = options.loopbackPort ?? settings.loopbackPort
        settings.githubHost = RepoBarAuthDefaults.githubHost
        if normalizedHost.host?.lowercased() == "github.com" {
            settings.enterpriseHost = nil
        } else {
            settings.enterpriseHost = normalizedHost
        }
        store.save(settings)

        print("Login succeeded; tokens stored.")
    }

    static func logout() {
        TokenStore.shared.clear()
        print("Logged out.")
    }

    static func status(options: CLIOptions) throws {
        let tokens = try TokenStore.shared.load()
        guard let tokens else {
            if options.jsonOutput {
                let output = StatusOutput(
                    authenticated: false,
                    host: nil,
                    expiresAt: nil,
                    expiresIn: nil,
                    expired: nil
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(output)
                if let json = String(data: data, encoding: .utf8) { print(json) }
            } else {
                print("Logged out.")
            }
            return
        }

        let settings = SettingsStore().load()
        let host = (settings.enterpriseHost ?? settings.githubHost).absoluteString
        let now = Date()
        let expiresAt = tokens.expiresAt
        let expired = expiresAt.map { $0 <= now }
        let expiresIn = expiresAt.map { RelativeFormatter.string(from: $0, relativeTo: now) }

        if options.jsonOutput {
            let output = StatusOutput(
                authenticated: true,
                host: host,
                expiresAt: expiresAt,
                expiresIn: expiresIn,
                expired: expired
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(output)
            if let json = String(data: data, encoding: .utf8) { print(json) }
        } else {
            print("Logged in.")
            print("Host: \(host)")
            if let expiresAt {
                let state = expired == true ? "expired" : "expires"
                let label = expiresIn ?? expiresAt.formatted()
                print("\(state.capitalized): \(label)")
            } else {
                print("Expires: unknown")
            }
        }
    }

    static func prepareRows(repos: [Repository], now: Date = Date()) -> [RepoRow] {
        repos.map { repo in
            let activityDate = repo.activityDate
            let activityLabel = activityDate.map { RelativeFormatter.string(from: $0, relativeTo: now) } ?? "-"
            let activityLine = repo.activityLine(fallbackToPush: true) ?? "-"
            return RepoRow(repo: repo, activityDate: activityDate, activityLabel: activityLabel, activityLine: activityLine)
        }
    }

    static func sortRows(_ rows: [RepoRow]) -> [RepoRow] {
        rows.sorted { lhs, rhs in
            let leftDate = lhs.activityDate ?? .distantPast
            let rightDate = rhs.activityDate ?? .distantPast
            if leftDate != rightDate { return leftDate > rightDate }
            if lhs.repo.openIssues != rhs.repo.openIssues { return lhs.repo.openIssues > rhs.repo.openIssues }
            if lhs.repo.openPulls != rhs.repo.openPulls { return lhs.repo.openPulls > rhs.repo.openPulls }
            if lhs.repo.stars != rhs.repo.stars { return lhs.repo.stars > rhs.repo.stars }
            return lhs.repo.fullName.localizedCaseInsensitiveCompare(rhs.repo.fullName) == .orderedAscending
        }
    }

}

private extension RepoBarCLI {
    static func renderTable(_ rows: [RepoRow], useColor: Bool) {
        let issuesWidth = max(3, rows.map { String($0.repo.openIssues).count }.max() ?? 1)
        let pullsWidth = max(2, rows.map { String($0.repo.openPulls).count }.max() ?? 1)
        let starsWidth = max(4, rows.map { String($0.repo.stars).count }.max() ?? 1)
        let activityWidth = max(3, rows.map(\.activityLabel.count).max() ?? 1)

        let header = [
            padRight("ACT", to: activityWidth),
            padLeft("ISS", to: issuesWidth),
            padLeft("PR", to: pullsWidth),
            padLeft("STAR", to: starsWidth),
            "REPO",
            "ACTIVITY"
        ].joined(separator: "  ")
        print(useColor ? Ansi.bold.wrap(header) : header)

        for row in rows {
            let issues = padLeft(String(row.repo.openIssues), to: issuesWidth)
            let pulls = padLeft(String(row.repo.openPulls), to: pullsWidth)
            let stars = padLeft(String(row.repo.stars), to: starsWidth)
            let activity = padRight(row.activityLabel, to: activityWidth)
            let repoName = row.repo.fullName
            let line = row.activityLine

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

    static func renderJSON(_ rows: [RepoRow]) throws {
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
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }
    }
}

private struct RepoRow {
    let repo: Repository
    let activityDate: Date?
    let activityLabel: String
    let activityLine: String
}

private struct RepoOutput: Codable {
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

private struct StatusOutput: Codable {
    let authenticated: Bool
    let host: String?
    let expiresAt: Date?
    let expiresIn: String?
    let expired: Bool?
}

private struct CLIOptions {
    let command: CLICommand
    let limit: Int?
    let jsonOutput: Bool
    let colorOutput: Bool
    let showHelp: Bool
    let login: LoginOptions

    static func parse(_ args: ArraySlice<String>) throws -> CLIOptions {
        var command: CLICommand = .repos
        var limit: Int?
        var jsonOutput = false
        var showHelp = false
        var login = LoginOptions()

        var index = args.startIndex
        if index < args.endIndex, args[index].hasPrefix("-") == false {
            let raw = args[index]
            command = try CLICommand.parse(raw)
            index = args.index(after: index)
        }

        while index < args.endIndex {
            let arg = args[index]
            switch arg {
            case "--help", "-h":
                showHelp = true
            case "--json":
                jsonOutput = true
            case let value where value.hasPrefix("--limit="):
                let raw = String(value.dropFirst("--limit=".count))
                limit = try parseLimit(raw)
            case "--limit":
                let next = args.index(after: index)
                guard next < args.endIndex else { throw CLIError.missingValue(flag: "--limit") }
                limit = try parseLimit(args[next])
                index = next
            case let value where value.hasPrefix("--host="):
                let raw = String(value.dropFirst("--host=".count))
                login.host = try parseHost(raw)
            case "--host":
                let next = args.index(after: index)
                guard next < args.endIndex else { throw CLIError.missingValue(flag: "--host") }
                login.host = try parseHost(args[next])
                index = next
            case let value where value.hasPrefix("--client-id="):
                let raw = String(value.dropFirst("--client-id=".count))
                login.clientID = raw
            case "--client-id":
                let next = args.index(after: index)
                guard next < args.endIndex else { throw CLIError.missingValue(flag: "--client-id") }
                login.clientID = args[next]
                index = next
            case let value where value.hasPrefix("--client-secret="):
                let raw = String(value.dropFirst("--client-secret=".count))
                login.clientSecret = raw
            case "--client-secret":
                let next = args.index(after: index)
                guard next < args.endIndex else { throw CLIError.missingValue(flag: "--client-secret") }
                login.clientSecret = args[next]
                index = next
            case let value where value.hasPrefix("--loopback-port="):
                let raw = String(value.dropFirst("--loopback-port=".count))
                login.loopbackPort = try parsePort(raw)
            case "--loopback-port":
                let next = args.index(after: index)
                guard next < args.endIndex else { throw CLIError.missingValue(flag: "--loopback-port") }
                login.loopbackPort = try parsePort(args[next])
                index = next
            default:
                throw CLIError.unknownArgument(arg)
            }
            index = args.index(after: index)
        }

        let colorOutput = jsonOutput ? false : Ansi.supportsColor
        return CLIOptions(
            command: command,
            limit: limit,
            jsonOutput: jsonOutput,
            colorOutput: colorOutput,
            showHelp: showHelp,
            login: login
        )
    }
}

private enum CLICommand {
    case repos
    case login
    case logout
    case status

    static func parse(_ raw: String) throws -> CLICommand {
        switch raw {
        case "repos", "list": return .repos
        case "login": return .login
        case "logout": return .logout
        case "status": return .status
        default: throw CLIError.unknownCommand(raw)
        }
    }
}

private struct LoginOptions {
    var host: URL?
    var clientID: String?
    var clientSecret: String?
    var loopbackPort: Int?
}

private enum CLIError: Error {
    case missingValue(flag: String)
    case invalidValue(flag: String, value: String)
    case unknownArgument(String)
    case unknownCommand(String)
    case notAuthenticated
    case openFailed
    case invalidHost(String)

    var message: String {
        switch self {
        case let .missingValue(flag):
            return "Missing value for \(flag)."
        case let .invalidValue(flag, value):
            return "Invalid value for \(flag): \(value)"
        case let .unknownArgument(arg):
            return "Unknown argument: \(arg)"
        case let .unknownCommand(command):
            return "Unknown command: \(command)"
        case .notAuthenticated:
            return "No stored login. Run `repobarcli login` first."
        case .openFailed:
            return "Failed to open the browser."
        case let .invalidHost(raw):
            return "Invalid host: \(raw)"
        }
    }
}

private func parseLimit(_ raw: String) throws -> Int {
    guard let value = Int(raw), value > 0 else {
        throw CLIError.invalidValue(flag: "--limit", value: raw)
    }
    return value
}

private func parsePort(_ raw: String) throws -> Int {
    guard let value = Int(raw), value > 0, value < 65536 else {
        throw CLIError.invalidValue(flag: "--loopback-port", value: raw)
    }
    return value
}

private func parseHost(_ raw: String) throws -> URL {
    guard var components = URLComponents(string: raw) else { throw CLIError.invalidHost(raw) }
    if components.scheme == nil { components.scheme = "https" }
    guard let url = components.url else { throw CLIError.invalidHost(raw) }
    return url
}

private func padLeft(_ value: String, to width: Int) -> String {
    let pad = max(0, width - value.count)
    return String(repeating: " ", count: pad) + value
}

private func padRight(_ value: String, to width: Int) -> String {
    let pad = max(0, width - value.count)
    return value + String(repeating: " ", count: pad)
}

private enum Ansi {
    static let reset = "\u{001B}[0m"
    static let bold = Code("\u{001B}[1m")
    static let red = Code("\u{001B}[31m")
    static let yellow = Code("\u{001B}[33m")
    static let magenta = Code("\u{001B}[35m")
    static let cyan = Code("\u{001B}[36m")
    static let gray = Code("\u{001B}[90m")

    static var supportsColor: Bool {
        guard isatty(fileno(stdout)) != 0 else { return false }
        return ProcessInfo.processInfo.environment["NO_COLOR"] == nil
    }

    struct Code {
        let value: String

        init(_ value: String) {
            self.value = value
        }

        func wrap(_ text: String) -> String {
            "\(self.value)\(text)\(Ansi.reset)"
        }
    }
}

private extension RepoBarCLI {
    static func printHelp() {
        let text = """
        repobarcli - list repositories by activity, issues, PRs, stars

        Usage:
          repobarcli [repos] [--limit N] [--json]
          repobarcli login [--host URL] [--client-id ID] [--client-secret SECRET] [--loopback-port PORT]
          repobarcli logout
          repobarcli status [--json]

        Options:
          --limit N   Max repositories to fetch (default: all accessible)
          --json      Output JSON instead of colored table
          -h, --help  Show help
        """
        print(text)
    }

    static func printError(_ message: String) {
        if Ansi.supportsColor {
            print(Ansi.red.wrap("Error: \(message)"))
        } else {
            print("Error: \(message)")
        }
    }

    static func openURL(_ url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.absoluteString]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CLIError.openFailed }
    }
}
