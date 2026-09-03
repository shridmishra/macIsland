import SwiftUI

// MARK: - AudioWaveformIndicator
// Minimalist, Apple-style animated audio visualizer bars.
// Shown in the collapsed Dynamic Island to give immediate visual feedback that audio is playing.
public struct AudioWaveformIndicator: View {
    public let isPlaying: Bool
    public let color: Color
    public let barCount: Int
    
    @State private var phase: CGFloat = 0
    
    public init(isPlaying: Bool, color: Color = Color.islandWaveformPeach, barCount: Int = 5) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
    }
    
    // Bar configuration: height multipliers and phase offsets
    private let barConfigs: [(multiplier: CGFloat, offset: CGFloat, resting: CGFloat)] = [
        (0.55, 0.1, 4.0),
        (0.85, 0.4, 7.5),
        (1.00, 0.7, 12.0),
        (0.80, 0.2, 7.0),
        (0.50, 0.5, 4.0)
    ]
    
    public var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(0..<min(barCount, barConfigs.count), id: \.self) { index in
                let config = barConfigs[index]
                bar(multiplier: config.multiplier, offset: config.offset, resting: config.resting)
            }
        }
        .frame(height: 16)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                startAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    phase = 0
                }
            }
        }
    }
    
    @ViewBuilder
    private func bar(multiplier: CGFloat, offset: CGFloat, resting: CGFloat) -> some View {
        let normalizedPhase = isPlaying ? (sin(phase + offset * .pi * 2) + 1.0) / 2.0 : 0.0
        let dynamicHeight = isPlaying ? max(3.5, normalizedPhase * 13.0 * multiplier + 3.0) : resting
        
        Capsule()
            .fill(color)
            .frame(width: 2.5, height: dynamicHeight)
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
            phase = .pi * 2
        }
    }
}
