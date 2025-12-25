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
            return max(left, right)
        case let (left?, nil):
            return left
        case let (nil, right?):
            return right
        default:
            return nil
        }
    }

    func activityLine(fallbackToPush: Bool) -> String? {
        if let line = self.activityLine { return line }
        if fallbackToPush, self.pushedAt != nil { return "push" }
        return nil
    }
}
