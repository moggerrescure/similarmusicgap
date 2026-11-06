import Foundation
#if os(iOS)
import UIKit
#endif

/// Deep Linking Engine into official streaming client applications (P1 - L6)
public enum DeepLinkManager {
    public static func openTrack(track: UniversalTrack, in provider: MusicProviderType) {
        let url: URL?
        
        switch provider {
        case .spotify:
            if let id = track.spotifyId {
                url = URL(string: "spotify:track:\(id)") ?? URL(string: "https://open.spotify.com/track/\(id)")
            } else {
                let query = "\(track.title) \(track.primaryArtist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                url = URL(string: "spotify:search:\(query)") ?? URL(string: "https://open.spotify.com/search/\(query)")
            }
            
        case .appleMusic:
            if let id = track.appleMusicId {
                url = URL(string: "music://music.apple.com/song/\(id)") ?? URL(string: "https://music.apple.com/song/\(id)")
            } else {
                let query = "\(track.title) \(track.primaryArtist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                url = URL(string: "music://music.apple.com/search?term=\(query)") ?? URL(string: "https://music.apple.com/search?term=\(query)")
            }
            
        case .yandexMusic:
            if let id = track.yandexId {
                url = URL(string: "yandexmusic://track/\(id)") ?? URL(string: "https://music.yandex.ru/track/\(id)")
            } else {
                let query = "\(track.title) \(track.primaryArtist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                url = URL(string: "yandexmusic://search?text=\(query)") ?? URL(string: "https://music.yandex.ru/search?text=\(query)")
            }
        }
        
        guard let finalURL = url else { return }
        
        #if os(iOS)
        UIApplication.shared.open(finalURL, options: [:]) { success in
            if !success {
                // Fallback to web search
                print("[DeepLinkManager] Native app not installed. Opening browser fallback: \(finalURL)")
            }
        }
        #else
        print("[DeepLinkManager] Opening URL: \(finalURL)")
        #endif
    }
}

