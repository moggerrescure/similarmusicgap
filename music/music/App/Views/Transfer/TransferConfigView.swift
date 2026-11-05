import SwiftUI

public enum TransferPreset: String, CaseIterable, Identifiable {
    case full = "Full Vault"
    case favorites = "Favorites Only"
    case delta = "Delta (New Only)"
    public var id: String { rawValue }
}

public enum MatchingSensitivity: String, CaseIterable, Identifiable {
    case strict = "Strict ISRC"
    case flexible = "Flexible Acoustic"
    public var id: String { rawValue }
}

/// Main Transfer Configuration & Migration Master View
public struct TransferConfigView: View {
    @StateObject private var transferManager = TransferManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    // Config State
    @State private var sourceProvider: MusicProviderType = .yandexMusic
    @State private var destinationProvider: MusicProviderType = .spotify
    @State private var scope = TransferScope()
    @State private var conflictPolicy: ConflictPolicy = .skip
    @State private var selectedPreset: TransferPreset = .favorites
    @State private var matchingSensitivity: MatchingSensitivity = .strict
    @State private var autoSyncEnabled: Bool = false
    
    // Flow Sheet Triggers
    @State private var isAnalyzingDryRun: Bool = false
    @State private var showingLiveMigration: Bool = false
    @State private var showingBridgeFlow: Bool = false
    @State private var showingRematchInbox: Bool = false
    @State private var showingProfileSheet: Bool = false
    @State private var completedReport: TransferExecutionReport?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            CosmicParticleBackgroundView(particleCount: 45)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    routeSection
                    presetsSection
                    preferencesSection
                    if transferManager.lastDryRun != nil {
                        dryRunSection
                    }
                    actionButtonsSection
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Transfer")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticManager.lightImpact()
                    showingProfileSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(PastelTheme.cardSubtle)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                }
            }
        }
        .fullScreenOrSheet(isPresented: $showingLiveMigration) {
            LiveTransferHUDView()
        }
        .sheet(isPresented: $showingBridgeFlow) {
            TransferBridgeFlowView(source: sourceProvider, destination: destinationProvider)
        }
        .sheet(item: $completedReport) { report in
            TransferReportView(report: report)
        }
        .sheet(isPresented: $showingRematchInbox) {
            RematchInboxView()
        }
        .sheet(isPresented: $showingProfileSheet) {
            UserProfileSheet()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRANSFER ROUTE")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Source Menu
                Menu {
                    ForEach(MusicProviderType.allCases) { opt in
                        Button {
                            sourceProvider = opt
                            if destinationProvider == opt {
                                destinationProvider = MusicProviderType.allCases.first { $0 != opt } ?? .appleMusic
                            }
                            transferManager.lastDryRun = nil
                        } label: {
                            HStack {
                                Text(opt.displayName)
                                if sourceProvider == opt { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("From")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                            .frame(width: 44, alignment: .leading)
                        
                        PlatformBrandBadgeView(type: sourceProvider, size: 24)
                        
                        Text(sourceProvider.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                }
                
                // Swap Button Divider
                ZStack {
                    Divider().background(PastelTheme.cardBorder)
                    
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
                            .fill(PastelTheme.cardSubtle)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(PastelTheme.pastelOat)
                            )
                            .overlay(
                                Circle().stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                
                // Destination Menu
                Menu {
                    ForEach(MusicProviderType.allCases.filter { $0 != sourceProvider }) { opt in
                        Button {
                            destinationProvider = opt
                            transferManager.lastDryRun = nil
                        } label: {
                            HStack {
                                Text(opt.displayName)
                                if destinationProvider == opt { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("To")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                            .frame(width: 44, alignment: .leading)
                        
                        PlatformBrandBadgeView(type: destinationProvider, size: 24)
                        
                        Text(destinationProvider.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                }
            }
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var presetsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransferPreset.allCases) { preset in
                    presetPill(preset)
                }
            }
        }
    }
    
    @ViewBuilder
    private func presetPill(_ preset: TransferPreset) -> some View {
        let isSelected = selectedPreset == preset
        Button {
            HapticManager.lightImpact()
            selectedPreset = preset
            switch preset {
            case .full:
                scope.transferFavorites = true
            case .favorites:
                scope.transferFavorites = true
                scope.selectedPlaylistIds.removeAll()
            case .delta:
                scope.transferFavorites = true
            }
            transferManager.lastDryRun = nil
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(preset.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? PastelTheme.pastelOat : PastelTheme.card)
            .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
    
    @ViewBuilder
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREFERENCES")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                Toggle(isOn: $scope.transferFavorites) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Favorites & Liked Songs")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(PastelTheme.textPrimary)
                        Text("Preserve original track order and date added")
                            .font(.system(size: 13))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                }
                .tint(PastelTheme.emeraldSuccess)
                
                Divider().background(PastelTheme.cardBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("When Track Already Exists")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                    
                    Picker("Conflict Policy", selection: $conflictPolicy) {
                        ForEach(ConflictPolicy.allCases) { policy in
                            Text(policy.rawValue).tag(policy)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(conflictPolicy.description)
                        .font(.system(size: 12))
                        .foregroundColor(PastelTheme.textTertiary)
                }
                
                Divider().background(PastelTheme.cardBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Acoustic Matching Precision")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                    
                    Picker("Matching Sensitivity", selection: $matchingSensitivity) {
                        ForEach(MatchingSensitivity.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(PastelTheme.cardBorder)
                
                Toggle(isOn: $autoSyncEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automated Daily Sync")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(PastelTheme.textPrimary)
                        Text("Runs delta updates nightly at 3:00 AM")
                            .font(.system(size: 13))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                }
                .tint(PastelTheme.emeraldSuccess)
            }
            .padding(16)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var dryRunSection: some View {
        if let dryRun = transferManager.lastDryRun {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("MATCH PREVIEW")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", dryRun.matchRatePercentage))%")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(PastelTheme.emeraldSuccess)
                        .monospacedDigit()
                }
                
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(PastelTheme.emeraldSuccess)
                            .frame(width: geo.size.width * CGFloat(Double(dryRun.exactMatchesCount) / max(1.0, Double(dryRun.totalTracks))))
                        Rectangle()
                            .fill(PastelTheme.amberWarning)
                            .frame(width: geo.size.width * CGFloat(Double(dryRun.alternateMatchesCount) / max(1.0, Double(dryRun.totalTracks))))
                        Rectangle()
                            .fill(PastelTheme.cardSubtle)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 6)
                
                HStack {
                    Label("\(dryRun.exactMatchesCount) Exact", systemImage: "checkmark.circle.fill")
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    Spacer()
                    Label("\(dryRun.alternateMatchesCount) Alternate", systemImage: "arrow.triangle.swap")
                        .foregroundColor(PastelTheme.amberWarning)
                    Spacer()
                    Label("\(dryRun.missingCount) Missing", systemImage: "xmark.circle")
                        .foregroundColor(PastelTheme.textTertiary)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                
                if !transferManager.rematchQueue.isEmpty {
                    Button {
                        showingRematchInbox = true
                    } label: {
                        HStack {
                            Text("Review \(transferManager.rematchQueue.count) Alternates")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(PastelTheme.amberWarning)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(16)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if transferManager.lastDryRun == nil {
                Button {
                    HapticManager.lightImpact()
                    runDryRun()
                } label: {
                    HStack(spacing: 8) {
                        if isAnalyzingDryRun {
                            ProgressView().tint(PastelTheme.textOnOat)
                        } else {
                            Image(systemName: "slider.horizontal.2.square")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Analyze Match Compatibility")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(PastelTheme.textOnOat)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(PastelTheme.pastelOat)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(TouchFeedbackButtonStyle())
            } else {
                VStack(spacing: 10) {
                    Button {
                        HapticManager.successNotification()
                        startLiveMigration()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Begin Transfer")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PastelTheme.emeraldSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    
                    Button {
                        HapticManager.lightImpact()
                        showingBridgeFlow = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 14, weight: .semibold))
                            Text("View Interactive Bridge Stream")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(PastelTheme.pastelOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT TRANSFERS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                HistoryItemRow(
                    from: .spotify,
                    to: .appleMusic,
                    trackCount: 840,
                    matchRate: "100%",
                    timeAgo: "Yesterday"
                )
                HistoryItemRow(
                    from: .yandexMusic,
                    to: .spotify,
                    trackCount: 142,
                    matchRate: "98.6%",
                    timeAgo: "3 days ago"
                )
            }
        }
        .padding(.top, 4)
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

// MARK: - History Item Row Component
private struct HistoryItemRow: View {
    let from: MusicProviderType
    let to: MusicProviderType
    let trackCount: Int
    let matchRate: String
    let timeAgo: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                PlatformBrandBadgeView(type: from, size: 20)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PastelTheme.textTertiary)
                PlatformBrandBadgeView(type: to, size: 20)
            }
            .frame(width: 56)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(from.displayName) to \(to.displayName)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text("\(trackCount) tracks • \(timeAgo)")
                    .font(.system(size: 12))
                    .foregroundColor(PastelTheme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(PastelTheme.emeraldSuccess)
                Text(matchRate)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.emeraldSuccess)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PastelTheme.cardSubtle)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}

#if DEBUG
struct TransferConfigView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TransferConfigView()
        }
    }
}
#endif
