import Foundation

public struct OAuthTokenRefresher: Sendable {
    private let tokenStore: TokenStore

    public init(tokenStore: TokenStore = .shared) {
        self.tokenStore = tokenStore
    }

    public func refreshIfNeeded(host: URL) async throws -> OAuthTokens? {
        guard var tokens = try tokenStore.load() else { return nil }
        if let expiry = tokens.expiresAt, expiry > Date().addingTimeInterval(60) {
            return tokens
        }

        let base = host.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let refreshURL = URL(string: "\(base)/login/oauth/access_token")!
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formUrlEncoded([
            "grant_type": "refresh_token",
            "refresh_token": tokens.refreshToken
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        let expires = Date().addingTimeInterval(TimeInterval(decoded.expiresIn ?? 3600))
        tokens = OAuthTokens(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken ?? tokens.refreshToken,
            expiresAt: expires
        )
        try self.tokenStore.save(tokens: tokens)
        return tokens
    }
}

private extension OAuthTokenRefresher {
    static func formUrlEncoded(_ params: [String: String]) -> Data? {
        let encoded = params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
        return encoded.data(using: .utf8)
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
