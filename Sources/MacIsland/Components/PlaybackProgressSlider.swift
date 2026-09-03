import SwiftUI

// MARK: - PlaybackProgressSlider
// Scannable, elegant playback progress bar matching Apple macOS styling.
// Displays the elapsed time, horizontal progress capsule, and total duration.
public struct PlaybackProgressSlider: View {
    public let progress: Double
    public let currentTimeString: String
    public let remainingTimeString: String
    
    public init(progress: Double, currentTimeString: String, remainingTimeString: String) {
        self.progress = progress
        self.currentTimeString = currentTimeString
        self.remainingTimeString = remainingTimeString
    }
    
    public init(progress: Double, currentTimeString: String, durationString: String) {
        self.progress = progress
        self.currentTimeString = currentTimeString
        self.remainingTimeString = durationString
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Elapsed time indicator (e.g. "0:54")
            Text(currentTimeString)
                .font(.system(size: 11.5, weight: .regular))
                .monospacedDigit()
                .foregroundColor(Color.islandScrubberMuted)
                .frame(minWidth: 28, alignment: .leading)
            
            // Scrubber capsule bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.islandProgressTrack)
                        .frame(height: 4.5)
                    
                    // Filled active progress
                    Capsule()
                        .fill(Color.islandScrubberFill)
                        .frame(
                            width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)),
                            height: 4.5
                        )
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 4.5)
            
            // Remaining time indicator (e.g. "-3:15")
            Text(remainingTimeString)
                .font(.system(size: 11.5, weight: .regular))
                .monospacedDigit()
                .foregroundColor(Color.islandScrubberMuted)
                .frame(minWidth: 32, alignment: .trailing)
        }
        .frame(height: 14)
    }
}
