import SwiftUI

/// Main Transfer Configuration & Migration Master View (P0 - T1, T2, T3, T5, T6, T11)
public struct TransferConfigView: View {
    @StateObject private var transferManager = TransferManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    // Config State
    @State private var sourceProvider: MusicProviderType = .yandexMusic
    @State private var destinationProvider: MusicProviderType = .spotify
    @State private var scope = TransferScope()
    @State private var conflictPolicy: ConflictPolicy = .skip
    
    // Flow Sheet Triggers
    @State private var isAnalyzingDryRun: Bool = false
    @State private var showingLiveMigration: Bool = false
    @State private var showingRematchInbox: Bool = false
    @State private var completedReport: TransferExecutionReport?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Step 1: Direction Hub (Source -> Destination)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("MIGRATION PATH (T1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        HStack(spacing: 12) {
                            // Source Picker Card
                            DirectionCard(
                                title: "SOURCE",
                                selection: $sourceProvider,
                                options: MusicProviderType.allCases
                            )
                            
                            // Swap Arrow
                            Button {
                                HapticManager.lightImpact()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    let temp = sourceProvider
                                    sourceProvider = destinationProvider
                                    destinationProvider = temp
                                    transferManager.lastDryRun = nil
                                }
                            } label: {
                                Circle()
                                    .fill(PastelTheme.card)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(PastelTheme.pastelOat)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                    )
                            }
                            
                            // Destination Picker Card
                            DirectionCard(
                                title: "DESTINATION",
                                selection: $destinationProvider,
                                options: MusicProviderType.allCases.filter { $0 != sourceProvider }
                            )
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Step 2: Content Scope (T2, T3)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WHAT TO TRANSFER")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        // Favorite Songs Toggle
                        Toggle(isOn: $scope.transferFavorites) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Liked Songs & Favorites (T3)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                Text("Your core library favorites with preserved order")
                                    .font(.system(size: 13))
                                    .foregroundColor(PastelTheme.textSecondary)
                            }
                        }
                        .tint(PastelTheme.emeraldSuccess)
                        
                        Divider().background(PastelTheme.cardBorder)
                        
                        // Conflict Policy Picker (T11)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Conflict Policy (T11)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            
                            Picker("Policy", selection: $conflictPolicy) {
                                ForEach(ConflictPolicy.allCases) { policy in
                                    Text(policy.rawValue).tag(policy)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text(conflictPolicy.description)
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.textTertiary)
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Step 3: Dry-Run Match Visualizer (T6, T7)
                    if let dryRun = transferManager.lastDryRun {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("DRY-RUN ANALYSIS PREVIEW (T6)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1.0)
                                    .foregroundColor(PastelTheme.pastelOat)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", dryRun.matchRatePercentage))% MATCH")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                            }
                            
                            // Multi-color segmented progress bar
                            GeometryReader { geo in
                                HStack(spacing: 3) {
                                    Rectangle()
                                        .fill(PastelTheme.emeraldSuccess)
                                        .frame(width: geo.size.width * CGFloat(Double(dryRun.exactMatchesCount) / max(1.0, Double(dryRun.totalTracks))))
                                    Rectangle()
                                        .fill(PastelTheme.amberWarning)
                                        .frame(width: geo.size.width * CGFloat(Double(dryRun.alternateMatchesCount) / max(1.0, Double(dryRun.totalTracks))))
                                    Rectangle()
                                        .fill(Color.red.opacity(0.8))
                                }
                                .clipShape(Capsule())
                            }
                            .frame(height: 8)
                            
                            // Breakdown labels
                            HStack {
                                Label("\(dryRun.exactMatchesCount) Exact", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                                Spacer()
                                Label("\(dryRun.alternateMatchesCount) Alternate", systemImage: "questionmark.circle.fill")
                                    .foregroundColor(PastelTheme.amberWarning)
                                Spacer()
                                Label("\(dryRun.missingCount) Missing", systemImage: "xmark.circle.fill")
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            
                            // Button to inspect alternates if any
                            if !transferManager.rematchQueue.isEmpty {
                                Button {
                                    showingRematchInbox = true
                                } label: {
                                    HStack {
                                        Text("Review \(transferManager.rematchQueue.count) Alternates in Inbox")
                                            .font(.system(size: 13, weight: .semibold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(PastelTheme.amberWarning)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(18)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        if transferManager.lastDryRun == nil {
                            // Primary Action: Run Dry-Run Analysis
                            Button {
                                HapticManager.lightImpact()
                                runDryRun()
                            } label: {
                                HStack(spacing: 8) {
                                    if isAnalyzingDryRun {
                                        ProgressView().tint(PastelTheme.textOnOat)
                                    } else {
                                        Text("Analyze Matching (Dry-Run)")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        Image(systemName: "sparkles")
                                    }
                                }
                                .foregroundColor(PastelTheme.textOnOat)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(PastelTheme.pastelOat)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                        } else {
                            // Primary Action: Execute Live Migration
                            Button {
                                HapticManager.successNotification()
                                startLiveMigration()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Start Full Migration")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 20))
                                }
                                .foregroundColor(PastelTheme.textOnOat)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(PastelTheme.emeraldSuccess)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Transfer Studio")
        .inlineNavigationBarTitle()
        .fullScreenOrSheet(isPresented: $showingLiveMigration) {
            LiveTransferHUDView()
        }
        .sheet(item: $completedReport) { report in
            TransferReportView(report: report)
        }
        .sheet(isPresented: $showingRematchInbox) {
            RematchInboxView()
        }
    }
    
    private func runDryRun() {
        isAnalyzingDryRun = true
        Task {
            _ = await transferManager.executeDryRun(
                sourceType: sourceProvider,
                destinationType: destinationProvider,
                scope: scope
            )
            isAnalyzingDryRun = false
        }
    }
    
    private func startLiveMigration() {
        showingLiveMigration = true
        Task {
            let report = await transferManager.startMigration(
                sourceType: sourceProvider,
                destinationType: destinationProvider,
                scope: scope,
                policy: conflictPolicy
            )
            showingLiveMigration = false
            completedReport = report
        }
    }
}

// MARK: - Direction Card Helper
private struct DirectionCard: View {
    let title: String
    @Binding var selection: MusicProviderType
    let options: [MusicProviderType]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(PastelTheme.textTertiary)
            
            Menu {
                ForEach(options) { opt in
                    Button(opt.displayName) {
                        selection = opt
                    }
                }
            } label: {
                HStack {
                    Circle()
                        .fill(Color(hex: selection.brandColorHex))
                        .frame(width: 8, height: 8)
                    
                    Text(selection.displayName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(PastelTheme.textTertiary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TransferConfigView()
    }
}

