import SwiftUI

// MARK: - AudioWaveformIndicator
// Minimalist, Apple-style animated audio visualizer bars.
// Shown in the collapsed Dynamic Island to give immediate visual feedback that audio is playing.
public struct AudioWaveformIndicator: View {
    public let isPlaying: Bool
    public let color: Color
    
    @State private var phase: CGFloat = 0
    
    public init(isPlaying: Bool, color: Color = Color.islandAccent) {
        self.isPlaying = isPlaying
        self.color = color
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            bar(multiplier: 0.8, offset: 0.0)
            bar(multiplier: 1.0, offset: 0.3)
            bar(multiplier: 0.6, offset: 0.6)
            bar(multiplier: 0.9, offset: 0.2)
        }
        .frame(height: 14)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                startAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    phase = 0
                }
            }
        }
    }
    
    @ViewBuilder
    private func bar(multiplier: CGFloat, offset: CGFloat) -> some View {
        let normalizedPhase = isPlaying ? (sin(phase + offset * .pi * 2) + 1.0) / 2.0 : 0.2
        let height = max(3.0, normalizedPhase * 12.0 * multiplier)
        
        Capsule()
            .fill(color)
            .frame(width: 2.5, height: height)
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            phase = .pi
        }
    }
}
