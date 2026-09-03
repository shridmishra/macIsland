import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Compact, sleek, proportional design fitting snugly below the MacBook notch:
// - Header: Artwork (38x38) + Track Title + Subtitle + Animated Waveform Pulse
// - Scrubber: Elapsed Time + Progress Capsule + Negative Remaining Time
// - Controls: Centered Previous / Frameless Play-Pause / Next + Dynamic Audio Route Icon
// Participates in matchedGeometryEffect for seamless, continuous fluid expansion.
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
        VStack(spacing: 9) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                let pulseColor = isPlaying ? item.service.brandColor : Color.white.opacity(0.35)
                
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator
                HStack(alignment: .center, spacing: 10) {
                    ArtworkImageView(item: item, size: 38, cornerRadius: 8.5)
                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(item.displayTitle)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Subtitle: Service name (Prime Video, YouTube, Netflix, Spotify) or Artist
                        Text(item.effectiveAppName)
                            .font(.system(size: 11.5, weight: .medium))
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
        .padding(.horizontal, 14)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 9)
    }
}
