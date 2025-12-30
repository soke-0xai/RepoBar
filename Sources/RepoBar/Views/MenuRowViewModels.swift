import Foundation
import RepoBarCore

struct LocalRefMenuRowViewModel: Sendable {
    enum Kind: Sendable {
        case branch
        case worktree
    }

    let kind: Kind
    let title: String
    let detail: String?
    let isCurrent: Bool
    let isDetached: Bool
    let upstream: String?
    let aheadCount: Int?
    let behindCount: Int?
    let lastCommitDate: Date?
    let lastCommitAuthor: String?
    let dirtySummary: String?

    var usesMiddleTruncation: Bool {
        self.kind == .worktree
    }

    var syncLabel: String {
        let ahead = self.aheadCount ?? 0
        let behind = self.behindCount ?? 0
        guard ahead > 0 || behind > 0 else { return "" }
        var parts: [String] = []
        if ahead > 0 { parts.append("↑\(ahead)") }
        if behind > 0 { parts.append("↓\(behind)") }
        return parts.joined(separator: " ")
    }

    var commitLine: String? {
        guard let lastCommitDate, let lastCommitAuthor else { return nil }
        let when = RelativeFormatter.string(from: lastCommitDate, relativeTo: Date())
        return "\(lastCommitAuthor) · \(when)"
    }
}

struct RecentRowMetadata: Sendable {
    let title: String
    let author: String?
    let updatedAt: Date?
    let url: URL?
}

protocol RecentRowViewModel: Sendable {
    var metadata: RecentRowMetadata { get }
}

struct IssueMenuRowViewModel: RecentRowViewModel {
    let summary: RepoIssueSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.title, author: self.summary.authorLogin, updatedAt: self.summary.updatedAt, url: self.summary.url)
    }

    var title: String { self.summary.title }
    var number: Int { self.summary.number }
    var authorLogin: String? { self.summary.authorLogin }
    var updatedAt: Date { self.summary.updatedAt }
    var commentCount: Int { self.summary.commentCount }
    var labels: [RepoIssueLabel] { self.summary.labels }
    var authorAvatarURL: URL? { self.summary.authorAvatarURL }
}

struct PullRequestMenuRowViewModel: RecentRowViewModel {
    let summary: RepoPullRequestSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.title, author: self.summary.authorLogin, updatedAt: self.summary.updatedAt, url: self.summary.url)
    }

    var title: String { self.summary.title }
    var number: Int { self.summary.number }
    var authorLogin: String? { self.summary.authorLogin }
    var updatedAt: Date { self.summary.updatedAt }
    var commentCount: Int { self.summary.commentCount }
    var reviewCommentCount: Int { self.summary.reviewCommentCount }
    var isDraft: Bool { self.summary.isDraft }
    var labels: [RepoIssueLabel] { self.summary.labels }
    var headRefName: String? { self.summary.headRefName }
    var baseRefName: String? { self.summary.baseRefName }
    var authorAvatarURL: URL? { self.summary.authorAvatarURL }
}

struct ReleaseMenuRowViewModel: RecentRowViewModel {
    let summary: RepoReleaseSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.name, author: self.summary.authorLogin, updatedAt: self.summary.publishedAt, url: self.summary.url)
    }

    var name: String { self.summary.name }
    var tag: String { self.summary.tag }
    var authorLogin: String? { self.summary.authorLogin }
    var publishedAt: Date { self.summary.publishedAt }
    var isPrerelease: Bool { self.summary.isPrerelease }
    var assetCount: Int { self.summary.assetCount }
    var downloadCount: Int { self.summary.downloadCount }
    var authorAvatarURL: URL? { self.summary.authorAvatarURL }
    var assets: [RepoReleaseAssetSummary] { self.summary.assets }
    var url: URL { self.summary.url }
}

struct WorkflowRunMenuRowViewModel: RecentRowViewModel {
    let summary: RepoWorkflowRunSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.name, author: self.summary.actorLogin, updatedAt: self.summary.updatedAt, url: self.summary.url)
    }

    var name: String { self.summary.name }
    var branch: String? { self.summary.branch }
    var event: String? { self.summary.event }
    var actorLogin: String? { self.summary.actorLogin }
    var updatedAt: Date { self.summary.updatedAt }
    var status: CIStatus { self.summary.status }
    var url: URL { self.summary.url }
}

struct DiscussionMenuRowViewModel: RecentRowViewModel {
    let summary: RepoDiscussionSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.title, author: self.summary.authorLogin, updatedAt: self.summary.updatedAt, url: self.summary.url)
    }

    var title: String { self.summary.title }
    var categoryName: String? { self.summary.categoryName }
    var authorLogin: String? { self.summary.authorLogin }
    var updatedAt: Date { self.summary.updatedAt }
    var commentCount: Int { self.summary.commentCount }
    var authorAvatarURL: URL? { self.summary.authorAvatarURL }
    var url: URL { self.summary.url }
}

struct CommitMenuRowViewModel: RecentRowViewModel {
    let summary: RepoCommitSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.message, author: self.authorLabel, updatedAt: self.summary.authoredAt, url: self.summary.url)
    }

    var message: String { self.summary.message }
    var sha: String { self.summary.sha }
    var authorLogin: String? { self.summary.authorLogin }
    var authorName: String? { self.summary.authorName }
    var authoredAt: Date { self.summary.authoredAt }
    var authorAvatarURL: URL? { self.summary.authorAvatarURL }
    var repoFullName: String? { self.summary.repoFullName }
    var url: URL { self.summary.url }

    var authorLabel: String? {
        self.summary.authorLogin ?? self.summary.authorName
    }
}

struct TagMenuRowViewModel: RecentRowViewModel {
    let summary: RepoTagSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.name, author: nil, updatedAt: nil, url: nil)
    }

    var name: String { self.summary.name }
    var commitSHA: String { self.summary.commitSHA }
}

struct BranchMenuRowViewModel: RecentRowViewModel {
    let summary: RepoBranchSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.name, author: nil, updatedAt: nil, url: nil)
    }

    var name: String { self.summary.name }
    var commitSHA: String { self.summary.commitSHA }
    var isProtected: Bool { self.summary.isProtected }
}

struct ContributorMenuRowViewModel: RecentRowViewModel {
    let summary: RepoContributorSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.login, author: nil, updatedAt: nil, url: self.summary.url)
    }

    var login: String { self.summary.login }
    var contributions: Int { self.summary.contributions }
    var avatarURL: URL? { self.summary.avatarURL }
    var url: URL? { self.summary.url }
}

struct ReleaseAssetMenuRowViewModel: RecentRowViewModel {
    let summary: RepoReleaseAssetSummary

    var metadata: RecentRowMetadata {
        RecentRowMetadata(title: self.summary.name, author: nil, updatedAt: nil, url: self.summary.url)
    }

    var name: String { self.summary.name }
    var sizeBytes: Int? { self.summary.sizeBytes }
    var downloadCount: Int { self.summary.downloadCount }
    var url: URL { self.summary.url }
}
