import AppKit
import RepoBarCore
import SwiftUI

extension StatusBarMenuBuilder {
    func contributionSubmenu(username: String, displayName: String) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self.target

        if let profileURL = self.profileURL(for: username) {
            menu.addItem(self.actionItem(
                title: "Open \(displayName) in GitHub",
                action: #selector(self.target.openURLItem),
                represented: profileURL,
                systemImage: "person.crop.circle"
            ))
        }

        if let error = self.appState.session.globalActivityError {
            menu.addItem(self.infoMessageItem(error))
            return menu
        }

        let events = Array(self.appState.session.globalActivityEvents.prefix(MenuStyle.globalActivityLimit))
        if events.isEmpty {
            let title = self.appState.session.hasLoadedRepositories ? "No recent activity" : "Loading…"
            menu.addItem(self.infoItem(title))
            return menu
        }

        events.forEach { menu.addItem(self.activityMenuItem(for: $0)) }
        return menu
    }

    func activityMenuItem(for event: ActivityEvent) -> NSMenuItem {
        let view = ActivityMenuItemView(event: event, symbolName: self.activitySymbolName(for: event)) { [weak target] in
            target?.open(url: event.url)
        }
        return self.viewItem(for: view, enabled: true, highlightable: true)
    }

    func activitySymbolName(for event: ActivityEvent) -> String {
        guard let type = event.eventTypeEnum else { return "clock" }
        switch type {
        case .pullRequest: return "arrow.triangle.branch"
        case .pullRequestReview: return "checkmark.bubble"
        case .pullRequestReviewComment: return "text.bubble"
        case .pullRequestReviewThread: return "text.bubble"
        case .issueComment: return "text.bubble"
        case .issues: return "exclamationmark.circle"
        case .push: return "arrow.up.circle"
        case .release: return "tag"
        case .watch: return "star"
        case .fork: return "doc.on.doc"
        case .create: return "plus"
        case .delete: return "trash"
        case .member: return "person.badge.plus"
        case .public: return "globe"
        case .gollum: return "book"
        case .commitComment: return "text.bubble"
        case .discussion: return "bubble.left.and.bubble.right"
        case .sponsorship: return "heart"
        }
    }

    private func profileURL(for username: String) -> URL? {
        guard username.isEmpty == false else { return nil }
        var host = self.appState.session.settings.githubHost
        host.appendPathComponent(username)
        return host
    }
}
