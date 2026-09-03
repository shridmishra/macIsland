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
                    let pulseColors = isPlaying ? item.pulseColors : item.pulseColors.map { $0.opacity(0.75) }
                    
                    // Top section: Interactive Track Header (opens active browser tab / source app on click)
                    Button {
                        mediaManager.openCurrentSource()
                        WindowManager.shared.collapse()
                    } label: {
                        HStack(alignment: .center, spacing: 11) {
                            // Artwork: Skeleton placeholder during transition, real artwork otherwise
                            ZStack {
                                if mediaManager.isTransitioning {
                                    SkeletonArtworkView(size: 36, cornerRadius: 8)
                                        .transition(.opacity)
                                } else {
                                    ArtworkImageView(item: item, size: 36, cornerRadius: 8)
                                        .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: mediaManager.isTransitioning)
                            
                            // Title + Subtitle: Skeleton pill lines during transition
                            VStack(alignment: .leading, spacing: 2) {
                                if mediaManager.isTransitioning {
                                    SkeletonTextLine(width: 120, height: 12)
                                        .transition(.opacity)
                                    SkeletonTextLine(width: 80, height: 10)
                                        .transition(.opacity)
                                } else {
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
                                    
                                    // Subtitle: Service name or Artist • Service
                                    Text(item.subtitleText)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.60))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: mediaManager.isTransitioning)
                            .transition(.opacity)
                            
                            Spacer(minLength: 8)
                            
                            // Waveform Audio Equalizer Pulse kept inside the floating card header
                            AudioWaveformIndicator(
                                isPlaying: isPlaying,
                                colors: pulseColors
                            )
                            .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                            .padding(.trailing, 8)
                            .animation(.easeInOut(duration: 0.25), value: isPlaying)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SpringPressButtonStyle(pressedScale: 0.98, hasHaptic: true))
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
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
                // Nothing State: Pomodoro Timer on left + Monthly Calendar on right
                NothingIslandView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity
                        )
                    )
            }
        }
        .padding(.horizontal, mediaManager.currentItem != nil ? 25 : 18)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, mediaManager.currentItem != nil ? 20 : 14)
    }
}
