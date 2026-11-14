import Foundation

public struct OnboardingSlide: Identifiable {
    public let id: Int
    public let videoResourceName: String
    public let badgeText: String
    public let headline: String
    public let subheadline: String
    public let metricValue: String
    public let metricLabel: String
    public let actionButtonTitle: String
    
    public static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            videoResourceName: "onboarding_1_sofa",
            badgeText: "ALL-IN-ONE LIBRARY",
            headline: "Your Entire Music Universe.\nWithout Boundaries.",
            subheadline: "Unite Spotify and Apple Music into one living catalog. No lost likes, no isolated silos.",
            metricValue: "2",
            metricLabel: "Services Live Now",
            actionButtonTitle: "Continue"
        ),
        OnboardingSlide(
            id: 1,
            videoResourceName: "onboarding_2_walk",
            badgeText: "ZERO-EFFORT MIGRATION",
            headline: "Switch Streaming Services.\nKeep Every Single Track.",
            subheadline: "Moving platforms shouldn't mean starting over. Transfer liked songs and playlists with ISRC matching on the Create tab.",
            metricValue: "ISRC",
            metricLabel: "Match Engine Ready",
            actionButtonTitle: "Next"
        ),
        OnboardingSlide(
            id: 2,
            videoResourceName: "onboarding_3_beach",
            badgeText: "DEEP TASTE ANALYTICS",
            headline: "Beyond Superficial Top 5s.\nDecode Your Sonic DNA.",
            subheadline: "Explore decade affinities and listening habits computed on-device from your synced library — not demo numbers.",
            metricValue: "On-device",
            metricLabel: "Taste from Your Library",
            actionButtonTitle: "Explore"
        ),
        OnboardingSlide(
            id: 3,
            videoResourceName: "onboarding_4_space",
            badgeText: "CONNECT → TASTE → MOVE",
            headline: "Break Free from Lock-in.\nYour Music Is Truly Yours.",
            subheadline: "Connect Spotify or Apple Music, sync your library, review Taste, then run a live migration from Create.",
            metricValue: "Start",
            metricLabel: "With Connect",
            actionButtonTitle: "Connect Your Music"
        )
    ]
}

