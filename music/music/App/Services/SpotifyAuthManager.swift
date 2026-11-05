import Foundation
import AuthenticationServices
import CryptoKit
import Security
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Token payload received from Spotify Accounts OAuth endpoint
public struct SpotifyTokenResponse: Codable {
    public let access_token: String
    public let token_type: String
    public let scope: String?
    public let expires_in: Int
    public let refresh_token: String?
}

/// Cross-platform presentation context provider for ASWebAuthenticationSession
final class WebAuthenticationPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthenticationPresentationContext()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        if let window = activeScene?.windows.first(where: { $0.isKeyWindow }) ?? activeScene?.windows.first {
            return window
        }
        return UIWindow()
        #elseif canImport(AppKit)
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            return window
        }
        return NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        #endif
    }
}

/// High-performance Spotify OAuth 2.0 PKCE Authorization Engine (RFC 7636)
public final class SpotifyAuthManager {
    public static let shared = SpotifyAuthManager()
    
    private let tokenKey = "spotify_access_token"
    private let refreshKey = "spotify_refresh_token"
    private let verifierKey = "spotify_temp_code_verifier"
    private let expiresAtKey = "spotify_token_expires_at"
    
    private init() {}
    
    // MARK: - PKCE Cryptographic Helpers (RFC 7636)
    
    /// Generates high-entropy cryptographic random string for PKCE code verifier
    public static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// Computes SHA-256 hash of verifier and returns Base64URL-encoded challenge
    public static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - ASWebAuthenticationSession Launch
    
    /// Launches native browser sheet to authenticate user with Spotify PKCE
    @MainActor
    public func startPKCEFlow(clientId: String) async throws -> String {
        let verifier = Self.generateCodeVerifier()
        let challenge = Self.generateCodeChallenge(from: verifier)
        
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyConfig.redirectUri),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: SpotifyConfig.scopes)
        ]
        
        guard let authURL = components.url else {
            throw NSError(domain: "SpotifyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Spotify authorization URL."])
        }
        
        // Save verifier in Keychain temporarily for token exchange step
        KeychainManager.save(token: verifier, for: verifierKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: SpotifyConfig.callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                    continuation.resume(throwing: NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid callback from Spotify."]))
                    return
                }
                
                if let errorParam = urlComponents.queryItems?.first(where: { $0.name == "error" })?.value {
                    continuation.resume(throwing: NSError(domain: "SpotifyAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Spotify Auth Denied: \(errorParam)"]))
                    return
                }
                
                guard let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: NSError(domain: "SpotifyAuth", code: -4, userInfo: [NSLocalizedDescriptionKey: "Authorization code missing in callback."]))
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            session.presentationContextProvider = WebAuthenticationPresentationContext.shared
            session.prefersEphemeralWebBrowserSession = false
            
            if !session.start() {
                continuation.resume(throwing: NSError(domain: "SpotifyAuth", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unable to present Apple Web Authentication sheet."]))
            }
        }
    }
    
    // MARK: - Token Exchange (Code -> Access & Refresh Tokens)
    
    public func exchangeCodeForTokens(code: String, clientId: String) async throws -> SpotifyTokenResponse {
        guard let verifier = KeychainManager.loadToken(for: verifierKey), !verifier.isEmpty else {
            throw NSError(domain: "SpotifyAuth", code: -6, userInfo: [NSLocalizedDescriptionKey: "PKCE code verifier not found in Keychain."])
        }
        
        guard let tokenURL = URL(string: "https://accounts.spotify.com/api/token") else {
            throw NSError(domain: "SpotifyAuth", code: -7, userInfo: [NSLocalizedDescriptionKey: "Invalid token endpoint."])
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "code": code,
            "redirect_uri": SpotifyConfig.redirectUri,
            "code_verifier": verifier
        ]
        
        let bodyString = bodyParams
            .compactMap { key, value in
                guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SpotifyAuth", code: -8, userInfo: [NSLocalizedDescriptionKey: "No HTTP response received."])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "SpotifyAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Spotify Token Error: \(errorText)"])
        }
        
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        
        // Persist tokens securely in Apple Keychain
        KeychainManager.save(token: tokenResponse.access_token, for: tokenKey)
        if let refreshToken = tokenResponse.refresh_token {
            KeychainManager.save(token: refreshToken, for: refreshKey)
        }
        
        // Save expiration time
        let expiresAt = Date().timeIntervalSince1970 + Double(tokenResponse.expires_in)
        UserDefaults.standard.set(expiresAt, forKey: expiresAtKey)
        
        // Cleanup temporary verifier
        KeychainManager.deleteToken(for: verifierKey)
        
        return tokenResponse
    }
    
    // MARK: - Token Refresh
    
    public func getValidAccessToken(clientId: String) async throws -> String {
        let now = Date().timeIntervalSince1970
        let expiresAt = UserDefaults.standard.double(forKey: expiresAtKey)
        
        // Re-use current token if it has more than 60 seconds of validity
        if let currentToken = KeychainManager.loadToken(for: tokenKey),
           !currentToken.isEmpty,
           expiresAt > (now + 60) {
            return currentToken
        }
        
        // Refresh token if available
        guard let refreshToken = KeychainManager.loadToken(for: refreshKey), !refreshToken.isEmpty else {
            if let currentToken = KeychainManager.loadToken(for: tokenKey), !currentToken.isEmpty {
                return currentToken
            }
            throw NSError(domain: "SpotifyAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated with Spotify."])
        }
        
        guard let tokenURL = URL(string: "https://accounts.spotify.com/api/token") else {
            throw NSError(domain: "SpotifyAuth", code: -7, userInfo: [NSLocalizedDescriptionKey: "Invalid token endpoint."])
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId
        ]
        
        let bodyString = bodyParams
            .compactMap { key, value in
                guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Refresh failed"
            throw NSError(domain: "SpotifyAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Refresh failed: \(errorText)"])
        }
        
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        KeychainManager.save(token: tokenResponse.access_token, for: tokenKey)
        if let newRefresh = tokenResponse.refresh_token {
            KeychainManager.save(token: newRefresh, for: refreshKey)
        }
        
        let newExpiresAt = Date().timeIntervalSince1970 + Double(tokenResponse.expires_in)
        UserDefaults.standard.set(newExpiresAt, forKey: expiresAtKey)
        
        return tokenResponse.access_token
    }
    
    // MARK: - Revoke / Sign Out
    
    public func clearTokens() {
        KeychainManager.deleteToken(for: tokenKey)
        KeychainManager.deleteToken(for: refreshKey)
        KeychainManager.deleteToken(for: verifierKey)
        UserDefaults.standard.removeObject(forKey: expiresAtKey)
    }
}

