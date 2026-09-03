import SwiftUI

// MARK: - AudioWaveformIndicator
// High-performance, GPU-driven animated audio visualizer bars using SwiftUI TimelineView.
// Features:
// - Multi-harmonic organic waveform oscillation (independent frequencies per bar)
// - Pauses timeline completely when not playing (0% idle CPU)
// - Dynamic brand color matching when playing, muted resting bars when paused
public struct AudioWaveformIndicator: View {
    public let isPlaying: Bool
    public let color: Color
    public let barCount: Int
    
    public init(isPlaying: Bool, color: Color = Color.islandWaveformPeach, barCount: Int = 5) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }
    
    // Bar configuration: speeds, phase offsets, min/max heights, resting heights
    private let barConfigs: [(speed: Double, offset: Double, minH: CGFloat, maxH: CGFloat, resting: CGFloat)] = [
        (4.2, 0.0, 3.5, 9.5, 4.0),
        (5.8, 0.3, 4.0, 14.5, 7.5),
        (3.7, 0.7, 5.0, 16.0, 12.0),
        (6.4, 0.2, 4.0, 13.5, 7.0),
        (4.9, 0.5, 3.5, 9.0, 4.0)
    ]
    
    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let time = isPlaying ? timeline.date.timeIntervalSinceReferenceDate : 0.0
            
            HStack(alignment: .center, spacing: 2.5) {
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
                        .frame(width: 2.5, height: dynamicHeight)
                }
            }
            .frame(height: 16)
        }
    }
}
