import SwiftUI

// MARK: - AudioWaveformIndicator
// Sleek, ultra-refined minimalist audio visualizer matching Apple Dynamic Island aesthetic.
// Key refinements:
// - 4 delicate hairline bars (1.8pt width, 2.0pt spacing) eliminating previous bulkiness
// - Organic dual-harmonic musical motion running on TimelineView
// - Pauses timeline completely when not playing (0% idle CPU)
// - Dynamic brand color matching when playing, muted translucent resting bars when paused
public struct AudioWaveformIndicator: View {
    public let isPlaying: Bool
    public let colors: [Color]
    public let barCount: Int
    
    public init(
        isPlaying: Bool,
        colors: [Color] = [Color.islandWaveformPeach],
        barCount: Int = 4
    ) {
        self.isPlaying = isPlaying
        self.colors = colors.isEmpty ? [Color.islandWaveformPeach] : colors
        self.barCount = barCount
    }
    
    // Convenience init for single color backward compatibility
    public init(isPlaying: Bool, color: Color, barCount: Int = 4) {
        self.init(isPlaying: isPlaying, colors: [color], barCount: barCount)
    }
    
    // 4 sleek, proportional bars with independent frequencies
    private let barConfigs: [(speed: Double, offset: Double, minH: CGFloat, maxH: CGFloat)] = [
        (4.4, 0.00, 2.5, 7.0),
        (6.2, 0.35, 3.0, 10.5),
        (4.0, 0.70, 3.5, 11.0),
        (5.5, 0.20, 2.5, 7.5)
    ]
    
    public static let barWidth: CGFloat = 1.8
    public static let barSpacing: CGFloat = 2.0
    public static let restingBarHeight: CGFloat = 2.4
    
    public var intrinsicWidth: CGFloat {
        let count = min(barCount, barConfigs.count)
        guard count > 0 else { return 0 }
        return CGFloat(count) * Self.barWidth + CGFloat(count - 1) * Self.barSpacing
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
            let time = isPlaying ? timeline.date.timeIntervalSinceReferenceDate : 0.0
            // Subtle, physical fluid shimmer across the gradient when playing
            let flow = isPlaying ? CGFloat(sin(time * 1.2)) * 0.06 : 0.0
            let start = UnitPoint(x: 0.0 + flow, y: 0.2 - flow * 0.4)
            let end = UnitPoint(x: 1.0 + flow, y: 0.8 + flow * 0.4)
            
            let vibrantColors: [Color] = {
                if colors.count >= 2 {
                    return colors
                } else if let single = colors.first {
                    return [single.opacity(0.85), single, single.opacity(0.95), single.opacity(0.75)]
                } else {
                    return [Color.islandWaveformPeach, Color.islandWaveformPeach]
                }
            }()
            
            ZStack {
                // Muted resting state: 100% clean translucent monochrome silver/gray (zero color tint)
                LinearGradient(
                    colors: [Color.islandWaveformMutedSecondary, Color.islandWaveformMuted],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isPlaying ? 0.0 : 1.0)
                
                // Active playing state: Dynamic vibrant gradient matching artwork/service colors
                LinearGradient(
                    colors: vibrantColors,
                    startPoint: start,
                    endPoint: end
                )
                .opacity(isPlaying ? 1.0 : 0.0)
            }
            .animation(.easeInOut(duration: 0.30), value: isPlaying)
            .mask(
                HStack(alignment: .center, spacing: Self.barSpacing) {
                    ForEach(0..<min(barCount, barConfigs.count), id: \.self) { index in
                        let config = barConfigs[index]
                        let dynamicHeight: CGFloat = {
                            if isPlaying {
                                // Organic dual-harmonic sine synthesis for natural musical pulsing
                                let wave1 = sin(time * config.speed + config.offset * .pi * 2)
                                let wave2 = cos(time * (config.speed * 0.7) + config.offset)
                                let normalized = (wave1 * 0.6 + wave2 * 0.4 + 1.0) / 2.0
                                return config.minH + (config.maxH - config.minH) * CGFloat(normalized)
                            } else {
                                // Calm baseline resting height: flatline indicating silence / paused
                                return Self.restingBarHeight
                            }
                        }()
                        
                        Capsule()
                            .frame(width: Self.barWidth, height: dynamicHeight)
                            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isPlaying)
                    }
                }
            )
            .frame(width: intrinsicWidth, height: 12)
        }
        .frame(width: intrinsicWidth, height: 12)
    }
}
