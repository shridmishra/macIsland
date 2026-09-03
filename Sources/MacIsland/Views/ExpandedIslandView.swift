import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Refined Apple Dynamic Island aesthetic:
// - Generous 20pt padding around all content for comfortable, premium breathing room
// - Sleek, proportional title typography (12.5pt semibold) preventing loud/oversized text
// - 34x34 brand artwork with continuous rounded corners
// - 4-bar delicate hairline animated equalizer waveform
// - Scannable scrubber and centered playback controls
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    public var namespace: Namespace.ID
    @ObservedObject private var windowManager = WindowManager.shared
    @ObservedObject private var routeManager = AudioRouteManager.shared
    
    public init(mediaManager: MediaManager, namespace: Namespace.ID) {
        self.mediaManager = mediaManager
        self.namespace = namespace
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                let pulseColor = isPlaying ? item.service.brandColor : Color.white.opacity(0.35)
                
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator
                HStack(alignment: .center, spacing: 11) {
                    ArtworkImageView(item: item, size: 34, cornerRadius: 7.5)
                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title: refined size with comfortable optical tracking
                        Text(item.displayTitle)
                            .font(.system(size: 12.5, weight: .semibold))
                            .tracking(-0.2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Subtitle: Service name (YouTube, Prime Video, Netflix, Spotify) or Artist
                        Text(item.effectiveAppName)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.60))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .transition(.opacity)
                    
                    Spacer(minLength: 4)
                    
                    // Waveform Audio Equalizer on the top-right matching the brand icon color
                    AudioWaveformIndicator(
                        isPlaying: isPlaying,
                        color: pulseColor
                    )
                    .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                    .animation(.easeInOut(duration: 0.25), value: isPlaying)
                }
                
                // Middle section: Scannable horizontal progress bar with timestamps
                PlaybackProgressSlider(
                    progress: mediaManager.interpolatedProgress,
                    currentTimeString: mediaManager.formattedCurrentTime,
                    remainingTimeString: mediaManager.formattedRemainingTime
                )
                .transition(.opacity.combined(with: .offset(y: 3)))
                
                // Bottom section: Centered Playback controls + Dynamic Route icon (AirPods/Headphones)
                MediaControlButtons(
                    isPlaying: isPlaying,
                    audioRouteIcon: routeManager.activeRouteIcon,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() }
                )
                .transition(.opacity.combined(with: .offset(y: 4)))
            } else {
                // Empty state when no media is playing system-wide
                VStack(spacing: 5) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.40))
                    
                    Text("No Media Playing")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Play audio in Apple Music, Spotify, or your browser")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 20) // Generous 20pt horizontal padding around content
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 13) // Comfortable bottom breathing room
    }
}
