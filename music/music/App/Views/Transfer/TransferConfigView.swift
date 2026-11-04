import SwiftUI

/// Main Transfer Configuration & Migration Master View
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
                VStack(spacing: 20) {
                    // MARK: - Section 1: Direction Hub
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TRANSFER ROUTE")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // Source Row Dropdown
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
                                            if sourceProvider == opt {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text("From")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .frame(width: 44, alignment: .leading)
                                    
                                    Image(systemName: sourceProvider.iconName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: sourceProvider.brandColorHex))
                                        .frame(width: 24)
                                    
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
                            
                            // Center Swap Divider
                            ZStack {
                                Divider()
                                    .background(PastelTheme.cardBorder)
                                
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
                                            Circle()
                                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Destination Row Dropdown
                            Menu {
                                ForEach(MusicProviderType.allCases.filter { $0 != sourceProvider }) { opt in
                                    Button {
                                        destinationProvider = opt
                                        transferManager.lastDryRun = nil
                                    } label: {
                                        HStack {
                                            Text(opt.displayName)
                                            if destinationProvider == opt {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text("To")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .frame(width: 44, alignment: .leading)
                                    
                                    Image(systemName: destinationProvider.iconName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: destinationProvider.brandColorHex))
                                        .frame(width: 24)
                                    
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
                    
                    // MARK: - Section 2: Content Preferences
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PREFERENCES")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 16) {
                            // Toggle Favorites
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
                            
                            Divider()
                                .background(PastelTheme.cardBorder)
                            
                            // Conflict Policy Segmented Control
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
                        }
                        .padding(16)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Section 3: Pre-Flight Match Analysis
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
                            
                            // Progress bar
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
                            
                            // Counters
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
                    
                    // MARK: - Action Button
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
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Transfer")
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

#Preview {
    NavigationStack {
        TransferConfigView()
    }
}
