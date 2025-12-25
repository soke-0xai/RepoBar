import Foundation
import Security

public struct OAuthTokens: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date?

    public init(accessToken: String, refreshToken: String, expiresAt: Date?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public enum TokenStoreError: Error {
    case saveFailed
    case loadFailed
}

public struct TokenStore: Sendable {
    public static let shared = TokenStore()
    private let service = "com.steipete.repobar.auth"

    public init() {}

    public func save(tokens: OAuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "default",
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw TokenStoreError.saveFailed }
    }

    public func load() throws -> OAuthTokens? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "default",
            kSecReturnData: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw TokenStoreError.loadFailed }
        return try JSONDecoder().decode(OAuthTokens.self, from: data)
    }

    public func clear() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "default"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
