import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

/// UIView subclass that hosts an AVPlayerLayer for seamless 60fps hardware playback
public final class PlayerUIView: UIView {
    override public class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    public var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Seamless gapless looping video player using AVQueuePlayer & AVPlayerLooper.
/// Falls back silently when the mp4 is missing from the bundle.
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
            queuePlayer?.pause()
            queuePlayer = nil
            playerLooper = nil
            view.playerLayer.player = nil
            
            guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4"),
                  FileManager.default.fileExists(atPath: url.path) else {
                // Videos are optional — OnboardingView paints AmbientWash behind this layer.
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
import AppKit

public struct LooperVideoPlayerView: View {
    public let videoName: String
    public init(videoName: String) { self.videoName = videoName }
    public var body: some View {
        Color.clear
    }
}
#endif
