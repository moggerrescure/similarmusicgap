import SwiftUI

/// Transfer Completion & Discrepancy Report View (P0 - T8, T13)
public struct TransferReportView: View {
    public let report: TransferExecutionReport
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet: Bool = false
    
    public init(report: TransferExecutionReport) {
        self.report = report
    }
    
    private var isFailure: Bool { !report.didSucceed }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Circle()
                            .fill(PastelTheme.card)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: isFailure ? "xmark.octagon.fill" : "checkmark.seal.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(isFailure ? Color.red.opacity(0.9) : PastelTheme.emeraldSuccess)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        (isFailure ? Color.red : PastelTheme.emeraldSuccess).opacity(0.4),
                                        lineWidth: 1
                                    )
                            )
                            .padding(.top, 24)
                        
                        VStack(spacing: 6) {
                            Text(isFailure ? "Migration Failed" : "Migration Complete")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            
                            Text("\(report.sourceProvider.displayName) → \(report.destinationProvider.displayName)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                        
                        if let error = report.errorMessage {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        HStack(spacing: 12) {
                            ReportMetricCell(
                                title: "TRANSFERRED",
                                value: "\(report.successfullyTransferred)",
                                color: PastelTheme.emeraldSuccess
                            )
                            ReportMetricCell(
                                title: report.skippedExisting > 0 ? "ALREADY THERE" : "REMATCHED",
                                value: report.skippedExisting > 0
                                    ? "\(report.skippedExisting)"
                                    : "\(report.alternatesAccepted)",
                                color: PastelTheme.amberWarning
                            )
                            ReportMetricCell(
                                title: "MISSING",
                                value: "\(report.missingTracks.count)",
                                color: report.missingTracks.isEmpty ? PastelTheme.textTertiary : Color.red
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EXECUTION SUMMARY")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.0)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            if isFailure {
                                Text(report.errorMessage ?? "Transfer did not complete. Check Connect auth and try again.")
                                    .font(.system(size: 14))
                                    .foregroundColor(PastelTheme.textSecondary)
                                    .lineSpacing(3)
                            } else if report.isNothingNewSuccess {
                                Text(
                                    """
                                    Nothing new to write — \(report.skippedExisting) matched track\(report.skippedExisting == 1 ? "" : "s") \
                                    already on \(report.destinationProvider.displayName). \
                                    No playlist was created.
                                    \(report.missingTracks.isEmpty ? "" : "\(report.missingTracks.count) still unresolved.")
                                    """
                                )
                                .font(.system(size: 14))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineSpacing(3)
                            } else {
                                Text(
                                    """
                                    Wrote \(report.successfullyTransferred) of \(report.totalTracks) tracks \
                                    (\(String(format: "%.0f", report.matchRate))% covered) in \
                                    \(String(format: "%.1f", report.durationSeconds))s.
                                    \(report.skippedExisting > 0 ? "Skipped \(report.skippedExisting) already on destination. " : "")\
                                    \(report.createdPlaylistName.map { "Playlist: \($0)." } ?? "")
                                    \(report.missingTracks.isEmpty ? "" : "\(report.missingTracks.count) tracks still missing.")
                                    """
                                )
                                .font(.system(size: 14))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineSpacing(3)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                        
                        if !report.missingTracks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MISSING TRACKS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1.0)
                                    .foregroundColor(PastelTheme.textTertiary)
                                ForEach(report.missingTracks.prefix(20)) { track in
                                    Text("\(track.primaryArtist) — \(track.title)")
                                        .font(.system(size: 13))
                                        .foregroundColor(PastelTheme.textSecondary)
                                }
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        VStack(spacing: 12) {
                            Button {
                                HapticManager.lightImpact()
                                showingShareSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Migration Summary")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(PastelTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textOnOat)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(PastelTheme.pastelOat)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Transfer Report")
            .inlineNavigationBarTitle()
            .sheet(isPresented: $showingShareSheet) {
                ShareTextSheet(text: report.shareableText)
            }
        }
    }
}

private struct ReportMetricCell: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(PastelTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#if os(iOS)
private struct ShareTextSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct ShareTextSheet: View {
    let text: String
    var body: some View { Text(text) }
}
#endif
