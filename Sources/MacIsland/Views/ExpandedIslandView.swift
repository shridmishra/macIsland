import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Pixel-perfect alignment matching the reference Dynamic Island layout:
// - Header: Artwork (36x36) + Track Title & Subtitle + Waveform Equalizer Pulse at its designated top-right place
// - Scrubber: Elapsed Time + Progress Capsule + Negative Remaining Time (real-time tracking & seeking)
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
        VStack(spacing: 11) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                let pulseColor = isPlaying ? item.service.brandColor : Color.white.opacity(0.35)
                
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator at its designated place
                HStack(alignment: .center, spacing: 11) {
                    ArtworkImageView(item: item, size: 36, cornerRadius: 8)
                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title: bold, crisp, matching reference card
                        Text(item.displayTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Subtitle: Service name (YouTube, Prime Video, Netflix, Spotify) or Artist
                        Text(item.effectiveAppName)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.60))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .transition(.opacity)
                    
                    Spacer(minLength: 8)
                    
                    // Waveform Audio Equalizer at its designated top-right place
                    AudioWaveformIndicator(
                        isPlaying: isPlaying,
                        color: pulseColor
                    )
                    .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                    .animation(.easeInOut(duration: 0.25), value: isPlaying)
                }
                
                // Middle section: Scannable horizontal progress bar with timestamps & interactive seek
                PlaybackProgressSlider(
                    progress: mediaManager.interpolatedProgress,
                    currentTimeString: mediaManager.formattedCurrentTime,
                    remainingTimeString: mediaManager.formattedRemainingTime,
                    onSeek: { targetFraction in
                        mediaManager.seek(to: targetFraction)
                    }
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
        .padding(.horizontal, 20)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 14)
    }
}
