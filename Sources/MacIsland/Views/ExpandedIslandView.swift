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
    @ObservedObject private var lyricsManager = LyricsManager.shared
    
    public init(mediaManager: MediaManager, namespace: Namespace.ID) {
        self.mediaManager = mediaManager
        self.namespace = namespace
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                let pulseColor = isPlaying ? item.pulseColor : item.pulseColor.opacity(0.75)
                
                // Top section: Service/Album Artwork + Track Details + Waveform Indicator OR Lyrics Display
                HStack(alignment: .center, spacing: 11) {
                    ArtworkImageView(item: item, size: 36, cornerRadius: 8)
                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title: bold, crisp, marquee animated on playback
                        MarqueeText(
                            text: item.displayTitle,
                            font: .system(size: 13, weight: .bold),
                            nsFont: .systemFont(ofSize: 13, weight: .bold),
                            color: Color.islandTextPrimary,
                            isPlaying: isPlaying,
                            speed: 30.0,
                            holdDelay: 2.0,
                            spacing: 36.0,
                            fadeLength: 14.0
                        )
                        
                        // Subtitle: Service name (YouTube, Prime Video, Netflix, Spotify) or Artist
                        Text(item.effectiveAppName)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.60))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .transition(.opacity)
                    
                    Spacer(minLength: 8)
                    
                    if lyricsManager.isLyricsEnabled {
                        // Synchronized Lyrics View on the right side of the bar
                        LyricsDisplayView(isPlaying: isPlaying)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // Waveform Audio Equalizer aligned with the time indicator below
                        AudioWaveformIndicator(
                            isPlaying: isPlaying,
                            color: pulseColor
                        )
                        .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                        .padding(.trailing, 8)
                        .animation(.easeInOut(duration: 0.25), value: isPlaying)
                        .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: lyricsManager.isLyricsEnabled)
                
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
                
                // Bottom section: Centered Playback controls + Dynamic Route icon + Lyrics Toggle Button
                MediaControlButtons(
                    isPlaying: isPlaying,
                    isLyricsEnabled: lyricsManager.isLyricsEnabled,
                    audioRouteIcon: routeManager.activeRouteIcon,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() },
                    onToggleLyrics: { lyricsManager.toggleLyrics() }
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
        .padding(.horizontal, 25)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 20)
    }
}
