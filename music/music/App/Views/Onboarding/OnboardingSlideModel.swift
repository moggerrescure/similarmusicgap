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
            badgeText: "MUSIC MIGRATOR",
            headline: "Move Your Library.\nKeep Every Match.",
            subheadline: "SoundShift transfers playlists between Spotify, Apple Music, and Yandex — LIVE accounts only.",
            metricValue: "3",
            metricLabel: "Services Supported",
            actionButtonTitle: "Continue"
        ),
        OnboardingSlide(
            id: 1,
            videoResourceName: "onboarding_2_walk",
            badgeText: "ISRC MATCHING",
            headline: "Switch Platforms.\nDon’t Lose the Songs.",
            subheadline: "Dry-run match preview, then migrate into a new playlist on the Move tab. Skip or Merge — never silent overwrite.",
            metricValue: "ISRC",
            metricLabel: "Match Engine Ready",
            actionButtonTitle: "Next"
        ),
        OnboardingSlide(
            id: 2,
            videoResourceName: "onboarding_3_beach",
            badgeText: "ON-DEVICE TASTE",
            headline: "See Your Sonic DNA.\nFrom Your Real Sync.",
            subheadline: "Taste analytics use your synced library on-device — empty until you Connect & Sync.",
            metricValue: "On-device",
            metricLabel: "From Synced Library",
            actionButtonTitle: "Explore"
        ),
        OnboardingSlide(
            id: 3,
            videoResourceName: "onboarding_4_space",
            badgeText: "CONNECT → SYNC → MOVE",
            headline: "Break Free from Lock-in.\nYour Music Stays Yours.",
            subheadline: "Connect LIVE services, sync on screen, then run migration from Move. Migrations tab keeps the history.",
            metricValue: "Start",
            metricLabel: "With Connect",
            actionButtonTitle: "Connect Your Music"
        )
    ]
}
