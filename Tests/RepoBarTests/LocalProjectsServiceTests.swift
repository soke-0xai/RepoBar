import Foundation
@testable import RepoBarCore
import Testing

struct LocalProjectsServiceTests {
    @Test
    func pathFormatter_abbreviatesHome() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let input = URL(fileURLWithPath: home).appendingPathComponent("Projects").path
        #expect(PathFormatter.displayString(input).hasPrefix("~"))
        #expect(PathFormatter.expandTilde(PathFormatter.displayString(input)).hasPrefix(home))
    }

    @Test
    func localRepoStatus_detailsAndAutoSyncEligibility() {
        let status = LocalRepoStatus(
            path: URL(fileURLWithPath: "/tmp/repo"),
            name: "repo",
            fullName: "owner/repo",
            branch: "main",
            isClean: true,
            aheadCount: 0,
            behindCount: 2,
            syncState: .behind
        )
        #expect(status.displayName == "owner/repo")
        #expect(status.syncDetail.contains("Behind"))
        #expect(status.canAutoSync == true)

        let dirty = LocalRepoStatus(
            path: URL(fileURLWithPath: "/tmp/repo"),
            name: "repo",
            fullName: nil,
            branch: "main",
            isClean: false,
            aheadCount: 0,
            behindCount: 0,
            syncState: .dirty
        )
        #expect(dirty.canAutoSync == false)
        #expect(dirty.syncDetail == "Dirty")
    }

    @Test
    func snapshot_discoversRepos_and_parsesRemoteFormats() async throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let repoA = root.appendingPathComponent("repo-a", isDirectory: true)
        let nested = root.appendingPathComponent("group", isDirectory: true)
        let repoB = nested.appendingPathComponent("repo-b", isDirectory: true)
        try FileManager.default.createDirectory(at: repoA, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: repoB, withIntermediateDirectories: true)

        try initializeRepo(at: repoA, origin: "git@github.com:foo/repo-a.git")
        try initializeRepo(at: repoB, origin: "https://github.com/foo/repo-b.git")

        let snapshot = await LocalProjectsService().snapshot(
            rootPath: root.path,
            maxDepth: 2,
            autoSyncEnabled: false,
            concurrencyLimit: 1
        )

        #expect(snapshot.statuses.count == 2)
        let names = Set(snapshot.statuses.map(\.displayName))
        #expect(names.contains("foo/repo-a"))
        #expect(names.contains("foo/repo-b"))
    }

    @Test
    func snapshot_autoSync_fastForwardPullsBehindRepos() async throws {
        let base = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: base) }

        let scanRoot = base.appendingPathComponent("scan", isDirectory: true)
        let origin = base.appendingPathComponent("origin.git", isDirectory: true)
        try FileManager.default.createDirectory(at: scanRoot, withIntermediateDirectories: true)

        try runGit(["init", "--bare", origin.path], in: base)

        let repoA = scanRoot.appendingPathComponent("repo-a", isDirectory: true)
        let repoB = scanRoot.appendingPathComponent("repo-b", isDirectory: true)
        _ = try runGit(["clone", origin.path, repoA.lastPathComponent], in: scanRoot)

        try runGit(["switch", "-c", "main"], in: repoA)
        try runGit(["config", "user.email", "repobar-tests@example.com"], in: repoA)
        try runGit(["config", "user.name", "RepoBar Tests"], in: repoA)
        try writeFile(repoA.appendingPathComponent("README.md"), contents: "a\n")
        try runGit(["add", "."], in: repoA)
        try runGit(["commit", "-m", "init"], in: repoA)
        try runGit(["push", "-u", "origin", "main"], in: repoA)

        _ = try runGit(["clone", origin.path, repoB.lastPathComponent], in: scanRoot)
        try runGit(["switch", "main"], in: repoB)

        try writeFile(repoA.appendingPathComponent("README.md"), contents: "a\nb\n")
        try runGit(["add", "."], in: repoA)
        try runGit(["commit", "-m", "next"], in: repoA)
        try runGit(["push"], in: repoA)

        let snapshot = await LocalProjectsService().snapshot(
            rootPath: scanRoot.path,
            maxDepth: 1,
            autoSyncEnabled: true,
            concurrencyLimit: 1
        )

        #expect(snapshot.statuses.count == 2)
        #expect(snapshot.syncedStatuses.count == 1)

        let repoBStatus = snapshot.statuses.first(where: { $0.name == "repo-b" })
        #expect(repoBStatus != nil)
        #expect(repoBStatus?.syncState == .synced)
    }
}

private func makeTempDirectory() throws -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("repobar-localprojects-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func writeFile(_ url: URL, contents: String) throws {
    try Data(contents.utf8).write(to: url, options: .atomic)
}

@discardableResult
private func runGit(_ arguments: [String], in directory: URL) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.currentDirectoryURL = directory
    process.arguments = arguments

    let out = Pipe()
    let err = Pipe()
    process.standardOutput = out
    process.standardError = err

    try process.run()
    process.waitUntilExit()

    let output = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let error = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    if process.terminationStatus != 0 {
        throw GitTestError.commandFailed(arguments: arguments, output: output, error: error)
    }
    return output
}

private func initializeRepo(at url: URL, origin: String) throws {
    try runGit(["init"], in: url)
    try runGit(["switch", "-c", "main"], in: url)
    try runGit(["config", "user.email", "repobar-tests@example.com"], in: url)
    try runGit(["config", "user.name", "RepoBar Tests"], in: url)
    try runGit(["remote", "add", "origin", origin], in: url)
    try writeFile(url.appendingPathComponent("README.md"), contents: "test\n")
    try runGit(["add", "."], in: url)
    try runGit(["commit", "-m", "init"], in: url)
}

private enum GitTestError: Error {
    case commandFailed(arguments: [String], output: String, error: String)
}
