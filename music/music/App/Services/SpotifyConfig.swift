import Foundation

/// Central configuration for Spotify Web API & OAuth 2.0 PKCE
public enum SpotifyConfig {
    /// Default Spotify Developer Application Client ID.
    /// Can be filled in code or entered dynamically in the app setup sheet.
    public static let defaultClientId: String = ""
    
    private static let clientIdKey = "soundshift_spotify_client_id"
    
    /// Returns stored Client ID from UserDefaults, or default code constant
    public static var activeClientId: String {
        get {
            if let saved = UserDefaults.standard.string(forKey: clientIdKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !saved.isEmpty {
                return saved
            }
            return defaultClientId
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: clientIdKey)
        }
    }
    
    /// Indicates whether a valid non-empty Client ID is set
    public static var isConfigured: Bool {
        let id = activeClientId
        return !id.isEmpty && id != "YOUR_SPOTIFY_CLIENT_ID"
    }
    
    /// Custom scheme callback URI registered in Spotify Developer Dashboard
    public static let redirectUri = "soundshift://spotify-callback"
    public static let callbackScheme = "soundshift"
    
    /// Production OAuth Scopes for reading & writing tracks/playlists
    public static let scopes = [
        "user-read-private",
        "user-read-email",
        "user-library-read",
        "user-library-modify",
        "playlist-read-private",
        "playlist-read-collaborative",
        "playlist-modify-public",
        "playlist-modify-private"
    ].joined(separator: " ")
}

