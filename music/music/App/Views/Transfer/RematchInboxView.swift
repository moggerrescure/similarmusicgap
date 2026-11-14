import SwiftUI

/// Rematch Inbox for Manual Track Disambiguation (P1 - L4, T8)
public struct RematchInboxView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                if transferManager.rematchQueue.isEmpty {
                    rematchEmptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(transferManager.rematchQueue, id: \.sourceTrack.id) { matchItem in
                                RematchCard(item: matchItem) { accepted in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        transferManager.resolveRematch(item: matchItem, acceptCandidate: accepted)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Rematch Inbox")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(PastelTheme.pastelOat)
                }
            }
        }
    }
    
    @ViewBuilder
    private var rematchEmptyState: some View {
        let dryRun = transferManager.lastDryRun
        let report = transferManager.lastReport
        let allStrong = (dryRun?.alternateMatchesCount ?? -1) == 0
            && (dryRun?.missingCount ?? -1) == 0
            && (dryRun?.totalTracks ?? 0) > 0
            && (dryRun?.exactMatchesCount ?? 0) == (dryRun?.totalTracks ?? -1)
        
        VStack(spacing: 16) {
            Image(systemName: allStrong ? "checkmark.circle.fill" : "tray")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(allStrong ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
            
            Text(allStrong ? "Inbox Zero" : "Nothing to rematch")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
            
            Text(emptyCopy(allStrong: allStrong, report: report, dryRun: dryRun))
                .font(.system(size: 15))
                .foregroundColor(PastelTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func emptyCopy(allStrong: Bool, report: TransferExecutionReport?, dryRun: DryRunSummary?) -> String {
        if allStrong {
            return "All tracks matched with high confidence. No manual disambiguation required."
        }
        if let report, report.didSucceed, !report.missingTracks.isEmpty {
            return "No alternates left to review. Open the last transfer report for \(report.missingTracks.count) missing track\(report.missingTracks.count == 1 ? "" : "s")."
        }
        if dryRun == nil {
            return "Run a dry-run first — alternate matches that need a choice will appear here."
        }
        return "No alternate matches need a decision right now."
    }
}

// MARK: - Disambiguation Card
private struct RematchCard: View {
    let item: MatchResult
    let onDecision: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Source Track Box
            VStack(alignment: .leading, spacing: 4) {
                Text("SOURCE TRACK")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(PastelTheme.textTertiary)
                
                Text(item.sourceTrack.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text(item.sourceTrack.primaryArtist)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PastelTheme.cardSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Match Confidence & Target Candidate
            if let target = item.matchedTrack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("PROPOSED DESTINATION MATCH")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.amberWarning)
                        
                        Spacer()
                        
                        Text("\(Int(item.score * 100))% Confidence")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PastelTheme.amberWarning)
                    }
                    
                    Text(target.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    Text(target.primaryArtist)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PastelTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PastelTheme.amberWarning.opacity(0.35), lineWidth: 1)
                )
            }
            
            // 1-Tap Actions
            HStack(spacing: 12) {
                Button {
                    onDecision(false)
                } label: {
                    Text("Skip Track")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.red.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                Button {
                    onDecision(true)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Accept Match")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(PastelTheme.textOnOat)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(PastelTheme.pastelOat)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(TouchFeedbackButtonStyle())
            }
        }
        .padding(16)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}

