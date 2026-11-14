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

public enum MatchingSensitivity: String, CaseIterable, Identifiable {
    case strict = "Strict"
    case flexible = "Flexible"
    public var id: String { rawValue }
    
    public var helpText: String {
        switch self {
        case .strict:
            return "Only auto-accepts exact codes (ISRC) or very high-confidence matches. Ambiguous songs go to Rematch Inbox — safer for large libraries."
        case .flexible:
            return "Also auto-accepts close title/artist matches. Faster, but open the report afterward in case a wrong song slipped through."
        }
    }
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
    @State private var selectedPreset: TransferPresetKind = .favorites
    @State private var matchingSensitivity: MatchingSensitivity = .strict
    @State private var customPlaylistName: String = ""
    
    // Source Archive Track Selection State
    @State private var selectedTrackIds: Set<UUID> = []
    @State private var trackSearchText: String = ""
    @State private var isArchiveExpanded: Bool = true
    
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
                    // 0. Live readiness (P0 gates)
                    transferReadinessBanner
                    
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
                    
                    // 5. Source Tracks Archive & Granular Selection
                    sourceTracksArchiveSection
                    
                    // 6. Match Preview if Dry-Run was run
                    if transferManager.lastDryRun != nil && mainMode == .serviceTransfer {
                        dryRunSection
                    }
                    
                    // 7. Step 3: Big CTA Action Button
                    step3ActionButtonSection
                    
                    // 7. Advanced Fine-Tuning Accordion
                    advancedSettingsAccordion
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(MigratorChrome.moveTabTitle)
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
        .onAppear {
            transferManager.applyMatchingSensitivity(matchingSensitivity)
            if selectedTrackIds.isEmpty {
                applyPreset(selectedPreset)
            }
        }
        .task {
            await coordinator.syncIfNeededWhileVisible()
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
                ForEach(MusicProviderType.availableConnectors) { opt in
                    let isSelected = sourceProvider == opt
                    let isAuthed = isProviderAuthenticated(opt)
                    let trackCount = tracksAvailable(for: opt)
                    
                    Button {
                        HapticManager.lightImpact()
                        if !isAuthed {
                            Task { await ensureAuthenticated(opt) }
                            return
                        }
                        sourceProvider = opt
                        selectedTrackIds = Set(coordinator.tracks(for: opt).map(\.id))
                        trackSearchText = ""
                        if destinationProvider == opt {
                            destinationProvider = MusicProviderType.availableConnectors.first { $0 != opt } ?? .appleMusic
                        }
                        transferManager.invalidateDryRunPreview()
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
                        selectedTrackIds = Set(coordinator.tracks(for: sourceProvider).map(\.id))
                        trackSearchText = ""
                        transferManager.invalidateDryRunPreview()
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
                ForEach(MusicProviderType.availableConnectors.filter { $0 != sourceProvider }) { opt in
                    let isSelected = destinationProvider == opt
                    let isAuthed = isProviderAuthenticated(opt)
                    
                    Button {
                        HapticManager.lightImpact()
                        if !isAuthed {
                            Task { await ensureAuthenticated(opt) }
                            return
                        }
                        destinationProvider = opt
                        transferManager.invalidateDryRunPreview()
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
                ForEach(TransferPresetKind.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        HapticManager.lightImpact()
                        selectedPreset = preset
                        applyPreset(preset)
                        transferManager.invalidateDryRunPreview()
                    } label: {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(preset.displayName)
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
    
    // MARK: - 4.5. Source Track Archive & Selection Section
    @ViewBuilder
    private var sourceTracksArchiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Step Label + Platform Badge + Live Selection Counter
            HStack {
                HStack(spacing: 6) {
                    Text("ШАГ 2.5 • АРХИВ ТРЕКОВ И ВЫБОР")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    PlatformBrandBadgeView(type: sourceProvider, size: 14)
                }
                
                Spacer()
                
                Text("Выбрано \(selectedTrackIds.count) из \(sourceTracks.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTrackIds.isEmpty ? PastelTheme.amberWarning : PastelTheme.emeraldSuccess)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            
            // Action Toolbar: Select All / Deselect All + Collapse / Expand
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    // "Select All" / "Deselect All" Capsule Button
                    Button {
                        toggleSelectAll()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedTrackIds.count == sourceTracks.count ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .bold))
                            Text(selectedTrackIds.count == sourceTracks.count ? "Снять все" : "Выбрать все (\(sourceTracks.count))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedTrackIds.count == sourceTracks.count ? PastelTheme.textOnOat : PastelTheme.pastelOat)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTrackIds.count == sourceTracks.count ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    
                    Spacer()
                    
                    // Collapse/Expand Toggle
                    Button {
                        HapticManager.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isArchiveExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isArchiveExpanded ? "Свернуть" : "Развернуть")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                            Image(systemName: isArchiveExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(PastelTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
                
                // Search Field (when expanded)
                if isArchiveExpanded {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        TextField("Поиск по трекам архива...", text: $trackSearchText)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .tint(PastelTheme.pastelOat)
                            .autocorrectionDisabled()
                        
                        if !trackSearchText.isEmpty {
                            Button {
                                HapticManager.lightImpact()
                                trackSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            // Track List
            if isArchiveExpanded {
                if filteredSourceTracks.isEmpty {
                    Text("В архиве нет подходящих треков")
                        .font(.system(size: 13))
                        .foregroundColor(PastelTheme.textTertiary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredSourceTracks) { track in
                            sourceTrackRow(track: track)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func sourceTrackRow(track: UniversalTrack) -> some View {
        let isSelected = selectedTrackIds.contains(track.id)
        
        return Button {
            toggleTrackSelection(id: track.id)
        } label: {
            HStack(spacing: 12) {
                // Interactive Checkbox (Загорается чистым белым цветом при выборе)
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .shadow(color: Color.white.opacity(0.45), radius: 6, x: 0, y: 0)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(Color.black)
                    } else {
                        Circle()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(width: 32, height: 32)
                
                // Track Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? PastelTheme.textPrimary : PastelTheme.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(track.primaryArtist)
                            .foregroundColor(PastelTheme.textSecondary)
                        if let album = track.album, !album.isEmpty {
                            Text("•")
                                .foregroundColor(PastelTheme.textTertiary)
                            Text(album)
                                .foregroundColor(PastelTheme.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    .font(.system(size: 12))
                }
                
                Spacer()
                
                // Duration, strictly aligned on the same horizontal level across every row
                Text(formatDuration(track.durationMs))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(PastelTheme.textTertiary)
                    .monospacedDigit()
                    .frame(height: 32, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? PastelTheme.card.opacity(0.9) : PastelTheme.cardSubtle.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? PastelTheme.cardBorderFocused : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 5. Match Compatibility Dry-Run Bar
    @ViewBuilder
    private var dryRunSection: some View {
        if let dryRun = transferManager.lastDryRun {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("PREVIEW — NOTHING WRITTEN YET")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    Spacer()
                    
                    Text("\(dryRun.exactMatchesCount)/\(dryRun.totalTracks) ready")
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
                    Label("\(dryRun.exactMatchesCount) Ready", systemImage: "checkmark.circle.fill")
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    Spacer()
                    Label("\(dryRun.alternateMatchesCount) Decide", systemImage: "arrow.triangle.swap")
                        .foregroundColor(PastelTheme.amberWarning)
                    Spacer()
                    Label("\(dryRun.missingCount) Missing", systemImage: "xmark.circle")
                        .foregroundColor(PastelTheme.textTertiary)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                
                Text("Ready = safe auto-match. Decide = open Rematch Inbox. Missing = not found on destination yet.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PastelTheme.textTertiary)
                
                if !transferManager.rematchQueue.isEmpty {
                    Button {
                        showingRematchInbox = true
                    } label: {
                        HStack {
                            Text("Review \(transferManager.rematchQueue.count) alternate matches")
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
            let trackCount = selectedTrackIds.count
            let hasSelection = trackCount > 0
            
            // Readiness Status Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(hasSelection ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
                    .frame(width: 8, height: 8)
                
                if mainMode == .serviceTransfer {
                    Text(hasSelection ? "Готово к переносу: \(trackCount) треков из \(sourceProvider.displayName) в \(destinationProvider.displayName)" : "Выберите треки для переноса в архиве выше")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                } else {
                    Text(hasSelection ? "Готово к выкачиванию: \(trackCount) треков в формате \(selectedExportFormat.rawValue)" : "Выберите треки для выкачивания в архиве выше")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if !transferManager.statusMessage.isEmpty {
                Text(transferManager.statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(PastelTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let err = transferManager.lastErrorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Primary Big CTA Button
            if mainMode == .serviceTransfer {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Playlist name on \(destinationProvider.displayName)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textTertiary)
                        TextField(
                            PlaylistNameBuilder.resolve(custom: nil, source: sourceProvider),
                            text: $customPlaylistName
                        )
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                        .accessibilityIdentifier("transfer.playlist_name")
                        Text("Leave empty for “SoundShift · from \(sourceProvider.displayName)”.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    
                    let rematchBlocking = TransferRematchGate.blocksMigrate(
                        pendingRematchCount: transferManager.rematchQueue.count,
                        isStrict: matchingSensitivity == .strict
                    )
                    if rematchBlocking {
                        Button {
                            showingRematchInbox = true
                        } label: {
                            Text("Resolve \(transferManager.rematchQueue.count) Rematch decision\(transferManager.rematchQueue.count == 1 ? "" : "s") first")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.amberWarning)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("transfer.rematch_gate")
                    }
                    
                    Button {
                        guard hasSelection, !rematchBlocking else { return }
                        HapticManager.successNotification()
                        startLiveMigration()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(
                                rematchBlocking
                                ? "Open Rematch Inbox first"
                                : (hasSelection ? "Начать перенос треков (\(trackCount) шт)" : "Выберите треки для переноса")
                            )
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(hasSelection && !rematchBlocking ? PastelTheme.textOnOat : PastelTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(hasSelection && !rematchBlocking ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(hasSelection && !rematchBlocking ? PastelTheme.marbleWhite.opacity(0.40) : PastelTheme.cardBorder, lineWidth: 1.5)
                        )
                    }
                    .disabled(!hasSelection || rematchBlocking)
                    .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.5))
                    .accessibilityIdentifier("transfer.start_migrate")
                    
                    HStack(spacing: 10) {
                        Button {
                            guard hasSelection else { return }
                            HapticManager.lightImpact()
                            runDryRun()
                        } label: {
                            HStack(spacing: 6) {
                                if isAnalyzingDryRun {
                                    ProgressView().tint(PastelTheme.pastelOat)
                                } else {
                                    Image(systemName: "slider.horizontal.2.square")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Dry-run match preview")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                            }
                            .foregroundColor(hasSelection ? PastelTheme.pastelOat : PastelTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(hasSelection ? PastelTheme.marbleBorder : PastelTheme.cardBorder.opacity(0.4), lineWidth: 1.2)
                            )
                        }
                        .disabled(!hasSelection)
                        .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.2))
                        .accessibilityIdentifier("transfer.dry_run")
                        
                        Button {
                            guard hasSelection, !rematchBlocking else {
                                if rematchBlocking { showingRematchInbox = true }
                                return
                            }
                            HapticManager.lightImpact()
                            startLiveMigration(preferBridge: true)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Живой мост")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(
                                hasSelection && !rematchBlocking && !transferManager.isMigrating
                                ? PastelTheme.pastelOat
                                : PastelTheme.textTertiary
                            )
                            .frame(width: 130)
                            .frame(height: 44)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        hasSelection && !rematchBlocking && !transferManager.isMigrating
                                            ? PastelTheme.marbleBorder
                                            : PastelTheme.cardBorder.opacity(0.4),
                                        lineWidth: 1.2
                                    )
                            )
                        }
                        .disabled(!hasSelection || rematchBlocking || transferManager.isMigrating)
                        .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.2))
                        .accessibilityIdentifier("transfer.live_bridge")
                    }
                }
            } else {
                // Direct Export Button
                Button {
                    guard hasSelection else { return }
                    HapticManager.successNotification()
                    executeDirectExport()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(hasSelection ? "Выкачать \(trackCount) треков в \(selectedExportFormat.rawValue)" : "Выберите треки для выкачивания")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(hasSelection ? PastelTheme.textOnOat : PastelTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(hasSelection ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(hasSelection ? PastelTheme.marbleWhite.opacity(0.40) : PastelTheme.cardBorder, lineWidth: 1.5)
                    )
                }
                .disabled(!hasSelection)
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Если трек уже есть в целевой библиотеке:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                        
                        Picker("Conflict Policy", selection: $conflictPolicy) {
                            ForEach(ConflictPolicy.implementedCases) { policy in
                                Text(policy.rawValue).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(conflictPolicy.description)
                            .font(.system(size: 11))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    
                    Divider().background(PastelTheme.cardBorder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How strict should matching be?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                        
                        Picker("Matching Sensitivity", selection: $matchingSensitivity) {
                            ForEach(MatchingSensitivity.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: matchingSensitivity) { _, newValue in
                            transferManager.applyMatchingSensitivity(newValue)
                            transferManager.invalidateDryRunPreview()
                        }
                        
                        Text(matchingSensitivity.helpText)
                            .font(.system(size: 11))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    
                    Divider().background(PastelTheme.cardBorder)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("In-app library sync")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PastelTheme.textPrimary)
                            Text("Refreshes when you open Create, Library, or Connect — only while the app is on screen. No background sync.")
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.textSecondary)
                            Button {
                                Task { await coordinator.syncIfNeededWhileVisible(force: true) }
                            } label: {
                                Text(coordinator.isSyncing ? "Syncing…" : "Sync now")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.pastelOat)
                            }
                            .disabled(coordinator.isSyncing)
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityIdentifier("transfer.sync_now")
                        }
                    }
                }
                .padding(16)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 6)
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private var sourceIsLive: Bool {
        coordinator.provider(for: sourceProvider).isLiveSession
    }
    
    private var destinationIsLive: Bool {
        coordinator.provider(for: destinationProvider).isLiveSession
    }
    
    private var transferBlockingReason: String? {
        if sourceProvider == .spotify || destinationProvider == .spotify {
            if !SpotifyConfig.isConfigured {
                return "Add Spotify Client ID in Connect → Spotify setup (Redirect URI: soundshift://spotify-callback)."
            }
        }
        if !isProviderAuthenticated(sourceProvider) || !isProviderAuthenticated(destinationProvider) {
            return "Connect both source and destination with live accounts."
        }
        if coordinator.spotify.isUsingDemoData && (sourceProvider == .spotify || destinationProvider == .spotify) {
            return "Spotify is in Demo Mode — disconnect and reconnect with a real Client ID. Demo cannot migrate."
        }
        if !sourceIsLive {
            return "\(sourceProvider.displayName) is not a live session."
        }
        if !destinationIsLive {
            return "\(destinationProvider.displayName) is not live. On Simulator, Apple Music library is often empty — use a physical iPhone."
        }
        if sourceTracks.isEmpty {
            return "No synced tracks for \(sourceProvider.displayName). Tap Sync on Connect, then return here."
        }
        return nil
    }
    
    private var transferReadinessBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIVE TRANSFER CHECKLIST")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
            
            readinessRow(
                ok: SpotifyConfig.isConfigured || (sourceProvider != .spotify && destinationProvider != .spotify),
                text: SpotifyConfig.isConfigured ? "Spotify Client ID configured" : "Spotify Client ID required for Spotify hops"
            )
            readinessRow(
                ok: isProviderAuthenticated(sourceProvider) && sourceIsLive,
                text: "Source \(sourceProvider.displayName): \(sourceIsLive ? "LIVE" : (isProviderAuthenticated(sourceProvider) ? "Demo / not live" : "Not connected"))"
            )
            readinessRow(
                ok: isProviderAuthenticated(destinationProvider) && destinationIsLive,
                text: "Destination \(destinationProvider.displayName): \(destinationIsLive ? "LIVE" : (isProviderAuthenticated(destinationProvider) ? "Not live" : "Not connected"))"
            )
            readinessRow(
                ok: !sourceTracks.isEmpty,
                text: sourceTracks.isEmpty ? "Sync library first (0 tracks)" : "\(sourceTracks.count) synced source tracks"
            )
            
            if let reason = transferBlockingReason {
                Text(reason)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PastelTheme.amberWarning)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Ready — dry-run then migrate. Writes a new playlist only (no Liked Songs).")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PastelTheme.emeraldSuccess)
            }
            
            HStack(spacing: 10) {
                Button {
                    NavigationCoordinator.shared.navigateToConnect()
                } label: {
                    Text("Open Connect")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textOnOat)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(PastelTheme.pastelOat)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    Task { await coordinator.syncAll() }
                } label: {
                    Text(coordinator.isSyncing ? "Syncing…" : "Sync now")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.pastelOat)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(coordinator.isSyncing)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private func readinessRow(ok: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ok ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(PastelTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }
    
    private var likedSourceTracks: [UniversalTrack] {
        coordinator.tracks(for: sourceProvider)
    }
    
    private var sourcePlaylists: [UniversalPlaylist] {
        coordinator.allPlaylists.filter { $0.providerType == sourceProvider }
    }
    
    /// Archive rows for the active preset (Favorites ≠ Full Vault).
    private var sourceTracks: [UniversalTrack] {
        TransferPresetResolver.tracks(
            preset: selectedPreset,
            likedTracks: likedSourceTracks,
            playlists: sourcePlaylists
        )
    }
    
    private var filteredSourceTracks: [UniversalTrack] {
        let query = trackSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return sourceTracks
        }
        return sourceTracks.filter {
            $0.title.lowercased().contains(query) ||
            $0.primaryArtist.lowercased().contains(query) ||
            ($0.album?.lowercased().contains(query) ?? false)
        }
    }
    
    private func toggleSelectAll() {
        HapticManager.lightImpact()
        if selectedTrackIds.count == sourceTracks.count {
            selectedTrackIds.removeAll()
        } else {
            selectedTrackIds = Set(sourceTracks.map(\.id))
        }
        transferManager.invalidateDryRunPreview()
    }
    
    private func toggleTrackSelection(id: UUID) {
        HapticManager.lightImpact()
        if selectedTrackIds.contains(id) {
            selectedTrackIds.remove(id)
        } else {
            selectedTrackIds.insert(id)
        }
        transferManager.invalidateDryRunPreview()
    }
    
    private func formatDuration(_ ms: Int) -> String {
        let totalSeconds = max(0, ms / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func isProviderAuthenticated(_ type: MusicProviderType) -> Bool {
        coordinator.provider(for: type).isAuthenticated
    }
    
    private func tracksAvailable(for type: MusicProviderType) -> Int {
        coordinator.tracks(for: type).count
    }
    
    private func ensureAuthenticated(_ type: MusicProviderType) async {
        if type == .spotify && !SpotifyConfig.isConfigured {
            showingSpotifySetup = true
            return
        }
        if type == .yandexMusic {
            if coordinator.yandexMusic.isLiveSession {
                await coordinator.syncIfNeededWhileVisible(force: true)
            } else {
                NavigationCoordinator.shared.openYandexConnect()
            }
            if type == sourceProvider {
                selectedTrackIds = Set(coordinator.tracks(for: type).map(\.id))
            }
            return
        }
        await coordinator.authenticate(type: type)
        if type == sourceProvider {
            selectedTrackIds = Set(coordinator.tracks(for: type).map(\.id))
        }
    }
    
    private func applyPreset(_ preset: TransferPresetKind) {
        let selection = TransferPresetResolver.resolve(
            preset: preset,
            likedTracks: likedSourceTracks,
            playlists: sourcePlaylists
        )
        scope.transferFavorites = selection.transferFavorites
        scope.selectedPlaylistIds = selection.playlistIds
        selectedTrackIds = selection.trackIds
    }
    
    private func runDryRun() {
        if let reason = transferBlockingReason {
            if !SpotifyConfig.isConfigured && (sourceProvider == .spotify || destinationProvider == .spotify) {
                showingSpotifySetup = true
            }
            transferManager.lastErrorMessage = reason
            transferManager.statusMessage = reason
            return
        }
        guard !selectedTrackIds.isEmpty else { return }
        isAnalyzingDryRun = true
        transferManager.applyMatchingSensitivity(matchingSensitivity)
        transferManager.clearRematchDecisions()
        var dryRunScope = scope
        dryRunScope.selectedTrackIds = selectedTrackIds
        Task {
            if sourceTracks.isEmpty {
                await coordinator.syncAll()
                selectedTrackIds = Set(coordinator.tracks(for: sourceProvider).map(\.id))
            }
            if let reason = transferBlockingReason {
                transferManager.lastErrorMessage = reason
                transferManager.statusMessage = reason
                isAnalyzingDryRun = false
                return
            }
            _ = await transferManager.executeDryRun(
                sourceType: sourceProvider,
                destinationType: destinationProvider,
                scope: dryRunScope
            )
            isAnalyzingDryRun = false
        }
    }
    
    private func startLiveMigration(preferBridge: Bool = false) {
        if let reason = transferBlockingReason {
            if !SpotifyConfig.isConfigured && (sourceProvider == .spotify || destinationProvider == .spotify) {
                showingSpotifySetup = true
            }
            transferManager.lastErrorMessage = reason
            transferManager.statusMessage = reason
            return
        }
        guard !selectedTrackIds.isEmpty else { return }
        transferManager.applyMatchingSensitivity(matchingSensitivity)
        transferManager.destinationPlaylistName = customPlaylistName
        var migrationScope = scope
        migrationScope.selectedTrackIds = selectedTrackIds
        // Honor the Advanced toggle — Favorites preset only pre-selects tracks via applyPreset.
        migrationScope.transferFavorites = scope.transferFavorites
        Task {
            if sourceTracks.isEmpty {
                await coordinator.syncAll()
                selectedTrackIds = Set(coordinator.tracks(for: sourceProvider).map(\.id))
                migrationScope.selectedTrackIds = selectedTrackIds
            }
            if let reason = transferBlockingReason {
                transferManager.lastErrorMessage = reason
                transferManager.statusMessage = reason
                return
            }
            if preferBridge {
                showingBridgeFlow = true
            } else {
                showingLiveMigration = true
            }
            let report = await transferManager.startMigration(
                sourceType: sourceProvider,
                destinationType: destinationProvider,
                scope: migrationScope,
                policy: conflictPolicy
            )
            showingLiveMigration = false
            showingBridgeFlow = false
            completedReport = report
        }
    }
    
    private func executeDirectExport() {
        let allTracks = coordinator.tracks(for: sourceProvider)
        let tracks = allTracks.filter { selectedTrackIds.contains($0.id) }
        guard !tracks.isEmpty else { return }
        let filename = "SoundShift_\(sourceProvider.displayName)_\(tracks.count)_tracks"
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
