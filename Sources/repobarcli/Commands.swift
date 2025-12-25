import Commander
import Foundation
import RepoBarCore

@MainActor
struct RepoBarRoot: ParsableCommand {
    nonisolated static let commandName = "repobarcli"

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: commandName,
            abstract: "RepoBar CLI",
            subcommands: [
                ReposCommand.self,
                LoginCommand.self,
                LogoutCommand.self,
                StatusCommand.self
            ],
            defaultSubcommand: ReposCommand.self
        )
    }
}

@MainActor
struct ReposCommand: CommanderRunnableCommand {
    nonisolated static let commandName = "repos"

    @Option(name: .customLong("limit"), help: "Max repositories to fetch (default: all accessible)")
    var limit: Int?

    @Option(name: .customLong("sort"), help: "Sort by activity, issues, prs, stars, repo, or event")
    var sort: SortKey = .activity

    @OptionGroup
    var output: OutputOptions

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: commandName,
            abstract: "List repositories by activity, issues, PRs, and stars"
        )
    }

    mutating func bind(_ values: ParsedValues) throws {
        self.output.bind(values)
        self.limit = try values.decodeOption("limit")
        self.sort = try values.decodeOption("sort") ?? .activity
    }

    mutating func run() async throws {
        if let limit, limit <= 0 {
            throw ValidationError("--limit must be greater than 0")
        }

        if self.output.jsonOutput == false, self.output.useColor {
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

        let repos = try await client.activityRepositories(limit: limit)
        let rows = prepareRows(repos: repos)
        let sorted = sortRows(rows, sortKey: sort)

        if self.output.jsonOutput {
            try renderJSON(sorted)
        } else {
            renderTable(sorted, useColor: self.output.useColor)
        }
    }
}

@MainActor
struct LoginCommand: CommanderRunnableCommand {
    nonisolated static let commandName = "login"

    @Option(name: .customLong("host"), help: "GitHub host URL (GitHub.com or Enterprise base URL)")
    var host: String?

    @Option(name: .customLong("client-id"), help: "GitHub App OAuth client ID")
    var clientID: String?

    @Option(name: .customLong("client-secret"), help: "GitHub App OAuth client secret")
    var clientSecret: String?

    @Option(name: .customLong("loopback-port"), help: "Loopback port for OAuth callback")
    var loopbackPort: Int?

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: commandName,
            abstract: "Sign in via browser-based OAuth"
        )
    }

    mutating func bind(_ values: ParsedValues) throws {
        self.host = try values.decodeOption("host")
        self.clientID = try values.decodeOption("clientID")
        self.clientSecret = try values.decodeOption("clientSecret")
        self.loopbackPort = try values.decodeOption("loopbackPort")
    }

    mutating func run() async throws {
        if let loopbackPort, loopbackPort <= 0 || loopbackPort >= 65536 {
            throw ValidationError("--loopback-port must be between 1 and 65535")
        }

        let store = SettingsStore()
        var settings = store.load()
        let rawHost: URL = if let host {
            try parseHost(host)
        } else {
            settings.enterpriseHost ?? settings.githubHost
        }
        let normalizedHost = try OAuthLoginFlow.normalizeHost(rawHost)

        let flow = OAuthLoginFlow(tokenStore: .shared) { url in
            try openURL(url)
        }
        _ = try await flow.login(
            clientID: self.clientID ?? RepoBarAuthDefaults.clientID,
            clientSecret: self.clientSecret ?? RepoBarAuthDefaults.clientSecret,
            host: normalizedHost,
            loopbackPort: loopbackPort ?? settings.loopbackPort
        )

        settings.loopbackPort = loopbackPort ?? settings.loopbackPort
        settings.githubHost = RepoBarAuthDefaults.githubHost
        if normalizedHost.host?.lowercased() == "github.com" {
            settings.enterpriseHost = nil
        } else {
            settings.enterpriseHost = normalizedHost
        }
        store.save(settings)

        print("Login succeeded; tokens stored.")
    }
}

@MainActor
struct LogoutCommand: CommanderRunnableCommand {
    nonisolated static let commandName = "logout"

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: commandName,
            abstract: "Clear stored credentials"
        )
    }

    mutating func bind(_: ParsedValues) throws {}

    mutating func run() async throws {
        TokenStore.shared.clear()
        print("Logged out.")
    }
}

@MainActor
struct StatusCommand: CommanderRunnableCommand {
    nonisolated static let commandName = "status"

    @OptionGroup
    var output: OutputOptions

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: commandName,
            abstract: "Show login state"
        )
    }

    mutating func bind(_ values: ParsedValues) throws {
        self.output.bind(values)
    }

    mutating func run() async throws {
        let tokens = try TokenStore.shared.load()
        guard let tokens else {
            if self.output.jsonOutput {
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

        if self.output.jsonOutput {
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
}
