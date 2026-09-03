import SwiftUI
import AppKit

// MARK: - PlaybackProgressSlider
// Scannable, interactive playback progress scrubber matching Apple Dynamic Island styling.
// Implements advanced SwiftUI gesture handling:
// - DragGesture with minimumDistance: 0 for instant scrubbing response
// - Tactile thumb indicator that blooms smoothly on drag
// - Jitter-free monospaced digits (.monospacedDigit())
// - Physical Force Touch haptic pulse on scrub interaction
public struct PlaybackProgressSlider: View {
    public let progress: Double
    public let currentTimeString: String
    public let remainingTimeString: String
    public var onSeek: ((Double) -> Void)?
    
    @State private var isDragging = false
    @State private var scrubProgress: Double = 0.0
    
    public init(
        progress: Double,
        currentTimeString: String,
        remainingTimeString: String,
        onSeek: ((Double) -> Void)? = nil
    ) {
        self.progress = progress
        self.currentTimeString = currentTimeString
        self.remainingTimeString = remainingTimeString
        self.onSeek = onSeek
    }
    
    private var displayProgress: Double {
        isDragging ? scrubProgress : progress
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // Elapsed time indicator with fixed-width tabular numbers
            Text(currentTimeString)
                .font(.system(size: 11.5, weight: .regular))
                .monospacedDigit()
                .foregroundColor(Color.white.opacity(0.55))
                .lineLimit(1)
            
            // Interactive scrubber capsule with drag tracking
            GeometryReader { geo in
                let width = geo.size.width
                let currentWidth = max(0, min(width * CGFloat(displayProgress), width))
                
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: isDragging ? 5 : 4)
                        .animation(.easeInOut(duration: 0.15), value: isDragging)
                    
                    // Filled active progress (white line)
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: currentWidth, height: isDragging ? 5 : 4)
                        .animation(isDragging ? nil : .linear(duration: 0.25), value: currentWidth)
                    
                    // Scrub thumb indicator visible on drag
                    if isDragging {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
                            .offset(x: max(0, min(currentWidth - 5, width - 10)))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 14)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                            }
                            let newProgress = max(0.0, min(1.0, Double(value.location.x / width)))
                            scrubProgress = newProgress
                        }
                        .onEnded { value in
                            let finalProgress = max(0.0, min(1.0, Double(value.location.x / width)))
                            scrubProgress = finalProgress
                            isDragging = false
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                            onSeek?(finalProgress)
                        }
                )
                .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            .frame(height: 14)
            
            // Remaining time indicator with fixed-width tabular numbers
            Text(remainingTimeString)
                .font(.system(size: 11.5, weight: .regular))
                .monospacedDigit()
                .foregroundColor(Color.white.opacity(0.55))
                .lineLimit(1)
        }
    }
}
