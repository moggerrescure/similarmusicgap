import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Transfer Completion & Discrepancy Report View (P0 - T8, T13)
public struct TransferReportView: View {
    public let report: TransferExecutionReport
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet: Bool = false
    
    public init(report: TransferExecutionReport) {
        self.report = report
    }
    
    private var isFailure: Bool { !report.didSucceed }
    private var headlineColor: Color {
        if isFailure { return Color.red.opacity(0.9) }
        if report.isPartialSuccess || report.warningMessage != nil { return PastelTheme.amberWarning }
        return PastelTheme.emeraldSuccess
    }
    private var headlineTitle: String {
        if isFailure { return "Migration Failed" }
        if report.isNothingNewSuccess { return "Nothing New to Write" }
        if report.isPartialSuccess { return "Migration Partially Complete" }
        if report.warningMessage != nil { return "Migration Complete with Warnings" }
        return "Migration Complete"
    }
    private var headlineIcon: String {
        if isFailure { return "xmark.octagon.fill" }
        if report.isPartialSuccess || report.warningMessage != nil { return "exclamationmark.triangle.fill" }
        return "checkmark.seal.fill"
    }
    
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
                                Image(systemName: headlineIcon)
                                    .font(.system(size: 48))
                                    .foregroundColor(headlineColor)
                            )
                            .overlay(
                                Circle()
                                    .stroke(headlineColor.opacity(0.4), lineWidth: 1)
                            )
                            .padding(.top, 24)
                        
                        VStack(spacing: 6) {
                            Text(headlineTitle)
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
                        
                        if let warning = report.warningMessage {
                            Text(warning)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(PastelTheme.amberWarning)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        HStack(spacing: 10) {
                            ReportMetricCell(
                                title: "TRANSFERRED",
                                value: "\(report.successfullyTransferred)",
                                color: PastelTheme.emeraldSuccess
                            )
                            ReportMetricCell(
                                title: "ALREADY",
                                value: "\(report.skippedExisting)",
                                color: PastelTheme.amberWarning
                            )
                            ReportMetricCell(
                                title: "REMATCHED",
                                value: "\(report.alternatesAccepted)",
                                color: PastelTheme.slateBlue
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
                                HStack {
                                    Text("MISSING TRACKS")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .tracking(1.0)
                                        .foregroundColor(PastelTheme.textTertiary)
                                    Spacer()
                                    Button("Copy list") {
                                        HapticManager.lightImpact()
                                        #if os(iOS)
                                        UIPasteboard.general.string = MissingTracksExport.plainText(report.missingTracks)
                                        #endif
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.pastelOat)
                                    .accessibilityIdentifier("report.copy_missing")
                                }
                                Text("These weren’t written — search them manually or re-run after Sync.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PastelTheme.textTertiary)
                                ForEach(report.missingTracks.prefix(20)) { track in
                                    Text("\(track.primaryArtist) — \(track.title)")
                                        .font(.system(size: 13))
                                        .foregroundColor(PastelTheme.textSecondary)
                                }
                                if report.missingTracks.count > 20 {
                                    Text("…and \(report.missingTracks.count - 20) more (use Copy list)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(PastelTheme.textTertiary)
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
                                    Text("Share summary")
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
