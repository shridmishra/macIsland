import SwiftUI

// MARK: - LyricsDisplayView
// Sleek, right-aligned synchronized lyrics line display for the expanded island header bar.
// Replaces the audio waveform pulse when lyrics mode is enabled.
// Features:
// - Musical note indicator and real-time active lyric line
// - Apple Music-style dynamic interlude dots during instrumental breaks or song intros
// - Smooth vertical slide and fade transitions when the active lyric line changes
// - Resilient loading and fallback states
public struct LyricsDisplayView: View {
    @ObservedObject var lyricsManager = LyricsManager.shared
    public let isPlaying: Bool
    
    public init(isPlaying: Bool = true) {
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if lyricsManager.isLoading {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 12, height: 12)
                
                Text("Loading...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.islandTextTertiary)
            } else if let line = lyricsManager.currentLine, !line.text.isEmpty {
                // Musical note indicator
                Image(systemName: "music.note")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.islandTextTertiary)
                
                // Synchronized active singing line
                Text(line.text)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .id("\(line.id.uuidString)-\(line.text)")
                    .transition(.lyricBlurSlide)
            } else if lyricsManager.hasLyrics {
                // Musical intro or instrumental interlude before line begins
                HStack(spacing: 3) {
                    Circle().fill(Color.islandTextTertiary).frame(width: 3, height: 3)
                    Circle().fill(Color.islandTextTertiary).frame(width: 3, height: 3)
                    Circle().fill(Color.islandTextTertiary).frame(width: 3, height: 3)
                }
                .padding(.horizontal, 4)
            } else {
                Text("No lyrics")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Color.islandTextTertiary)
            }
        }
        .frame(maxWidth: 170, alignment: .trailing)
        .animation(IslandAnimation.lyricsSpring, value: lyricsManager.currentLine?.id)
        .animation(IslandAnimation.lyricsSpring, value: lyricsManager.currentLine?.text)
        .animation(IslandAnimation.snappySpring, value: lyricsManager.isLoading)
    }
}
