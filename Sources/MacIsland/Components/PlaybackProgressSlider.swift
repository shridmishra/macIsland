import SwiftUI

// MARK: - PlaybackProgressSlider
// Scannable, elegant playback progress bar matching Apple Dynamic Island styling:
// [Current Time]  [==== Progress Bar ====]  [-Remaining Time]
public struct PlaybackProgressSlider: View {
    public let progress: Double
    public let currentTimeString: String
    public let remainingTimeString: String
    
    public init(progress: Double, currentTimeString: String, remainingTimeString: String) {
        self.progress = progress
        self.currentTimeString = currentTimeString
        self.remainingTimeString = remainingTimeString
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Elapsed time indicator
            Text(currentTimeString)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.68))
                .lineLimit(1)
            
            // Horizontal progress capsule
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.20))
                        .frame(height: 3.5)
                    
                    // Filled active progress
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 3.5)
                }
                .frame(height: 3.5)
                .offset(y: (geo.size.height - 3.5) / 2.0)
            }
            .frame(height: 14)
            
            // Remaining time indicator (e.g. -1:15:05)
            Text(remainingTimeString)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.68))
                .lineLimit(1)
        }
    }
}
