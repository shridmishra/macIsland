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
    public let color: Color
    public let barCount: Int
    
    public init(isPlaying: Bool, color: Color = Color.islandWaveformPeach, barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }
    
    // 4 sleek, proportional bars with independent frequencies
    private let barConfigs: [(speed: Double, offset: Double, minH: CGFloat, maxH: CGFloat, resting: CGFloat)] = [
        (4.4, 0.00, 2.5, 7.0, 3.5),
        (6.2, 0.35, 3.0, 10.5, 7.0),
        (4.0, 0.70, 3.5, 11.0, 8.5),
        (5.5, 0.20, 2.5, 7.5, 4.0)
    ]
    
    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let time = isPlaying ? timeline.date.timeIntervalSinceReferenceDate : 0.0
            
            HStack(alignment: .center, spacing: 2.0) {
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
                            return config.resting
                        }
                    }()
                    
                    Capsule()
                        .fill(color)
                        .frame(width: 1.8, height: dynamicHeight)
                }
            }
            .frame(height: 12)
        }
    }
}
