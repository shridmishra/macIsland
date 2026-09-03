import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Pixel-perfect replica of the reference Dynamic Island layout:
// - Header: Artwork + Track Title + Subtitle + Animated Waveform Pulse
// - Scrubber: Elapsed Time + Progress Capsule + Negative Remaining Time
// - Controls: Centered Previous / Frameless Play-Pause / Next + Dynamic Audio Route Icon
// Participates in matchedGeometryEffect for seamless, continuous fluid expansion.
// The pulse color dynamically matches the service brand logo color (Prime: Blue, Netflix/YouTube: Red, Spotify: Green),
// or displays resting bars in muted gray when playback is paused.
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
        VStack(spacing: 13) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                let pulseColor = isPlaying ? item.service.brandColor : Color.white.opacity(0.35)
                
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator
                HStack(alignment: .center, spacing: 12) {
                    ArtworkImageView(item: item, size: 46, cornerRadius: 10)
                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                    
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
                    .transition(.opacity)
                    
                    Spacer(minLength: 0)
                    
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
                .transition(.opacity.combined(with: .offset(y: 4)))
                
                // Bottom section: Centered Playback controls + Dynamic Route icon (AirPods/Headphones)
                MediaControlButtons(
                    isPlaying: isPlaying,
                    audioRouteIcon: routeManager.activeRouteIcon,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() }
                )
                .transition(.opacity.combined(with: .offset(y: 6)))
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
