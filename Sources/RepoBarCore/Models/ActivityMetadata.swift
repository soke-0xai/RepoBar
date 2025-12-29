import Foundation

public struct ActivityMetadata: Codable, Equatable, Sendable {
    public let actor: String
    public let action: String?
    public let target: String?
    public let url: URL?

    public init(actor: String, action: String?, target: String?, url: URL?) {
        self.actor = actor
        self.action = action
        self.target = target
        self.url = url
    }

    public var label: String {
        switch (self.action, self.target) {
        case let (action?, target?) where target.hasPrefix("→"):
            return "\(action) \(target)"
        case let (action?, target?) where target.hasPrefix("#"):
            return "\(action) \(target)"
        case let (action?, target?):
            return "\(action): \(target)"
        case let (action?, nil):
            return action
        case let (nil, target?):
            return target
        default:
            return ""
        }
    }

    public var deepLink: URL? { self.url }
}
