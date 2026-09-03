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
                // Mini album artwork
                ArtworkImageView(artworkData: item.artworkData, size: 22, cornerRadius: 6)
                
                // Track title (compact)
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Animated audio visualizer bars
                AudioWaveformIndicator(isPlaying: isPlaying)
            } else {
                // Idle state: subtle indicator pill
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.islandTextSecondary)
                
                Text("Mac Island")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.islandTextSecondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            WindowManager.shared.expand()
        }
    }
}
