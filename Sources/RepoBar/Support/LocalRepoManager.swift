import Foundation
import RepoBarCore

actor LocalRepoManager {
    private let notifier = LocalSyncNotifier.shared

    func snapshot(settings: LocalProjectsSettings) async -> LocalRepoIndex {
        guard let rootPath = settings.rootPath,
              rootPath.isEmpty == false
        else {
            return .empty
        }
        let snapshot = await LocalProjectsService().snapshot(
            rootPath: rootPath,
            maxDepth: 2,
            autoSyncEnabled: settings.autoSyncEnabled
        )

        for status in snapshot.syncedStatuses {
            await self.notifier.notifySync(for: status)
        }

        return LocalRepoIndex(statuses: snapshot.statuses)
    }
}
