import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

/// UIView subclass that hosts an AVPlayerLayer for seamless 60fps hardware playback
final class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Seamless gapless looping video player using AVQueuePlayer & AVPlayerLooper
public struct LooperVideoPlayerView: UIViewRepresentable {
    public let videoName: String
    
    public init(videoName: String) {
        self.videoName = videoName
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        context.coordinator.setupPlayer(for: view, videoName: videoName)
        return view
    }
    
    public func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if context.coordinator.currentVideoName != videoName {
            context.coordinator.setupPlayer(for: uiView, videoName: videoName)
        }
    }
    
    public final class Coordinator {
        var queuePlayer: AVQueuePlayer?
        var playerLooper: AVPlayerLooper?
        var currentVideoName: String?
        
        func setupPlayer(for view: PlayerUIView, videoName: String) {
            currentVideoName = videoName
            
            // Look up in main bundle or App Resources folder
            let url = Bundle.main.url(forResource: videoName, withExtension: "mp4")
                ?? Bundle.main.url(forResource: "Resources/Videos/\(videoName)", withExtension: "mp4")
                ?? URL(fileURLWithPath: "App/Resources/Videos/\(videoName).mp4")
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("⚠️ [LooperVideoPlayerView] Video not found at path: \(url.path)")
                return
            }
            
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            
            let player = AVQueuePlayer(playerItem: item)
            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            
            let looper = AVPlayerLooper(player: player, templateItem: item)
            
            self.queuePlayer = player
            self.playerLooper = looper
            view.playerLayer.player = player
            
            player.play()
        }
    }
}
#else
// macOS Fallback for SwiftUI preview & testing
import AppKit

public struct LooperVideoPlayerView: View {
    public let videoName: String
    public init(videoName: String) { self.videoName = videoName }
    public var body: some View {
        Color.black
            .overlay(Text("Video: \(videoName)").foregroundColor(.white))
    }
}
#endif

