import Foundation
import RepoBarCore

actor LocalRepoManager {
    private let fileManager = FileManager.default
    private let notifier = LocalSyncNotifier.shared
    private let git = GitRunner()

    func snapshot(settings: LocalProjectsSettings) async -> LocalRepoIndex {
        guard let rootPath = settings.rootPath,
              rootPath.isEmpty == false
        else {
            return .empty
        }

        let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard self.fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            return .empty
        }
        let repos = self.findGitRepos(in: rootURL, maxDepth: 2)
        guard repos.isEmpty == false else { return .empty }

        var statuses: [LocalRepoStatus] = []
        for repoURL in repos {
            guard var status = self.loadStatus(at: repoURL) else { continue }
            if settings.autoSyncEnabled, status.canAutoSync {
                if self.pullFastForward(at: repoURL) {
                    if let refreshed = self.loadStatus(at: repoURL) {
                        status = refreshed
                    }
                    await self.notifier.notifySync(for: status)
                }
            }
            statuses.append(status)
        }

        return LocalRepoIndex(statuses: statuses)
    }

    private func findGitRepos(in root: URL, maxDepth: Int) -> [URL] {
        var results: [URL] = []
        func scan(_ url: URL, depth: Int) {
            if self.isGitRepo(url) {
                results.append(url)
                return
            }
            guard depth < maxDepth else { return }
            let children = (try? self.fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )) ?? []
            for child in children {
                var isDirectory: ObjCBool = false
                guard self.fileManager.fileExists(atPath: child.path, isDirectory: &isDirectory),
                      isDirectory.boolValue
                else { continue }
                if child.lastPathComponent.hasPrefix(".") { continue }
                scan(child, depth: depth + 1)
            }
        }
        scan(root, depth: 0)
        return results
    }

    private func isGitRepo(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let gitURL = url.appendingPathComponent(".git")
        return self.fileManager.fileExists(atPath: gitURL.path, isDirectory: &isDirectory)
    }

    private func loadStatus(at repoURL: URL) -> LocalRepoStatus? {
        let branch = self.currentBranch(at: repoURL)
        let isClean = self.isClean(at: repoURL)
        let (ahead, behind) = self.aheadBehind(at: repoURL)
        let syncState = LocalSyncState.resolve(isClean: isClean, ahead: ahead, behind: behind)
        let remote = self.remoteInfo(at: repoURL)
        let repoName = remote?.name ?? repoURL.lastPathComponent
        let fullName = remote?.fullName
        return LocalRepoStatus(
            path: repoURL,
            name: repoName,
            fullName: fullName,
            branch: branch,
            isClean: isClean,
            aheadCount: ahead,
            behindCount: behind,
            syncState: syncState
        )
    }

    private func currentBranch(at repoURL: URL) -> String {
        guard let raw = try? self.git.run(["rev-parse", "--abbrev-ref", "HEAD"], in: repoURL) else {
            return "unknown"
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == "HEAD" ? "detached" : trimmed
    }

    private func isClean(at repoURL: URL) -> Bool {
        guard let output = try? self.git.run(["status", "--porcelain"], in: repoURL) else {
            return false
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func aheadBehind(at repoURL: URL) -> (ahead: Int?, behind: Int?) {
        guard let output = try? self.git.run(["rev-list", "--left-right", "--count", "@{u}...HEAD"], in: repoURL) else {
            return (nil, nil)
        }
        let parts = output.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        guard parts.count >= 2,
              let behind = Int(parts[0]),
              let ahead = Int(parts[1])
        else { return (nil, nil) }
        return (ahead, behind)
    }

    private func pullFastForward(at repoURL: URL) -> Bool {
        do {
            _ = try self.git.run(["pull", "--ff-only"], in: repoURL)
            return true
        } catch {
            return false
        }
    }

    private func remoteInfo(at repoURL: URL) -> GitRemote? {
        guard let raw = try? self.git.run(["remote", "get-url", "origin"], in: repoURL) else {
            return nil
        }
        return GitRemote.parse(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

private struct GitRunner {
    func run(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw GitRunnerError.commandFailed(output: output, error: error)
        }
        return output
    }
}

private enum GitRunnerError: Error {
    case commandFailed(output: String, error: String)
}

private struct GitRemote {
    let host: String
    let owner: String
    let name: String

    var fullName: String { "\(self.owner)/\(self.name)" }

    static func parse(_ value: String) -> GitRemote? {
        if value.contains("://") {
            return self.parseURL(value)
        }
        return self.parseScp(value)
    }

    private static func parseURL(_ value: String) -> GitRemote? {
        guard let url = URL(string: value),
              let host = url.host
        else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        let owner = parts[parts.count - 2]
        let name = self.stripGitSuffix(parts.last ?? "")
        return GitRemote(host: host, owner: owner, name: name)
    }

    private static func parseScp(_ value: String) -> GitRemote? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let hostPart = parts[0].split(separator: "@").last.map(String.init) ?? parts[0]
        let path = parts[1]
        let pathParts = path.split(separator: "/").map(String.init)
        guard pathParts.count >= 2 else { return nil }
        let owner = pathParts[pathParts.count - 2]
        let name = self.stripGitSuffix(pathParts.last ?? "")
        return GitRemote(host: hostPart, owner: owner, name: name)
    }

    private static func stripGitSuffix(_ value: String) -> String {
        value.hasSuffix(".git") ? String(value.dropLast(4)) : value
    }
}
