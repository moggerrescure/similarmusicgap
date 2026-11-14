import Foundation

/// Decides what to do when the live write list is empty after matching + Skip policy.
public enum EmptyTransferPlanner {
    public enum Decision: Equatable {
        /// Create destination playlist as usual (never writes Liked Songs).
        case writePlaylist
        /// Every matched track was already on the destination — not an error.
        case successNothingNew(skippedExisting: Int)
        /// Nothing matched and nothing was skippable — user must rematch / sync.
        case failureNoMatches
    }
    
    public static func decide(transferableCount: Int, skippedExisting: Int) -> Decision {
        if transferableCount > 0 { return .writePlaylist }
        if skippedExisting > 0 { return .successNothingNew(skippedExisting: skippedExisting) }
        return .failureNoMatches
    }
}
