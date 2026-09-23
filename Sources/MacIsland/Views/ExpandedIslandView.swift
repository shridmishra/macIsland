import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering or tapping Mac Island.
// Precision-matched to the original Dynamic Island layout with fluid gesture navigation:
// - Page 0 (Default): Now Playing Media Player (Artwork, Marquee, Scrubber, Controls)
// - Page 1 (Right): Focus Timer (Pomodoro focus timer)
//
// Gestures:
// - Swipe / Drag Left: Transitions toward Focus Timer widget
// - Swipe / Drag Right: Transitions back toward Media Player widget
// - Swipe / Drag Up: Smoothly collapses the island back into the notch
@MainActor
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    public var namespace: Namespace.ID
    @ObservedObject private var windowManager = WindowManager.shared
    @ObservedObject private var routeManager = AudioRouteManager.shared
    @ObservedObject private var lyricsManager = LyricsManager.shared
    
    @State private var dragOffsetX: CGFloat = 0.0
    @State private var dragOffsetY: CGFloat = 0.0
    @State private var isDragging = false
    
    public init(mediaManager: MediaManager, namespace: Namespace.ID) {
        self.mediaManager = mediaManager
        self.namespace = namespace
    }
    
    public var body: some View {
        ZStack {
            if windowManager.isAudioRoutePickerActive {
                AudioRoutePickerView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                        )
                    )
            } else {
                switch windowManager.currentPage {
                case .media:
                    mediaPlayerContentView
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                                removal: .opacity
                            )
                        )
                case .timer:
                    PomodoroTimerView()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 18)),
                                removal: .opacity.combined(with: .offset(x: 18))
                            )
                        )
                }
            }
        }
        .padding(.horizontal, currentHorizontalPadding)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, currentBottomPadding)
        .offset(x: dragOffsetX, y: dragOffsetY)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    isDragging = true
                    let tx = value.translation.width
                    let ty = value.translation.height
                    
                    // Natural Resistance Physics:
                    // 1. Vertical: Only allow upward drag (negative Y) to collapse the island.
                    if ty < 0 {
                        dragOffsetY = ty * 0.35
                    } else {
                        dragOffsetY = sqrt(ty) * 1.5
                    }
                    
                    // 2. Horizontal: Only allow dragging between available pages
                    if windowManager.isAudioRoutePickerActive {
                        dragOffsetX = 0
                    } else if tx < 0 {
                        // Dragging Left -> going toward Timer
                        if windowManager.currentPage.canGoNext {
                            dragOffsetX = tx * 0.40
                        } else {
                            dragOffsetX = -sqrt(-tx) * 2.0 // Rubberband clamp
                        }
                    } else {
                        // Dragging Right -> going toward Media
                        if windowManager.currentPage.canGoPrevious {
                            dragOffsetX = tx * 0.40
                        } else {
                            dragOffsetX = sqrt(tx) * 2.0 // Rubberband clamp
                        }
                    }
                }
                .onEnded { value in
                    isDragging = false
                    let tx = value.translation.width
                    let ty = value.translation.height
                    let pty = value.predictedEndTranslation.height
                    let ptx = value.predictedEndTranslation.width
                    
                    // 1. Check for swipe up ("upside") to collapse
                    if ty < -25 || pty < -45 {
                        withAnimation(IslandAnimation.notchSpring) {
                            dragOffsetY = -35
                        }
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                        windowManager.collapse()
                        dragOffsetY = 0
                        dragOffsetX = 0
                        return
                    }
                    
                    withAnimation(IslandAnimation.notchSpring) {
                        dragOffsetY = 0
                    }
                    
                    // 2. Check for horizontal swipe to switch pages (only when route picker is not active)
                    if !windowManager.isAudioRoutePickerActive {
                        let swipeThreshold: CGFloat = 35.0
                        let predictedThreshold: CGFloat = 65.0
                        
                        if tx < -swipeThreshold || ptx < -predictedThreshold {
                            // Swiped left -> navigate forward (Media -> Timer)
                            if windowManager.currentPage.canGoNext {
                                windowManager.nextPage()
                            }
                        } else if tx > swipeThreshold || ptx > predictedThreshold {
                            // Swiped right -> navigate backward (Timer -> Media)
                            if windowManager.currentPage.canGoPrevious {
                                windowManager.previousPage()
                            }
                        }
                    }
                    
                    withAnimation(IslandAnimation.notchSpring) {
                        dragOffsetX = 0
                    }
                }
        )
    }
    
    // MARK: - Dynamic Precision Paddings
    
    private var currentHorizontalPadding: CGFloat {
        if windowManager.isAudioRoutePickerActive {
            return 25.0
        }
        switch windowManager.currentPage {
        case .timer:
            return 14.0
        case .media:
            return mediaManager.currentItem != nil ? 25.0 : 18.0
        }
    }
    
    private var currentBottomPadding: CGFloat {
        if windowManager.isAudioRoutePickerActive {
            return 26.0
        }
        switch windowManager.currentPage {
        case .timer:
            return 10.0
        case .media:
            return mediaManager.currentItem != nil ? 20.0 : 14.0
        }
    }
    
    // MARK: - Page 1: Media Player Content View
    
    @ViewBuilder
    private var mediaPlayerContentView: some View {
        VStack(spacing: 12) {
            if let item = mediaManager.currentItem {
                let isPlaying = mediaManager.playbackState.isPlaying
                
                // Top section: Interactive Track Header (diff-isolated)
                ExpandedTrackHeaderView(
                    item: item,
                    isPlaying: isPlaying,
                    isTransitioning: mediaManager.isTransitioning,
                    namespace: namespace,
                    onOpenSource: { mediaManager.openCurrentSource() }
                )
                
                // Middle section: Scannable horizontal progress bar with timestamps & interactive seek
                ExpandedProgressSectionView(
                    progress: mediaManager.interpolatedProgress,
                    currentTime: mediaManager.formattedCurrentTime,
                    remainingTime: mediaManager.formattedRemainingTime,
                    onSeek: { targetFraction in
                        mediaManager.seek(to: targetFraction)
                    }
                )
                .transition(.opacity.combined(with: .offset(y: 3)))
                
                // Bottom section: Centered Playback controls + Dynamic Route icon + Lyrics Toggle Button
                MediaControlButtons(
                    isPlaying: isPlaying,
                    isLyricsEnabled: lyricsManager.isLyricsEnabled,
                    showLyricsButton: !item.service.isVideoService,
                    audioRouteIcon: routeManager.activeRouteIcon,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() },
                    onToggleLyrics: { lyricsManager.toggleLyrics() }
                )
                .transition(.opacity.combined(with: .offset(y: 4)))
            } else if mediaManager.isTransitioning {
                // Skeleton loading state
                HStack(alignment: .center, spacing: 11) {
                    SkeletonArtworkView(size: 36, cornerRadius: 8)
                        .transition(.opacity)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        SkeletonTextLine(width: 120, height: 12)
                            .transition(.opacity)
                        SkeletonTextLine(width: 80, height: 10)
                            .transition(.opacity)
                    }
                    .transition(.opacity)
                    
                    Spacer(minLength: 8)
                    
                    AudioWaveformIndicator(
                        isPlaying: false,
                        colors: [Color.islandTextTertiary]
                    )
                    .padding(.trailing, 8)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                
                PlaybackProgressSlider(
                    progress: 0.0,
                    currentTimeString: "0:00",
                    remainingTimeString: "-0:00",
                    onSeek: { _ in }
                )
                .transition(.opacity.combined(with: .offset(y: 3)))
                
                MediaControlButtons(
                    isPlaying: false,
                    isLyricsEnabled: lyricsManager.isLyricsEnabled,
                    showLyricsButton: true,
                    audioRouteIcon: routeManager.activeRouteIcon,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() },
                    onToggleLyrics: { lyricsManager.toggleLyrics() }
                )
                .transition(.opacity.combined(with: .offset(y: 4)))
            } else {
                ExpandedIdlePlaceholderView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Subviews Extracted for Senior-Grade Invalidation Isolation

@MainActor
private struct ExpandedTrackHeaderView: View {
    let item: MediaItem
    let isPlaying: Bool
    let isTransitioning: Bool
    let namespace: Namespace.ID
    let onOpenSource: () -> Void
    
    var body: some View {
        let pulseColors = isPlaying ? item.pulseColors : item.pulseColors.map { $0.opacity(0.75) }
        let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasArt = (item.artworkData != nil && !item.artworkData!.isEmpty) || (item.artworkImage != nil)
        let showSkeleton = (isTransitioning && !hasArt) || isTitleEmpty
        
        Button {
            onOpenSource()
            WindowManager.shared.collapse()
        } label: {
            HStack(alignment: .center, spacing: 11) {
                ZStack {
                    if showSkeleton || (!hasArt && isTitleEmpty) {
                        SkeletonArtworkView(size: 36, cornerRadius: 8)
                            .transition(.opacity)
                    } else {
                        ArtworkImageView(item: item, size: 36, cornerRadius: 8)
                            .matchedGeometryEffect(
                                id: "islandArtwork",
                                in: namespace,
                                isSource: WindowManager.shared.islandState.isExpanded
                            )
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showSkeleton)
                
                VStack(alignment: .leading, spacing: 2) {
                    if showSkeleton {
                        SkeletonTextLine(width: 120, height: 12)
                            .transition(.opacity)
                        SkeletonTextLine(width: 80, height: 10)
                            .transition(.opacity)
                    } else {
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
                        
                        Text(item.subtitleText)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.60))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showSkeleton)
                .transition(.opacity)
                
                Spacer(minLength: 8)
                
                AudioWaveformIndicator(
                    isPlaying: isPlaying,
                    colors: isTitleEmpty ? [Color.islandTextTertiary] : pulseColors
                )
                .matchedGeometryEffect(
                    id: "islandWaveform",
                    in: namespace,
                    isSource: WindowManager.shared.islandState.isExpanded
                )
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
    }
}

@MainActor
private struct ExpandedProgressSectionView: View {
    let progress: Double
    let currentTime: String
    let remainingTime: String
    let onSeek: (Double) -> Void
    
    var body: some View {
        PlaybackProgressSlider(
            progress: progress,
            currentTimeString: currentTime,
            remainingTimeString: remainingTime,
            onSeek: onSeek
        )
    }
}

@MainActor
private struct ExpandedIdlePlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.islandRose)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Media Playing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.islandTextPrimary)
                    
                    Text("Play audio from Music, Spotify, or Web")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.islandTextTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.top, 4)
            
            Spacer(minLength: 4)
            
            // App Quick Launch Bar
            HStack(spacing: 12) {
                quickAppButton(title: "Music", systemIcon: "music.note.list") {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") {
                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                    }
                }
                
                quickAppButton(title: "Spotify", systemIcon: "play.circle.fill") {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") {
                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                    } else if let webUrl = URL(string: "https://open.spotify.com") {
                        NSWorkspace.shared.open(webUrl)
                    }
                }
                
                quickAppButton(title: "YouTube", systemIcon: "play.rectangle.fill") {
                    if let webUrl = URL(string: "https://music.youtube.com") {
                        NSWorkspace.shared.open(webUrl)
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func quickAppButton(title: String, systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemIcon)
                    .font(.system(size: 10.5, weight: .medium))
                
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(Color.islandTextPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.springPress(scale: 0.94, haptic: true))
    }
}

