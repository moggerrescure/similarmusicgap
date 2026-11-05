import SwiftUI

/// Official pixel-perfect brand badges for music streaming providers
public struct PlatformBrandBadgeView: View {
    let type: MusicProviderType
    var size: CGFloat = 46
    
    public init(type: MusicProviderType, size: CGFloat = 46) {
        self.type = type
        self.size = size
    }
    
    public var body: some View {
        Image(type.assetIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: Color(hex: type.brandColorHex).opacity(0.35), radius: size * 0.18, x: 0, y: size * 0.08)
    }
}
