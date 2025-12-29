import Foundation
import RepoBarCore
import UserNotifications

actor LocalSyncNotifier {
    static let shared = LocalSyncNotifier()
    private let center = UNUserNotificationCenter.current()

    func notifySync(for status: LocalRepoStatus) async {
        let authorizationStatus = await self.authorizationStatus()
        let authorized: Bool = switch authorizationStatus {
        case .authorized, .provisional:
            true
        case .notDetermined:
            await self.requestAuthorization()
        default:
            false
        }

        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "RepoBar"
        content.body = "Synced \(status.displayName) (\(status.branch))"
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        _ = try? await self.center.add(request)
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            self.center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
