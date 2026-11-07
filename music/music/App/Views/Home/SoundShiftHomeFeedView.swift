import SwiftUI

/// SoundShift Next-Gen Acoustic Command Deck (Apple HIG HUD Luxury Athletic Standard)
/// Replaces generic Spotify clone with a bespoke multi-service acoustic cockpit.
public struct SoundShiftHomeFeedView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    @State private var showingProfileSheet: Bool = false
    @State private var showingServicesSheet: Bool = false
    @State private var showingDuplicatesSheet: Bool = false
    @State private var showingStoryReceiptSheet: Bool = false
    @State private var selectedVibeIndex: Int = 0
    @State private var equalizerPhase: CGFloat = 0.0
    
    // Dynamic Greeting based on time of day
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }
    
    // Vibe Presets (Zero emojis, high-contrast SF symbols)
    private struct AcousticVibe: Identifiable {
        let id: Int
        let title: String
        let bpmBadge: String
        let systemImage: String
        let accentColor: Color
    }
    
    private let vibes: [AcousticVibe] = [
        AcousticVibe(id: 0, title: "Пиковый драйв", bpmBadge: "140+ BPM", systemImage: "bolt.fill", accentColor: PastelTheme.emeraldSuccess),
        AcousticVibe(id: 1, title: "Глубокий фокус", bpmBadge: "432 Гц", systemImage: "brain.head.profile", accentColor: PastelTheme.slateBlue),
        AcousticVibe(id: 2, title: "Ночной поток", bpmBadge: "Bass & Synth", systemImage: "moon.stars.fill", accentColor: PastelTheme.warmAmber),
        AcousticVibe(id: 3, title: "Шелковый чилл", bpmBadge: "Lo-Fi Flow", systemImage: "sparkles", accentColor: PastelTheme.lavenderAI)
    ]
    
    // Curated Vaults Model
    private struct CuratedVault: Identifiable {
        let id: Int
        let title: String
        let trackCount: Int
        let subtitle: String
        let systemImage: String
        let accentColor: Color
    }
    
    private let curatedVaults: [CuratedVault] = [
        CuratedVault(id: 1, title: "Lossless Originals", trackCount: 128, subtitle: "Hi-Res FLAC Master", systemImage: "waveform.badge.exclamationmark", accentColor: PastelTheme.emeraldSuccess),
        CuratedVault(id: 2, title: "Night Drive Vault", trackCount: 64, subtitle: "Синхронизировано", systemImage: "car.fill", accentColor: PastelTheme.warmAmber),
        CuratedVault(id: 3, title: "Liked Cross-Platform", trackCount: 412, subtitle: "3 сервиса объединены", systemImage: "heart.fill", accentColor: PastelTheme.pastelOat),
        CuratedVault(id: 4, title: "Workout Hyperdrive", trackCount: 85, subtitle: "140+ BPM Резонанс", systemImage: "figure.run", accentColor: PastelTheme.lavenderAI)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Strict Dark Mode Background (#0E0F12)
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // 1. Top HUD Header (Avatar, greeting, cloud status cluster - without ping)
                        headerHUD
                            .padding(.top, 10)
                        
                        // 2. Hero: Acoustic Resonance Deck
                        heroResonanceDeck
                        
                        // 3. Cross-Cloud Audio Bridge
                        crossCloudBridgeCard
                        
                        // 4. Acoustic State Selector (Vibe frequencies)
                        acousticVibeSelector
                        
                        // 5. Curated Sound Vaults
                        curatedSoundVaultsShelf
                        
                        // 6. Viral Retention Hook: Daily Acoustic Receipt
                        dailyAcousticReceiptCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Clearance for 56pt mini player + tab bar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
            .sheet(isPresented: $showingServicesSheet) {
                ServicesHubView()
            }
            .sheet(isPresented: $showingDuplicatesSheet) {
                DuplicatesInspectorView(duplicates: DuplicatesEngine.shared.findDuplicates(in: coordinator.allTracks))
            }
            .sheet(isPresented: $showingStoryReceiptSheet) {
                TasteCardStoryView(profile: TasteAnalyticsEngine.shared.analyzeLibrary(tracks: coordinator.allTracks))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    equalizerPhase = CGFloat(Double.pi * 2.0)
                }
            }
        }
    }
    
    // MARK: - 1. Header HUD (Without ping latency indicators, zero emojis)
    private var headerHUD: some View {
        HStack(alignment: .center, spacing: 12) {
            // User Avatar (Opens Profile Sheet)
            Button {
                HapticManager.lightImpact()
                showingProfileSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(PastelTheme.cardSubtle)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    
                    if let avatar = coordinator.customAvatarImage {
                        avatar
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Text Title & Greeting
            VStack(alignment: .leading, spacing: 2) {
                Text("SOUNDSHIFT MATRIX")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(PastelTheme.textTertiary)
                
                Text("\(timeGreeting), Илья")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Cloud Services Connection Cluster (Without ping latency)
            Button {
                HapticManager.lightImpact()
                showingServicesSheet = true
            } label: {
                HStack(spacing: 7) {
                    // Spotify Status Dot
                    serviceBadge(name: "Spotify", isConnected: coordinator.spotify.isAuthenticated, color: PastelTheme.emeraldSuccess)
                    
                    // Apple Music Status Dot
                    serviceBadge(name: "Apple", isConnected: coordinator.appleMusic.isAuthenticated, color: PastelTheme.pastelOat)
                    
                    // Yandex Music Status Dot
                    serviceBadge(name: "Яндекс", isConnected: coordinator.yandexMusic.isAuthenticated, color: PastelTheme.warmAmber)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PastelTheme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func serviceBadge(name: String, isConnected: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? color : PastelTheme.textTertiary.opacity(0.35))
                .frame(width: 6, height: 6)
            
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isConnected ? PastelTheme.textPrimary : PastelTheme.textTertiary)
        }
    }
    
    // MARK: - 2. Hero: Acoustic Resonance Deck (Apple HIG HUD)
    private var heroResonanceDeck: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row with live flow pill
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("АКУСТИЧЕСКИЙ РЕЗОНАНС")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(PastelTheme.pastelOat)
                    
                    Text("Ежедневный индекс нейро-потока")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                
                Spacer()
                
                // Live status capsule
                HStack(spacing: 5) {
                    Circle()
                        .fill(PastelTheme.emeraldSuccess)
                        .frame(width: 6, height: 6)
                    
                    Text("LIVE FLOW")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(PastelTheme.emeraldSuccess)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PastelTheme.cardSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            
            // Metric and telemetry row
            HStack(alignment: .bottom, spacing: 18) {
                // Large 34pt Monospaced Score
                Text("94%")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(PastelTheme.textPrimary)
                    .contentTransition(.numericText())
                
                VStack(alignment: .leading, spacing: 4) {
                    telemetryChip(label: "BPM", value: "138", color: PastelTheme.emeraldSuccess)
                    telemetryChip(label: "Тональность", value: "Фа минор", color: PastelTheme.slateBlue)
                    telemetryChip(label: "Состояние", value: "Deep Flow", color: PastelTheme.warmAmber)
                }
                
                Spacer()
            }
            
            // Dynamic Live Equalizer Bars
            dynamicEqualizerBars
                .frame(height: 28)
            
            // Primary Porcelain Oat CTA Button
            Button {
                HapticManager.lightImpact()
                if let _ = player.currentTrack {
                    player.togglePlayPause()
                } else if let firstTrack = coordinator.allTracks.first {
                    player.play(track: firstTrack, in: coordinator.allTracks)
                } else {
                    player.togglePlayPause()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    
                    Text(player.isPlaying ? "Приостановить поток" : "Возобновить поток")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(PastelTheme.textOnOat)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(PastelTheme.pastelOat)
                .clipShape(Capsule())
                .shadow(color: PastelTheme.pastelOat.opacity(0.2), radius: 10, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(18)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private func telemetryChip(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            
            Text("\(label):")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(PastelTheme.textTertiary)
            
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
        }
    }
    
    private var dynamicEqualizerBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<18, id: \.self) { index in
                let pD = Double(equalizerPhase)
                let heightFactor = (sin(pD * 1.8 + Double(index) * 0.45) * 0.45 + 0.55)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor(for: index))
                    .frame(width: 3.5, height: max(4.0, CGFloat(heightFactor) * 26.0))
            }
            Spacer(minLength: 0)
        }
    }
    
    private func barColor(for index: Int) -> Color {
        if index % 3 == 0 {
            return PastelTheme.pastelOat.opacity(0.85)
        } else if index % 3 == 1 {
            return PastelTheme.emeraldSuccess.opacity(0.80)
        } else {
            return PastelTheme.slateBlue.opacity(0.70)
        }
    }
    
    // MARK: - 3. Cross-Cloud Audio Bridge
    private var crossCloudBridgeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(PastelTheme.pastelOat)
                
                Text("ОБЛАЧНЫЙ АУДИО-ШЛЮЗ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(PastelTheme.pastelOat)
                
                Spacer()
                
                Text("Синхронизировано")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PastelTheme.emeraldSuccess)
            }
            
            // Telemetry Grid
            HStack(spacing: 12) {
                // Column 1: Total tracks count
                VStack(alignment: .leading, spacing: 3) {
                    Text(coordinator.allTracks.isEmpty ? "4 820" : "\(coordinator.allTracks.count)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    Text("Единый каталог")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
                
                // Column 2: Connected Gateways
                VStack(alignment: .leading, spacing: 3) {
                    Text("3 / 3")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    
                    Text("Активные сервисы")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            
            // 2 Oval Action Buttons with Marble-White Hairline Border
            HStack(spacing: 10) {
                // Button 1: Quick Transfer (Navigates to Create tab)
                Button {
                    HapticManager.lightImpact()
                    navCoordinator.navigateTo(tab: .create)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.arrow.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Быстрый перенос")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(PastelTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Button 2: Duplicates Inspector
                Button {
                    HapticManager.lightImpact()
                    showingDuplicatesSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Дубликаты")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(PastelTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - 4. Acoustic State Selector (Vibe Frequencies)
    private var acousticVibeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("АКУСТИЧЕСКИЕ ЧАСТОТЫ")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.0)
                .foregroundColor(PastelTheme.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vibes) { vibe in
                        let isSelected = selectedVibeIndex == vibe.id
                        Button {
                            HapticManager.lightImpact()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedVibeIndex = vibe.id
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: vibe.systemImage)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(vibe.accentColor)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(vibe.title)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSelected ? PastelTheme.textPrimary : PastelTheme.textSecondary)
                                    
                                    Text(vibe.bpmBadge)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(vibe.accentColor.opacity(0.85))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? PastelTheme.cardBorderFocused.opacity(0.12) : PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - 5. Curated Sound Vaults Shelf
    private var curatedSoundVaultsShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("АКТИВНЫЕ ХРАНИЛИЩА")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(PastelTheme.textSecondary)
                
                Spacer()
                
                Button {
                    HapticManager.lightImpact()
                    navCoordinator.navigateTo(tab: .library)
                } label: {
                    HStack(spacing: 4) {
                        Text("Библиотека")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(PastelTheme.pastelOat)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(curatedVaults) { vault in
                        Button {
                            HapticManager.lightImpact()
                            if let firstTrack = coordinator.allTracks.first {
                                player.play(track: firstTrack, in: coordinator.allTracks)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(vault.accentColor.opacity(0.16))
                                            .frame(width: 34, height: 34)
                                        
                                        Image(systemName: vault.systemImage)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(vault.accentColor)
                                    }
                                    
                                    Spacer()
                                    
                                    // Play icon indicator
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(PastelTheme.pastelOat.opacity(0.65))
                                }
                                
                                Spacer(minLength: 0)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vault.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(PastelTheme.textPrimary)
                                        .lineLimit(1)
                                    
                                    Text("\(vault.trackCount) треков • \(vault.subtitle)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(14)
                            .frame(width: 190, height: 118)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - 6. Daily Acoustic Receipt Card (Viral Retention Hook)
    private var dailyAcousticReceiptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(PastelTheme.pastelOat)
                
                Text("АКУСТИЧЕСКИЙ СЛЕД ДНЯ")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(PastelTheme.pastelOat)
                
                Spacer()
                
                Text("Сегодня")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PastelTheme.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("2.4 ч прослушивания")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text("38 400 ударов сердца в резонансе • Доминант: Электроника")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
            }
            
            // Share Button (Oval, marble border)
            Button {
                HapticManager.lightImpact()
                showingStoryReceiptSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .bold))
                    
                    Text("Открыть Stories-паспорт")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(PastelTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(PastelTheme.cardSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
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
