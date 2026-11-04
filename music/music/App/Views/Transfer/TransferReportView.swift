import SwiftUI

/// Transfer Completion & Discrepancy Report View (P0 - T8, T13)
public struct TransferReportView: View {
    public let report: TransferExecutionReport
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet: Bool = false
    
    public init(report: TransferExecutionReport) {
        self.report = report
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Success Badge
                        Circle()
                            .fill(PastelTheme.card)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                            )
                            .overlay(
                                Circle()
                                    .stroke(PastelTheme.emeraldSuccess.opacity(0.4), lineWidth: 1)
                            )
                            .padding(.top, 24)
                        
                        VStack(spacing: 6) {
                            Text("Migration Complete")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            
                            Text("\(report.sourceProvider.displayName) → \(report.destinationProvider.displayName)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                        
                        // HUD Metric Trio
                        HStack(spacing: 12) {
                            ReportMetricCell(
                                title: "TRANSFERRED",
                                value: "\(report.successfullyTransferred)",
                                color: PastelTheme.emeraldSuccess
                            )
                            ReportMetricCell(
                                title: "REMATCHED",
                                value: "\(report.alternatesAccepted)",
                                color: PastelTheme.amberWarning
                            )
                            ReportMetricCell(
                                title: "MISSING",
                                value: "\(report.missingTracks.count)",
                                color: report.missingTracks.isEmpty ? PastelTheme.textTertiary : Color.red
                            )
                        }
                        
                        // Summary Narrative
                        VStack(alignment: .leading, spacing: 10) {
                            Text("EXECUTION SUMMARY")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.0)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            Text("Successfully transferred \(report.successfullyTransferred) songs with 100% track order fidelity in \(String(format: "%.1f", report.durationSeconds)) seconds. Target playlist created and ready for offline listening.")
                                .font(.system(size: 14))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                        
                        // Actions
                        VStack(spacing: 12) {
                            // Share Report Button (T13)
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
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                            
                            // Done Button
                            Button {
                                HapticManager.lightImpact()
                                dismiss()
                            } label: {
                                Text("Return to Library")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.textOnOat)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(PastelTheme.pastelOat)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .inlineNavigationBarTitle()
            .sheet(isPresented: $showingShareSheet) {
                ShareTextSheet(text: report.shareableText)
            }
        }
    }
}

// MARK: - Mini Metric Cell
private struct ReportMetricCell: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textTertiary)
            
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
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

