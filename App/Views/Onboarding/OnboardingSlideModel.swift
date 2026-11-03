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
            subheadline: "Unite Spotify, Apple Music, and Yandex Music into a single living catalog. No lost likes, no isolated silos.",
            metricValue: "14,800+",
            metricLabel: "Tracks in Unified View",
            actionButtonTitle: "Continue"
        ),
        OnboardingSlide(
            id: 1,
            videoResourceName: "onboarding_2_walk",
            badgeText: "ZERO-EFFORT MIGRATION",
            headline: "Switch Streaming Services.\nKeep Every Single Track.",
            subheadline: "Moving platforms shouldn't mean starting over. Seamlessly transfer playlists, albums, and favorites with preserved order.",
            metricValue: "99.4%",
            metricLabel: "ISRC Match Accuracy",
            actionButtonTitle: "Next"
        ),
        OnboardingSlide(
            id: 2,
            videoResourceName: "onboarding_3_beach",
            badgeText: "DEEP TASTE ANALYTICS",
            headline: "Beyond Superficial Top 5s.\nDecode Your Sonic DNA.",
            subheadline: "Explore acoustic dimensions, mood clusters, and decade affinities. Understand your true taste across all services.",
            metricValue: "18 Moods",
            metricLabel: "Autonomous Cluster Engine",
            actionButtonTitle: "Explore"
        ),
        OnboardingSlide(
            id: 3,
            videoResourceName: "onboarding_4_space",
            badgeText: "INFINITE SOUNDSCAPE",
            headline: "Break Free from Lock-in.\nYour Music Is Truly Yours.",
            subheadline: "Export universal backups, discover cross-service music twins, and step into an infinite sonic universe.",
            metricValue: "Zero",
            metricLabel: "Lock-in Forever",
            actionButtonTitle: "Start Your Sonic Journey"
        )
    ]
}

