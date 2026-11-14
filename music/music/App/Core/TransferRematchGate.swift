import Foundation

/// Single gate for primary migrate and «Живой мост» — Strict must clear Rematch Inbox first.
public enum TransferRematchGate {
    public static func blocksMigrate(pendingRematchCount: Int, isStrict: Bool) -> Bool {
        pendingRematchCount > 0 && isStrict
    }
}
