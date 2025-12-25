import Foundation

public extension ActivityEvent {
    var line: String { "\(self.actor): \(self.title)" }
}

public extension Repository {
    var activityLine: String? { self.latestActivity?.line }
    var activityURL: URL? { self.latestActivity?.url }

    /// Returns the most recent activity date between latest activity and last push.
    var activityDate: Date? {
        switch (self.latestActivity?.date, self.pushedAt) {
        case let (left?, right?):
            max(left, right)
        case let (left?, nil):
            left
        case let (nil, right?):
            right
        default:
            nil
        }
    }

    func activityLine(fallbackToPush: Bool) -> String? {
        if let line = self.activityLine { return line }
        if fallbackToPush, self.pushedAt != nil { return "push" }
        return nil
    }
}
