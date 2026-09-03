import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Maps and displays the true streaming media service (Prime Video, Netflix, YouTube, Spotify)
// even when audio/video is playing inside browsers like Brave, Chrome, Safari, or Arc.
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject private var windowManager = WindowManager.shared
    
    public init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if let item = mediaManager.currentItem {
                // Top row: Album Artwork + Track Details (Title & Artist) + Animated Waveform Equalizer
                HStack(alignment: .center, spacing: 14) {
                    ArtworkImageView(item: item, size: 52, cornerRadius: 13)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        // Track Title
                        Text(item.displayTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.islandTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Artist name
                        Text(item.artist.isEmpty ? item.effectiveAppName : item.artist)
                            .font(.system(size: 13.5, weight: .regular))
                            .foregroundColor(Color.islandScrubberMuted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 5-bar animated waveform equalizer matching reference design
                    AudioWaveformIndicator(
                        isPlaying: mediaManager.playbackState.isPlaying,
                        color: Color.islandWaveformPeach,
                        barCount: 5
                    )
                }
                
                // Middle row: Single-row Scrubber with elapsed & negative remaining time
                PlaybackProgressSlider(
                    progress: mediaManager.interpolatedProgress,
                    currentTimeString: mediaManager.formattedCurrentTime,
                    remainingTimeString: mediaManager.formattedRemainingTime
                )
                
                // Bottom row: Centered flat white controls (Previous, Play/Pause, Next) + AirPods icon
                MediaControlButtons(
                    isPlaying: mediaManager.playbackState.isPlaying,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() }
                )
            } else {
                // Empty state when no media is playing system-wide
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color.islandTextTertiary)
                    
                    Text("No Media Playing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.islandTextSecondary)
                    
                    Text("Play audio in Apple Music, Spotify, or your browser")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.islandTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 14)
    }
}
