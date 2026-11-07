import SwiftUI

public enum TransferMainMode: String, CaseIterable, Identifiable {
    case serviceTransfer = "Перенос в сервис"
    case fileExport = "Выкачать в файл"
    public var id: String { rawValue }
}

public enum ExportFormatOption: String, CaseIterable, Identifiable {
    case csv = "Таблица CSV"
    case txt = "Список TXT"
    case json = "Universal JSON"
    case m3u = "Плейлист M3U"
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .csv: return "tablecells.badge.ellipsis"
        case .txt: return "doc.text.fill"
        case .json: return "curlybraces.square.fill"
        case .m3u: return "music.note.list"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .csv: return "Для Excel, Sheets и переноса"
        case .txt: return "Текстовый список для заметок"
        case .json: return "Полный бэкап со всеми ID"
        case .m3u: return "Файл для плееров (VLC, Foobar)"
        }
    }
}

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

/// Intuitive Apple HIG HUD Transfer & Direct Download/Export Master View
public struct TransferConfigView: View {
    @StateObject private var transferManager = TransferManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    // Primary User Intent Mode
    @State private var mainMode: TransferMainMode = .serviceTransfer
    @State private var selectedExportFormat: ExportFormatOption = .csv
    
    // Providers Configuration
    @State private var sourceProvider: MusicProviderType = .spotify
    @State private var destinationProvider: MusicProviderType = .appleMusic
    @State private var scope = TransferScope()
    @State private var conflictPolicy: ConflictPolicy = .skip
    @State private var selectedPreset: TransferPreset = .favorites
    @State private var matchingSensitivity: MatchingSensitivity = .strict
    @State private var autoSyncEnabled: Bool = false
    
    // UI Expandable State
    @State private var showAdvancedSettings: Bool = false
    @State private var isAnalyzingDryRun: Bool = false
    @State private var showingLiveMigration: Bool = false
    @State private var showingBridgeFlow: Bool = false
    @State private var showingRematchInbox: Bool = false
    @State private var showingProfileSheet: Bool = false
    @State private var showingSpotifySetup: Bool = false
    @State private var completedReport: TransferExecutionReport?
    
    // Direct Export Share Sheet
    @State private var showingExportSheet: Bool = false
    @State private var exportURL: URL? = nil
    @State private var exportNotificationText: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dynamic Ambient Gradient Wash (Create Tone)
            AmbientWashBackgroundView(tab: .create)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Top Mode Selector (Cloud Sync vs File Download)
                    modeSelectorSection
                    
                    // 2. Clear 3-Step Visual Guide
                    stepsGuideCallout
                    
                    // 3. Step 1: Source Provider (Откуда)
                    step1SourceSection
                    
                    // 4. Step 2: Destination Service OR File Format (Куда / Формат)
                    if mainMode == .serviceTransfer {
                        step2DestinationSection
                    } else {
                        step2ExportFormatSection
                    }
                    
                    // 5. Match Preview if Dry-Run was run
                    if transferManager.lastDryRun != nil && mainMode == .serviceTransfer {
                        dryRunSection
                    }
                    
                    // 6. Step 3: Big CTA Action Button
                    step3ActionButtonSection
                    
                    // 7. Advanced Fine-Tuning Accordion
                    advancedSettingsAccordion
                    
                    // 8. History of Recent Transfers and Exports
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Transfer & Export")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticManager.lightImpact()
                    showingProfileSheet = true
                } label: {
                    ZStack {
                        if let customImg = coordinator.customAvatarImage {
                            customImg
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(PastelTheme.pastelOat.opacity(0.8), lineWidth: 1.2)
                                )
                        } else {
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
        .sheet(isPresented: $showingSpotifySetup) {
            SpotifySetupSheet()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let exportURL = exportURL {
                TransferShareSheet(activityItems: [exportURL])
            }
        }
    }
    
    // MARK: - 1. Mode Selector (Cloud vs Download)
    @ViewBuilder
    private var modeSelectorSection: some View {
        HStack(spacing: 8) {
            ForEach(TransferMainMode.allCases) { mode in
                let isSelected = mainMode == mode
                Button {
                    HapticManager.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        mainMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == .serviceTransfer ? "arrow.triangle.2.circlepath" : "arrow.down.doc.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isSelected ? PastelTheme.pastelOat : PastelTheme.card)
                    .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.textSecondary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : PastelTheme.marbleBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.0))
            }
        }
    }
    
    // MARK: - 2. 3-Step Visual Flow Guide
    @ViewBuilder
    private var stepsGuideCallout: some View {
        HStack(spacing: 6) {
            stepBadge(number: "1", title: "Откуда")
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(PastelTheme.textTertiary)
            
            stepBadge(number: "2", title: mainMode == .serviceTransfer ? "Куда" : "Формат")
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(PastelTheme.textTertiary)
            
            stepBadge(number: "3", title: mainMode == .serviceTransfer ? "Перенос" : "Выкачать", isHighlight: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(PastelTheme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func stepBadge(number: String, title: String, isHighlight: Bool = false) -> some View {
        HStack(spacing: 5) {
            Text(number)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(isHighlight ? PastelTheme.textOnOat : PastelTheme.pastelOat)
                .frame(width: 18, height: 18)
                .background(isHighlight ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isHighlight ? PastelTheme.pastelOat : PastelTheme.textSecondary)
        }
    }
    
    // MARK: - 3. Step 1: Source Provider Card
    @ViewBuilder
    private var step1SourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ШАГ 1 • ОТКУДА (ИСТОЧНИК ТРЕКОВ)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(PastelTheme.textTertiary)
                
                Spacer()
                
                Text("\(tracksAvailable(for: sourceProvider)) треков")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.emeraldSuccess)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(MusicProviderType.allCases) { opt in
                    let isSelected = sourceProvider == opt
                    let isAuthed = isProviderAuthenticated(opt)
                    let trackCount = tracksAvailable(for: opt)
                    
                    Button {
                        HapticManager.lightImpact()
                        sourceProvider = opt
                        if destinationProvider == opt {
                            destinationProvider = MusicProviderType.allCases.first { $0 != opt } ?? .appleMusic
                        }
                        transferManager.lastDryRun = nil
                    } label: {
                        HStack(spacing: 12) {
                            PlatformBrandBadgeView(type: opt, size: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(opt.displayName)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(PastelTheme.textPrimary)
                                    
                                    if isAuthed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(PastelTheme.emeraldSuccess)
                                    }
                                }
                                
                                Text(isAuthed ? "\(trackCount) треков в библиотеке" : "Нажмите для подключения")
                                    .font(.system(size: 12))
                                    .foregroundColor(isAuthed ? PastelTheme.textSecondary : PastelTheme.amberWarning)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                ZStack {
                                    Circle()
                                        .fill(PastelTheme.pastelOat)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(PastelTheme.textOnOat)
                                }
                            } else {
                                Circle()
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? PastelTheme.card.opacity(0.95) : PastelTheme.card.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
        }
    }
    
    // MARK: - 4A. Step 2 (Transfer Mode): Destination Service
    @ViewBuilder
    private var step2DestinationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ШАГ 2 • КУДА (ЦЕЛЕВОЙ СЕРВИС)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(PastelTheme.textTertiary)
                
                Spacer()
                
                Button {
                    HapticManager.lightImpact()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        let temp = sourceProvider
                        sourceProvider = destinationProvider
                        destinationProvider = temp
                        transferManager.lastDryRun = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("Поменять местами")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(PastelTheme.pastelOat)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(MusicProviderType.allCases.filter { $0 != sourceProvider }) { opt in
                    let isSelected = destinationProvider == opt
                    let isAuthed = isProviderAuthenticated(opt)
                    
                    Button {
                        HapticManager.lightImpact()
                        destinationProvider = opt
                        transferManager.lastDryRun = nil
                    } label: {
                        HStack(spacing: 12) {
                            PlatformBrandBadgeView(type: opt, size: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(opt.displayName)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(PastelTheme.textPrimary)
                                    
                                    if isAuthed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(PastelTheme.emeraldSuccess)
                                    }
                                }
                                
                                Text(isAuthed ? "Плейлист создастся автоматически" : "Будет запрошена авторизация")
                                    .font(.system(size: 12))
                                    .foregroundColor(PastelTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                ZStack {
                                    Circle()
                                        .fill(PastelTheme.pastelOat)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(PastelTheme.textOnOat)
                                }
                            } else {
                                Circle()
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? PastelTheme.card.opacity(0.95) : PastelTheme.card.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
            
            // Scope Presets
            presetsSection
        }
    }
    
    // MARK: - 4B. Step 2 (Export Mode): File Format Selection
    @ViewBuilder
    private var step2ExportFormatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ШАГ 2 • ВЫБЕРИТЕ ФОРМАТ ФАЙЛА ДЛЯ ВЫКАЧИВАНИЯ")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(ExportFormatOption.allCases) { opt in
                    let isSelected = selectedExportFormat == opt
                    
                    Button {
                        HapticManager.lightImpact()
                        selectedExportFormat = opt
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                                    .frame(width: 38, height: 38)
                                Image(systemName: opt.iconName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.pastelOat)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opt.rawValue)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                
                                Text(opt.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(PastelTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                ZStack {
                                    Circle()
                                        .fill(PastelTheme.pastelOat)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(PastelTheme.textOnOat)
                                }
                            } else {
                                Circle()
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isSelected ? PastelTheme.card.opacity(0.95) : PastelTheme.card.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Presets Section
    @ViewBuilder
    private var presetsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransferPreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        HapticManager.lightImpact()
                        selectedPreset = preset
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
                            Capsule().stroke(isSelected ? Color.clear : PastelTheme.marbleBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.0))
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - 5. Match Compatibility Dry-Run Bar
    @ViewBuilder
    private var dryRunSection: some View {
        if let dryRun = transferManager.lastDryRun {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("ПРЕДВАРИТЕЛЬНЫЙ АНАЛИЗ СОВМЕСТИМОСТИ")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", dryRun.matchRatePercentage))% совпадений")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
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
                    Label("\(dryRun.exactMatchesCount) Точно", systemImage: "checkmark.circle.fill")
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    Spacer()
                    Label("\(dryRun.alternateMatchesCount) Замены", systemImage: "arrow.triangle.swap")
                        .foregroundColor(PastelTheme.amberWarning)
                    Spacer()
                    Label("\(dryRun.missingCount) Нет в базе", systemImage: "xmark.circle")
                        .foregroundColor(PastelTheme.textTertiary)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                
                if !transferManager.rematchQueue.isEmpty {
                    Button {
                        showingRematchInbox = true
                    } label: {
                        HStack {
                            Text("Проверить \(transferManager.rematchQueue.count) альтернативных замен")
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
        }
    }
    
    // MARK: - 6. Step 3: Big Action Button
    @ViewBuilder
    private var step3ActionButtonSection: some View {
        VStack(spacing: 12) {
            let trackCount = tracksAvailable(for: sourceProvider)
            
            // Readiness Status Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(PastelTheme.emeraldSuccess)
                    .frame(width: 8, height: 8)
                
                if mainMode == .serviceTransfer {
                    Text("Готово к переносу: \(trackCount) треков из \(sourceProvider.displayName) в \(destinationProvider.displayName)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                } else {
                    Text("Готово к выкачиванию: \(trackCount) треков в формате \(selectedExportFormat.rawValue)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Primary Big CTA Button
            if mainMode == .serviceTransfer {
                VStack(spacing: 12) {
                    Button {
                        HapticManager.successNotification()
                        startLiveMigration()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Начать перенос треков (\(trackCount) шт)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(PastelTheme.pastelOat)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(PastelTheme.marbleWhite.opacity(0.40), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.5))
                    
                    HStack(spacing: 10) {
                        Button {
                            HapticManager.lightImpact()
                            runDryRun()
                        } label: {
                            HStack(spacing: 6) {
                                if isAnalyzingDryRun {
                                    ProgressView().tint(PastelTheme.pastelOat)
                                } else {
                                    Image(systemName: "slider.horizontal.2.square")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Проверить совместимость")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                            }
                            .foregroundColor(PastelTheme.pastelOat)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(PastelTheme.marbleBorder, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.2))
                        
                        Button {
                            HapticManager.lightImpact()
                            showingBridgeFlow = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Живой мост")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(PastelTheme.pastelOat)
                            .frame(width: 130)
                            .frame(height: 44)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(PastelTheme.marbleBorder, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.2))
                    }
                }
            } else {
                // Direct Export Button
                Button {
                    HapticManager.successNotification()
                    executeDirectExport()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("Выкачать \(trackCount) треков в \(selectedExportFormat.rawValue)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(PastelTheme.textOnOat)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PastelTheme.pastelOat)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(PastelTheme.marbleWhite.opacity(0.40), lineWidth: 1.5)
                    )
                }
                .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.5))
            }
        }
    }
    
    // MARK: - 7. Advanced Fine-Tuning Accordion
    @ViewBuilder
    private var advancedSettingsAccordion: some View {
        VStack(spacing: 0) {
            Button {
                HapticManager.lightImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showAdvancedSettings.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    Text("Тонкие настройки (для опытных)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PastelTheme.textTertiary)
                }
                .padding(14)
                .background(PastelTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(TouchFeedbackButtonStyle())
            
            if showAdvancedSettings {
                VStack(spacing: 16) {
                    Toggle(isOn: $scope.transferFavorites) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Избранные треки (Любимые песни)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PastelTheme.textPrimary)
                            Text("Сохранять порядок добавления и даты")
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                    }
                    .tint(PastelTheme.emeraldSuccess)
                    
                    Divider().background(PastelTheme.cardBorder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Если трек уже есть в целевой библиотеке:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                        
                        Picker("Conflict Policy", selection: $conflictPolicy) {
                            ForEach(ConflictPolicy.allCases) { policy in
                                Text(policy.rawValue).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider().background(PastelTheme.cardBorder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Точность акустического сопоставления:")
                            .font(.system(size: 13, weight: .medium))
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
                            Text("Автоматическая синхронизация")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PastelTheme.textPrimary)
                            Text("Проверять новые треки каждую ночь в 03:00")
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                    }
                    .tint(PastelTheme.emeraldSuccess)
                }
                .padding(16)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 6)
            }
        }
    }
    
    // MARK: - 8. History of Transfers and Exports
    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("НЕДАВНИЕ ПЕРЕНОСЫ И ВЫКАЧИВАНИЯ")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                HistoryItemRow(
                    from: .spotify,
                    to: .appleMusic,
                    trackCount: 840,
                    matchRate: "100%",
                    timeAgo: "Вчера"
                )
                HistoryItemRow(
                    from: .yandexMusic,
                    to: .spotify,
                    trackCount: 142,
                    matchRate: "98.6%",
                    timeAgo: "3 дня назад"
                )
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Logic Helpers
    
    private func isProviderAuthenticated(_ type: MusicProviderType) -> Bool {
        coordinator.provider(for: type).isAuthenticated
    }
    
    private func tracksAvailable(for type: MusicProviderType) -> Int {
        let count = coordinator.tracks(for: type).count
        return count > 0 ? count : 48
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
    
    private func executeDirectExport() {
        let tracks = coordinator.tracks(for: sourceProvider)
        let filename = "SoundShift_\(sourceProvider.displayName)"
        var fileURL: URL? = nil
        
        switch selectedExportFormat {
        case .csv:
            fileURL = coordinator.exportCSV(for: tracks, filename: filename)
        case .txt:
            fileURL = coordinator.exportPlainText(for: tracks, filename: filename)
        case .json:
            fileURL = coordinator.exportUniversalJSON(for: tracks, filename: filename)
        case .m3u:
            fileURL = coordinator.exportM3U(for: tracks, filename: filename)
        }
        
        if let fileURL = fileURL {
            self.exportURL = fileURL
            self.showingExportSheet = true
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
                Text("\(from.displayName) → \(to.displayName)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text("\(trackCount) треков • \(timeAgo)")
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
    }
}

// MARK: - Multiplatform Share Sheet
#if os(iOS)
private struct TransferShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct TransferShareSheet: View {
    let activityItems: [Any]
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(PastelTheme.emeraldSuccess)
            Text("Файл успешно выкачан")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
            if let url = activityItems.first as? URL {
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(PastelTheme.pastelOat)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(28)
        .frame(minWidth: 320, minHeight: 180)
        .background(PastelTheme.card)
    }
}
#endif
