import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// On notched displays, compact wings flank the physical cutout at the exact 28pt height of the notch.
// Shows the true streaming service logo icon (Prime Video, Netflix, YouTube, Spotify)
// with pixel-perfect symmetrical padding and optical centering.
// The right wing waveform pulse dynamically matches the brand icon color (Prime: Blue, Netflix: Red, Spotify: Green),
// or displays resting bars in muted gray when playback is paused.
public struct CollapsedIslandView: View {
    public let item: MediaItem?
    public let isPlaying: Bool
    public var namespace: Namespace.ID
    @ObservedObject private var windowManager = WindowManager.shared
    @ObservedObject private var lyricsManager = LyricsManager.shared
    @ObservedObject private var hudManager = SystemHUDManager.shared
    @ObservedObject private var mediaManager = MediaManager.shared
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    
    public init(item: MediaItem?, isPlaying: Bool, namespace: Namespace.ID) {
        self.item = item
        self.isPlaying = isPlaying
        self.namespace = namespace
    }
    
    private var isLyricsActive: Bool {
        isPlaying && lyricsManager.isLyricsEnabled && (item?.service.isVideoService != true)
    }
    
    public var body: some View {
        Group {
            if windowManager.hasNotch {
                notchWingLayout
            } else {
                CollapsedStandardBarView(
                    item: item,
                    isPlaying: isPlaying,
                    isLyricsActive: isLyricsActive,
                    namespace: namespace,
                    windowManager: windowManager,
                    hudManager: hudManager,
                    mediaManager: mediaManager,
                    pomodoroManager: pomodoroManager
                )
            }
        }
        .frame(height: windowManager.collapsedHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if !hudManager.isHUDActive {
                WindowManager.shared.expand()
            }
        }
    }
    
    // MARK: - Notched Display Wing Layout
    private var notchWingLayout: some View {
        let leftWingWidth = windowManager.currentLeftWingWidth
        let rightWingWidth = windowManager.currentRightWingWidth
        let hasActiveWings = windowManager.hasActiveWings
        
        return HStack(spacing: 0) {
            // LEFT WING
            CollapsedNotchLeftWingView(
                item: item,
                isPlaying: isPlaying,
                hasActiveWings: hasActiveWings,
                leftWingWidth: leftWingWidth,
                collapsedHeight: windowManager.collapsedHeight,
                namespace: namespace,
                hudManager: hudManager,
                mediaManager: mediaManager,
                pomodoroManager: pomodoroManager
            )
            
            // CENTER: Physical camera cutout zone
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING
            CollapsedNotchRightWingView(
                item: item,
                isPlaying: isPlaying,
                isLyricsActive: isLyricsActive,
                hasActiveWings: hasActiveWings,
                rightWingWidth: rightWingWidth,
                collapsedHeight: windowManager.collapsedHeight,
                namespace: namespace,
                hudManager: hudManager,
                mediaManager: mediaManager,
                lyricsManager: lyricsManager
            )
        }
        .frame(width: windowManager.collapsedWidth, height: windowManager.collapsedHeight, alignment: .leading)
    }
}

// MARK: - Dedicated Collapsed Subviews for Invalidation Isolation

@MainActor
private struct CollapsedNotchLeftWingView: View {
    let item: MediaItem?
    let isPlaying: Bool
    let hasActiveWings: Bool
    let leftWingWidth: CGFloat
    let collapsedHeight: CGFloat
    let namespace: Namespace.ID
    @ObservedObject var hudManager: SystemHUDManager
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject var pomodoroManager: PomodoroManager
    
    var body: some View {
        HStack(spacing: 0) {
            if hasActiveWings {
                Spacer()
                    .frame(width: 6) // Accounts for the top-left outward flare curve
                
                ZStack {
                    if hudManager.isHUDActive {
                        Group {
                            if hudManager.hudType == .brightness {
                                Image(systemName: hudManager.brightnessIconName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.islandTextPrimary)
                            } else if hudManager.hudType == .battery {
                                HStack(spacing: 4) {
                                    Text("\(hudManager.batteryPercentage)%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(hudManager.batteryColor)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                    
                                    Image(systemName: hudManager.batteryIconName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(hudManager.batteryColor)
                                }
                            } else {
                                Image(systemName: hudManager.volumeIconName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.islandTextPrimary)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else if pomodoroManager.isTimerActive && pomodoroManager.isTimerInNotchEnabled {
                        NotchTimerRingView(manager: pomodoroManager)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    } else if let item = item {
                        let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        let hasArt = (item.artworkData != nil && !item.artworkData!.isEmpty) || (item.artworkImage != nil)
                        if (mediaManager.isTransitioning && !hasArt) || (!hasArt && isTitleEmpty) {
                            SkeletonArtworkView(size: 16, cornerRadius: 4)
                        } else {
                            ArtworkImageView(item: item, size: 16, cornerRadius: 4)
                                .matchedGeometryEffect(
                                    id: "islandArtwork",
                                    in: namespace,
                                    isSource: !WindowManager.shared.islandState.isExpanded
                                )
                                .onTapGesture {
                                    MediaManager.shared.openCurrentSource()
                                }
                        }
                    } else if mediaManager.isTransitioning && isPlaying {
                        SkeletonArtworkView(size: 16, cornerRadius: 4)
                            .transition(.opacity)
                    } else {
                        EmptyView()
                    }
                }
                .offset(y: -2)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(width: hasActiveWings ? leftWingWidth : 0, height: collapsedHeight)
        .clipped()
        .animation(IslandAnimation.notchSpring, value: leftWingWidth)
    }
}

@MainActor
private struct CollapsedNotchRightWingView: View {
    let item: MediaItem?
    let isPlaying: Bool
    let isLyricsActive: Bool
    let hasActiveWings: Bool
    let rightWingWidth: CGFloat
    let collapsedHeight: CGFloat
    let namespace: Namespace.ID
    @ObservedObject var hudManager: SystemHUDManager
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject var lyricsManager: LyricsManager
    
    var body: some View {
        HStack(spacing: 0) {
            if hasActiveWings {
                if item != nil && isLyricsActive && !hudManager.isHUDActive {
                    if lyricsManager.showNoLyricsNotice {
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5)
                        
                        Spacer()
                            .frame(width: 8)
                    } else if !lyricsManager.hasLyrics && !lyricsManager.isLoading {
                        if let item = item {
                            let pulseColors = item.pulseColors
                            AudioWaveformIndicator(
                                isPlaying: isPlaying,
                                colors: pulseColors
                            )
                            .matchedGeometryEffect(
                                id: "islandWaveform",
                                in: namespace,
                                isSource: !WindowManager.shared.islandState.isExpanded
                            )
                            .animation(.easeInOut(duration: 0.25), value: isPlaying)
                            .transition(.opacity)
                            .offset(y: -2)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Circle()
                                .fill(Color.islandTextTertiary)
                                .frame(width: 4, height: 4)
                        }
                        
                        Spacer()
                            .frame(width: 6)
                    } else if let line = lyricsManager.currentLine, !line.text.isEmpty {
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5)
                        
                        Spacer()
                            .frame(width: 14)
                    } else if lyricsManager.isLoading {
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5)
                        
                        Spacer()
                            .frame(width: 8)
                    } else {
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -2)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                            .frame(width: 6)
                    }
                } else {
                    ZStack {
                        if hudManager.isHUDActive {
                            if hudManager.hudType == .battery {
                                Text(hudManager.batteryText)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundStyle(hudManager.batteryColor)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                            } else {
                                HUDLevelBarView(level: hudManager.level) { newLevel in
                                    if hudManager.hudType == .brightness {
                                        hudManager.setBrightness(newLevel)
                                    } else {
                                        hudManager.setVolume(newLevel)
                                    }
                                }
                                .transition(.opacity)
                            }
                        } else if let item = item {
                            let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            let pulseColors = item.pulseColors
                            AudioWaveformIndicator(
                                isPlaying: isPlaying,
                                colors: isTitleEmpty ? [Color.islandTextTertiary] : pulseColors
                            )
                            .matchedGeometryEffect(
                                id: "islandWaveform",
                                in: namespace,
                                isSource: !WindowManager.shared.islandState.isExpanded
                            )
                            .animation(.easeInOut(duration: 0.25), value: isPlaying)
                            .transition(.opacity)
                        } else if mediaManager.isTransitioning && isPlaying {
                            AudioWaveformIndicator(
                                isPlaying: false,
                                colors: [Color.islandTextTertiary]
                            )
                            .matchedGeometryEffect(
                                id: "islandWaveform",
                                in: namespace,
                                isSource: !WindowManager.shared.islandState.isExpanded
                            )
                            .transition(.opacity)
                        } else {
                            EmptyView()
                        }
                    }
                    .offset(y: -2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                        .frame(width: 6)
                }
            }
        }
        .frame(width: hasActiveWings ? rightWingWidth : 0, height: collapsedHeight, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            if !hudManager.isHUDActive && item != nil {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                MediaManager.shared.togglePlayPause()
            }
        }
        .mask {
            let isLyricsShowing = item != nil && isLyricsActive && !hudManager.isHUDActive && lyricsManager.currentLine != nil
            if isLyricsShowing {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black)
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 16)
                }
            } else {
                Rectangle().fill(Color.black)
            }
        }
        .animation(IslandAnimation.notchSpring, value: rightWingWidth)
    }
}

@MainActor
private struct CollapsedStandardBarView: View {
    let item: MediaItem?
    let isPlaying: Bool
    let isLyricsActive: Bool
    let namespace: Namespace.ID
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var hudManager: SystemHUDManager
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject var pomodoroManager: PomodoroManager
    
    var body: some View {
        HStack(spacing: 8) {
            if hudManager.isHUDActive {
                if hudManager.hudType == .brightness {
                    Image(systemName: hudManager.brightnessIconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                } else if hudManager.hudType == .battery {
                    HStack(spacing: 4) {
                        Text("\(hudManager.batteryPercentage)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(hudManager.batteryColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Image(systemName: hudManager.batteryIconName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(hudManager.batteryColor)
                    }
                } else {
                    Image(systemName: hudManager.volumeIconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                }
                
                if hudManager.hudType == .battery {
                    Text(hudManager.batteryText)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(hudManager.batteryColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                } else {
                    HUDLevelBarView(level: hudManager.level) { newLevel in
                        if hudManager.hudType == .brightness {
                            hudManager.setBrightness(newLevel)
                        } else {
                            hudManager.setVolume(newLevel)
                        }
                    }
                }
            } else if windowManager.hasActiveWings {
                if pomodoroManager.isTimerActive && pomodoroManager.isTimerInNotchEnabled {
                    NotchTimerRingView(manager: pomodoroManager)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                
                if let item = item, windowManager.shouldShowMediaInCollapsed {
                    let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let hasArt = (item.artworkData != nil && !item.artworkData!.isEmpty) || (item.artworkImage != nil)
                    let showSkeleton = (mediaManager.isTransitioning && !hasArt) || isTitleEmpty
                    if showSkeleton || (!hasArt && isTitleEmpty) {
                        SkeletonArtworkView(size: 16, cornerRadius: 4)
                    } else {
                        ArtworkImageView(item: item, size: 16, cornerRadius: 4)
                            .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                            .onTapGesture {
                                MediaManager.shared.openCurrentSource()
                            }
                    }
                    
                    if isLyricsActive {
                        TopLyricsView(isPlaying: isPlaying, maxWidth: 200)
                            .transition(.opacity)
                    } else if showSkeleton {
                        SkeletonTextLine(width: 80, height: 10)
                    } else {
                        let pulseColors = item.pulseColors
                        
                        MarqueeText(
                            text: item.displayTitle,
                            font: .system(size: 11, weight: .semibold),
                            nsFont: .systemFont(ofSize: 11, weight: .semibold),
                            color: Color.islandTextPrimary,
                            isPlaying: isPlaying,
                            speed: 26.0,
                            holdDelay: 2.0,
                            spacing: 28.0,
                            fadeLength: 10.0
                        )
                        
                        AudioWaveformIndicator(
                            isPlaying: isPlaying,
                            colors: pulseColors
                        )
                        .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                        .onTapGesture {
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                            MediaManager.shared.togglePlayPause()
                        }
                    }
                } else if mediaManager.isTransitioning && windowManager.shouldShowMediaInCollapsed {
                    SkeletonArtworkView(size: 16, cornerRadius: 4)
                    SkeletonTextLine(width: 80, height: 10)
                }
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, windowManager.hasActiveWings ? 10 : 0)
    }
}
