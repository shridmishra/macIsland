import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Pixel-perfect replica of the reference Dynamic Island layout:
// - Header: Artwork + Track Title + Subtitle + Animated Waveform
// - Scrubber: Elapsed Time + Progress Capsule + Negative Remaining Time
// - Controls: Centered Previous / Frameless Play-Pause / Next + AirPods Route Icon
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject private var windowManager = WindowManager.shared
    
    public init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        VStack(spacing: 13) {
            if let item = mediaManager.currentItem {
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator
                HStack(alignment: .center, spacing: 12) {
                    ArtworkImageView(item: item, size: 46, cornerRadius: 10)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        // Title
                        Text(item.displayTitle)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Subtitle: Service name (Prime Video, YouTube, Netflix, Spotify) or Artist
                        Text(item.effectiveAppName)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Waveform Audio Equalizer on the top-right
                    AudioWaveformIndicator(
                        isPlaying: mediaManager.playbackState.isPlaying,
                        color: Color(red: 0.95, green: 0.58, blue: 0.42)
                    )
                }
                
                // Middle section: Scannable horizontal progress bar with timestamps
                PlaybackProgressSlider(
                    progress: mediaManager.interpolatedProgress,
                    currentTimeString: mediaManager.formattedCurrentTime,
                    remainingTimeString: mediaManager.formattedRemainingTime
                )
                
                // Bottom section: Centered Playback controls + AirPods Route icon
                MediaControlButtons(
                    isPlaying: mediaManager.playbackState.isPlaying,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() }
                )
            } else {
                // Empty state when no media is playing system-wide
                VStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.40))
                    
                    Text("No Media Playing")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Play audio in Apple Music, Spotify, or your browser")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.45))
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
