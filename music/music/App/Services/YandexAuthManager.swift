import Foundation

/// OAuth Device Flow for Yandex Music (same client used by community clients).
public final class YandexAuthManager {
    public static let shared = YandexAuthManager()
    
    /// Android Yandex Music OAuth client (Device Flow).
    public static let clientId = "23cabbbdc6cd418abb4b39c32c41195d"
    public static let clientSecret = "53bc75238f0c4d08a118e51fe9203300"
    
    public static let tokenKey = "yandex_music_oauth_token"
    public static let refreshKey = "yandex_music_refresh_token"
    public static let uidKey = "yandex_music_uid"
    public static let displayNameKey = "yandex_music_display_name"
    
    private init() {}
    
    public struct DeviceCodePayload: Decodable {
        public let deviceCode: String
        public let userCode: String
        public let verificationUrl: String
        public let interval: Int
        public let expiresIn: Int
        
        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case verificationUrl = "verification_url"
            case interval
            case expiresIn = "expires_in"
        }
    }
    
    public struct TokenPayload: Decodable {
        public let accessToken: String
        public let refreshToken: String?
        public let expiresIn: Int?
        public let tokenType: String?
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
        
        public init(accessToken: String, refreshToken: String? = nil, expiresIn: Int? = nil, tokenType: String? = "bearer") {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.tokenType = tokenType
        }
    }
    
    public func requestDeviceCode(deviceName: String = "SoundShift iPhone") async throws -> DeviceCodePayload {
        var request = URLRequest(url: URL(string: "https://oauth.yandex.ru/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let deviceId = String(
            UUID().uuidString
                .replacingOccurrences(of: "-", with: "")
                .lowercased()
                .prefix(50)
        )
        let body = [
            "client_id=\(Self.clientId)",
            "device_id=\(deviceId)",
            "device_name=\(deviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "SoundShift")"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw YandexAuthError.failed("Device code request failed: \(text.prefix(160))")
        }
        return try JSONDecoder().decode(DeviceCodePayload.self, from: data)
    }
    
    /// Returns token when authorized; `nil` while still pending.
    public func pollDeviceToken(deviceCode: String) async throws -> TokenPayload? {
        var request = URLRequest(url: URL(string: "https://oauth.yandex.ru/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type=device_code",
            "code=\(deviceCode)",
            "client_id=\(Self.clientId)",
            "client_secret=\(Self.clientSecret)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw YandexAuthError.failed("No HTTP response from token endpoint")
        }
        if http.statusCode == 200 {
            return try JSONDecoder().decode(TokenPayload.self, from: data)
        }
        // Pending / slow_down come back as 400 with error field
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = obj["error"] as? String {
            if error == "authorization_pending" || error == "slow_down" {
                return nil
            }
            throw YandexAuthError.failed(error)
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        throw YandexAuthError.failed("Token poll failed (\(http.statusCode)): \(text.prefix(120))")
    }
    
    public func persist(token: TokenPayload, uid: Int?, displayName: String?) {
        _ = KeychainManager.save(token: token.accessToken, for: Self.tokenKey)
        if let refresh = token.refreshToken {
            _ = KeychainManager.save(token: refresh, for: Self.refreshKey)
        }
        if let uid {
            _ = KeychainManager.save(token: "\(uid)", for: Self.uidKey)
        }
        if let displayName, !displayName.isEmpty {
            UserDefaults.standard.set(displayName, forKey: Self.displayNameKey)
        }
    }
    
    public func persistManualAccessToken(_ accessToken: String) {
        let trimmed = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = KeychainManager.save(token: trimmed, for: Self.tokenKey)
    }
    
    public func loadAccessToken() -> String? {
        KeychainManager.loadToken(for: Self.tokenKey)
    }
    
    public func loadRefreshToken() -> String? {
        KeychainManager.loadToken(for: Self.refreshKey)
    }
    
    public func loadUid() -> Int? {
        guard let raw = KeychainManager.loadToken(for: Self.uidKey) else { return nil }
        return Int(raw)
    }
    
    public func loadDisplayName() -> String? {
        UserDefaults.standard.string(forKey: Self.displayNameKey)
    }
    
    /// Refresh access token when a refresh_token was stored from Device Flow.
    /// Returns the new access token, or `nil` if no refresh token / refresh failed.
    @discardableResult
    public func refreshAccessTokenIfPossible() async -> String? {
        guard let refresh = loadRefreshToken(), !refresh.isEmpty else { return loadAccessToken() }
        var request = URLRequest(url: URL(string: "https://oauth.yandex.ru/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(refresh)",
            "client_id=\(Self.clientId)",
            "client_secret=\(Self.clientSecret)"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return loadAccessToken()
            }
            let payload = try JSONDecoder().decode(TokenPayload.self, from: data)
            persist(
                token: payload,
                uid: loadUid(),
                displayName: loadDisplayName()
            )
            return payload.accessToken
        } catch {
            return loadAccessToken()
        }
    }
    
    public func clear() {
        KeychainManager.deleteToken(for: Self.tokenKey)
        KeychainManager.deleteToken(for: Self.refreshKey)
        KeychainManager.deleteToken(for: Self.uidKey)
        UserDefaults.standard.removeObject(forKey: Self.displayNameKey)
    }
}

public enum YandexAuthError: LocalizedError {
    case failed(String)
    case cancelled
    case timedOut
    
    public var errorDescription: String? {
        switch self {
        case .failed(let msg): return msg
        case .cancelled: return "Yandex sign-in cancelled"
        case .timedOut: return "Yandex sign-in timed out — try again"
        }
    }
}
