import SwiftUI

// MARK: - PlaybackProgressSlider
// Scannable, elegant playback progress bar matching Apple macOS styling.
// Displays the elapsed time, horizontal progress capsule, and total duration.
public struct PlaybackProgressSlider: View {
    public let progress: Double
    public let currentTimeString: String
    public let durationString: String
    
    public init(progress: Double, currentTimeString: String, durationString: String) {
        self.progress = progress
        self.currentTimeString = currentTimeString
        self.durationString = durationString
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Horizontal progress capsule
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.islandProgressTrack)
                        .frame(height: 3.5)
                    
                    // Filled active progress
                    Capsule()
                        .fill(Color.islandTextPrimary.opacity(0.85))
                        .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 3.5)
                }
            }
            .frame(height: 3.5)
            
            // Time indicators
            HStack {
                Text(currentTimeString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.islandTextTertiary)
                
                Spacer()
                
                Text(durationString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.islandTextTertiary)
            }
        }
    }
}
