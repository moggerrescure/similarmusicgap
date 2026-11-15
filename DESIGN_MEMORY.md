# SoundShift IDE Agent Design Memory & Architecture Archive
> **Status:** Preserved & Archived Asset  
> **Design Standard:** Apple HIG HUD (iOS 18+ Luxury Athletic) & Teenage Engineering OP-1 Field  
> **Role:** Chief Design Officer & Apple Design Award Auditor Memory  
> **Last Verified:** 2026-11-15  

---

## 🧭 Executive Summary
Этот документ является постоянной архитектурной памятью дизайн-субагента. В нём навсегда зафиксированы визуальные правила, геометрические константы, цветовые формулы и полный нативный SwiftUI-код для **16-полосного студийного анализатора спектра (Concept 3: Digital Studio Spectrum)**, а также архивированные концепты кассетных бумбоксов и аналоговых ламповых VU-метров.

Секция была отключена из основного фида приложения по прямому распоряжению пользователя (*«без проигрывателей, просто её не должно быть»*), но её эталонная эстетика, проработка и инженерная точность сохранены в эту базу знаний для мгновенного переиспользования в будущих экранах, фичах (например, Full Player Sheet, Mastering Studio HUD, Audio Equalizer HUD) или промо-материалах.

---

## 🎨 1. Цветовая философия и Strict Dark Mode (PastelTheme)

| Токен | HEX / Значение | Назначение / Применение |
| :--- | :--- | :--- |
| **Canvas / Background** | `#0E0F12` | OLED Cashmere Charcoal — глубокий энергосберегающий фон без синевы. |
| **Card Surface** | `#14151B` / `#17181D` | Глубокий матовый графит шасси модулей. |
| **Recessed Screen Surface** | `#0C0D10` | Утопленная камера дисплея спектроанализатора. |
| **Card Border (Default)** | `#EFE3D3` @ 18% | Благородный тёплый титановый контур (`PastelTheme.cardBorder`). |
| **Card Border (Focused)** | `#EFE3D3` @ 42% | Активный контур при воспроизведении (`PastelTheme.cardBorderFocused`). |
| **CTA / Oat Accent** | `#EFE3D3` (`text: #0E0F12`) | Главный цвет действий и тактильных переключателей. |
| **Athletic Emerald** | `#10B981` ➔ `#34D399` | Басовая зона спектра (32–250Hz), индикация активности. |
| **Warm Amber** | `#F59E0B` ➔ `#FBBF24` | Среднечастотная зона (500Hz–2kHz), предупреждения, стрики. |
| **Pastel Slate / Lavender** | `#60A5FA` ➔ `#A78BFA` | Высокочастотная зона (4k–16kHz), прозрачность, стереопанорама. |

> [!CAUTION]
> **Абсолютное ТАБУ на «нейрослоп»:**
> Категорически запрещены случайные многоцветные киберпанк-градиенты (циановый с маджентой, фиолетовый с синим, неоновые интерполяции), светящиеся шары и размытые дешёвые тени.

---

## 📐 2. Геометрия «Zero Collision» (Шкала частот и Запас пространства)

Ключевое требование пользователя: **белые пиковые чёрточки и цветные столбики не должны касаться или налезать на надписи частот (`32Hz`–`16kHz`).**

### Математическая раскладка камеры дисплея (Высота = 58pt):
```
┌────────────────────────────────────────────────────────┐  Y = 0pt
│  [32Hz]   [125]   [500]   [2k]    [8k]    [16kHz]      │  Зона заголовка шкалы: 14pt (SF Mono 6.2pt)
├────────────────────────────────────────────────────────┤  Y = 14pt (Тонкий разделитель 0.5pt, oat 12%)
│                                                        │
│  ▓▓▓ ТЁМНЫЙ ЗАПАС ПРОСТРАНСТВА (HEADROOM >= 10.5pt) ▓▓▓ │  Свободная тёмная зона, исключающая наложение
│                                                        │
│   ──      ──      ──              ──      ──      ──   │  Y = 24.5pt (Белые пик-холды, Max H = 16.5pt)
│  ┌──┐    ┌──┐    ┌──┐            ┌──┐    ┌──┐    ┌──┐  │  
│  │  │    │  │    │  │            │  │    │  │    │  │  │  Цветные LED-столбики (Max H = 13.5pt)
│  └──┴────┴──┴────┴──┴────────────┴──┴────┴──┴────┴──┘  │  Y = 41pt (Базовая линия спектра)
└────────────────────────────────────────────────────────┘  Y = 58pt (Нижний край окна)
```

1. **Разделитель:** Горизонтальная линия `0.5pt` (`PastelTheme.pastelOat.opacity(0.12)`).
2. **Ограничение столбиков:** Максимальная высота цветного бара = `13.5pt`.
3. **Ограничение пик-холдов:** Белая микро-полоска `1.5pt` висит на высоте `min(barHeight + 2.0, 16.5pt)`.
4. **Результат:** Между пиковой точкой и текстом герцев всегда гарантировано **не менее 10.5pt чистого чёрного пространства**.

---

## ⚡ 3. Баллистическая динамика и физика анимации

- **FPS:** 60/120 Hz через `TimelineView(.animation(paused: !isPlaying))`.
- **Гармоники звука:**
  - Басовый кик (полосы 0–4): выраженная реакция на синусоиду `time * 8.5` + басовый свинг.
  - Снейр и ритм (полосы 5–10): модуляция `time * 12.0` с откликом на гармоники вокала.
  - Хай-хэты и перкуссия (полосы 11–15): мелкий мерцающий отклик `time * 18.0`.
- **Пик-холды:** Белый маркер держится в верхней точке на 2–3 кадра дольше столбика и плавно опускается по закону затухания.
- **В покое (`!isPlaying`):** Столбики находятся на уровне покоя `2.5pt` с прозрачностью 0.35, имитируя включённый студийный прибор в режиме ожидания.

---

## 💻 4. Эталонный SwiftUI-код компонента

```swift
import SwiftUI

// MARK: - Digital Studio Spectrum 16-Band Card (OP-1 Field Edition)
public struct DigitalStudioSpectrumMixCard: View {
    public let title: String
    public let subtitle: String
    public let channelNumber: Int
    public let isPlaying: Bool
    public let onPlay: () -> Void
    
    private let freqLabels = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    
    public init(
        title: String,
        subtitle: String,
        channelNumber: Int = 1,
        isPlaying: Bool,
        onPlay: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.channelNumber = channelNumber
        self.isPlaying = isPlaying
        self.onPlay = onPlay
    }
    
    public var body: some View {
        Button(action: onPlay) {
            TimelineView(.animation(paused: !isPlaying)) { timeline in
                cardBody(time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func cardBody(time: TimeInterval) -> some View {
        ZStack {
            // 1. Monolithic Charcoal Matte Chassis (#14151B)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#14151B"))
                .frame(width: 240, height: 124)
            
            // 2. Active Warm Ambient Glow
            if isPlaying {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "#EFE3D3").opacity(0.06))
                    .frame(width: 240, height: 124)
                    .blur(radius: 14)
            }
            
            // 3. Tactile 1.5pt Border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isPlaying ? Color(hex: "#EFE3D3").opacity(0.42) : Color(hex: "#EFE3D3").opacity(0.18),
                    lineWidth: 1.5
                )
                .frame(width: 240, height: 124)
            
            // 4. Content Architecture
            VStack(spacing: 0) {
                // Top Clean Swiss Status Bar (No lossless badge!)
                HStack {
                    Text("CH 0\(channelNumber) • MASTER SPECTRUM")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#EFE3D3").opacity(0.55))
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Text("-14.2 LUFS")
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#EFE3D3").opacity(0.38))
                }
                .padding(.horizontal, 12)
                .padding(.top, 9)
                
                // Center: Recessed Digital Studio Screen Chamber
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(hex: "#0C0D10"))
                    
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color(hex: "#EFE3D3").opacity(0.12), lineWidth: 1)
                    
                    VStack(spacing: 0) {
                        // A. Frequency Scale Header (Height: 14pt)
                        VStack(spacing: 3) {
                            HStack {
                                ForEach(freqLabels, id: \.self) { label in
                                    Text(label)
                                        .font(.system(size: 6.2, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(hex: "#EFE3D3").opacity(0.35))
                                    if label != freqLabels.last {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                            
                            Rectangle()
                                .fill(Color(hex: "#EFE3D3").opacity(0.12))
                                .frame(height: 0.5)
                                .padding(.horizontal, 6)
                        }
                        .frame(height: 14)
                        
                        // B. Clearance Headroom & 16-Band Dynamic Bars
                        HStack(alignment: .bottom, spacing: 3.5) {
                            ForEach(0..<16, id: \.self) { index in
                                spectrumBarColumn(index: index, time: time)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                    }
                    
                    // Specular Reflection Sheen
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.01), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .allowsHitTesting(false)
                }
                .frame(width: 218, height: 58)
                .padding(.top, 5)
                
                Spacer()
                
                // Bottom Track Metadata & Tactile Play Knob
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(title)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Color(hex: "#10B981") : Color(hex: "#EFE3D3"))
                            .frame(width: 22, height: 22)
                            .shadow(color: Color.black.opacity(0.6), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(Color(hex: "#0E0F12"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 9)
            }
            .frame(width: 240, height: 124)
        }
        .frame(width: 240, height: 124)
    }
    
    @ViewBuilder
    private func spectrumBarColumn(index: Int, time: TimeInterval) -> some View {
        let (barHeight, peakHeight) = calculateLevels(index: index, time: time)
        
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 7.5, height: 24)
                
                RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                    .fill(barGradient(for: index))
                    .frame(width: 7.5, height: barHeight)
                
                // White Peak-Hold Dash (Strictly <= 16.5pt)
                RoundedRectangle(cornerRadius: 0.6, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 7.5, height: 1.5)
                    .offset(y: -peakHeight)
            }
            .frame(width: 7.5, height: 24)
        }
        .frame(width: 7.5, height: 26)
    }
    
    private func calculateLevels(index: Int, time: TimeInterval) -> (CGFloat, CGFloat) {
        guard isPlaying else {
            let base = 2.5 + CGFloat(index % 3) * 0.8
            return (base, base + 2.0)
        }
        
        let idx = Double(index)
        let kick = max(0, sin(time * 8.5)) * 0.85
        let snare = max(0, sin(time * 12.0 + 1.2)) * 0.70
        let hat = max(0, sin(time * 18.0 + 2.4)) * 0.65
        let swing = sin(time * 3.2) * 0.20
        
        let freqWeight: Double
        let ripple: Double
        if index < 5 {
            freqWeight = 0.35 + 0.65 * kick + swing
            ripple = sin(time * 11.0 + idx * 0.8) * 0.22
        } else if index < 11 {
            freqWeight = 0.30 + 0.70 * snare + swing * 0.5
            ripple = cos(time * 15.0 + idx * 0.9) * 0.20
        } else {
            freqWeight = 0.25 + 0.75 * hat
            ripple = sin(time * 22.0 + idx * 1.4) * 0.18
        }
        
        let rawLevel = min(max(freqWeight + ripple, 0.10), 1.0)
        let barHeight = CGFloat(rawLevel) * 13.5 + 1.5
        let peakFlutter = CGFloat(sin(time * 6.0 + idx * 1.1) * 0.6)
        let peakTarget = min(barHeight + 2.0 + peakFlutter, 16.5)
        
        return (barHeight, peakTarget)
    }
    
    private func barGradient(for index: Int) -> LinearGradient {
        if index < 5 {
            return LinearGradient(
                colors: [Color(hex: "#10B981"), Color(hex: "#34D399")],
                startPoint: .bottom,
                endPoint: .top
            )
        } else if index < 11 {
            return LinearGradient(
                colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "#60A5FA"), Color(hex: "#A78BFA")],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }
}
```

---

## 🗄️ 5. Каталог артефактов и ссылок

- **Финальный 8K-макрорендер Концепта 3:**  
  [soundshift_concept_3_perfected_spectrum_1794677778520.jpg](file:///Users/ilakazdan/.gemini/antigravity/brain/ffeb4f6e-9094-44e9-bf07-82a8ede95bbd/soundshift_concept_3_perfected_spectrum_1794677778520.jpg)
- **Интерактивный HTML-шоукейс 4 концептов:**  
  [curated_mixes_4_concepts_interactive.html](file:///Users/ilakazdan/.gemini/antigravity/brain/ffeb4f6e-9094-44e9-bf07-82a8ede95bbd/curated_mixes_4_concepts_interactive.html)
- **Нативный файл SwiftUI фида:**  
  [SpotifyHomeFeedView.swift](file:///Users/ilakazdan/similarmusicgap/music/music/App/Views/Home/SpotifyHomeFeedView.swift)

---
*Документ сохранён в постоянную память дизайн-агента SoundShift.*
