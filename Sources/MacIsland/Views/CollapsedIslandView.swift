import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// Hugs the top screen or camera notch unobtrusively, revealing just enough visual feedback
// (mini artwork, track title, and lively equalizer bars) without blocking the screen.
public struct CollapsedIslandView: View {
    public let item: MediaItem?
    public let isPlaying: Bool
    
    public init(item: MediaItem?, isPlaying: Bool) {
        self.item = item
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            if let item = item {
                // Mini album artwork or fallback glyph
                ArtworkImageView(artworkData: item.artworkData, size: 20, cornerRadius: 5)
                
                // Track title (compact)
                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 110, alignment: .leading)
                
                Spacer(minLength: 0)
                
                // Animated audio visualizer bars
                AudioWaveformIndicator(isPlaying: isPlaying)
            } else {
                // Idle state: subtle indicator pill
                Circle()
                    .fill(Color.islandTextTertiary)
                    .frame(width: 6, height: 6)
                
                Text("Mac Island")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.islandTextSecondary)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .contentShape(Rectangle())
        .onTapGesture {
            WindowManager.shared.expand()
        }
    }
}
