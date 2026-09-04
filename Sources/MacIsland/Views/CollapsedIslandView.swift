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
                standardCenteredLayout
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
    
    // MARK: - Notched Display Wing Layout (Symmetrical Optical Centering)
    private var notchWingLayout: some View {
        let rightWingWidth = windowManager.currentRightWingWidth
        
        return HStack(spacing: 0) {
            // LEFT WING (44pt): [Flare 6pt] + [11pt gap] + [Icon 16pt] + [11pt gap] -> Notch
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 6) // Accounts for the top-left outward flare curve
                
                ZStack {
                    if hudManager.isHUDActive {
                        Group {
                            if hudManager.hudType == .brightness {
                                Image(systemName: hudManager.brightnessIconName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.islandTextPrimary)
                            } else if hudManager.hudType == .battery {
                                HStack(spacing: 3) {
                                    Text("\(hudManager.batteryPercentage)%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(hudManager.batteryColor)
                                        .lineLimit(1)
                                        .fixedSize()
                                    
                                    Image(systemName: hudManager.batteryIconName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(hudManager.batteryColor)
                                }
                            } else {
                                Image(systemName: hudManager.volumeIconName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.islandTextPrimary)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else if let item = item {
                        if isPlaying {
                            let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            if mediaManager.isTransitioning || (item.artworkData == nil && isTitleEmpty) {
                                SkeletonArtworkView(size: 16, cornerRadius: 4)
                                    .transition(.opacity)
                            } else {
                                ArtworkImageView(item: item, size: 16, cornerRadius: 4)
                                    .matchedGeometryEffect(id: "islandArtwork", in: namespace)
                                    .onTapGesture {
                                        MediaManager.shared.openCurrentSource()
                                    }
                                    .transition(.opacity)
                            }
                        } else {
                            EmptyView()
                        }
                    } else if mediaManager.isTransitioning && isPlaying {
                        SkeletonArtworkView(size: 16, cornerRadius: 4)
                            .transition(.opacity)
                    } else {
                        EmptyView()
                    }
                }
                .offset(y: -2) // Nudged upwards for optical balance
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: 44, height: windowManager.collapsedHeight)
            
            // CENTER: Physical camera cutout zone (100% empty space for hardware notch)
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING: Notch -> [HUD Bar OR TopLyricsView OR Waveform Equalizer]
            HStack(spacing: 0) {
                if item != nil && isLyricsActive && !hudManager.isHUDActive {
                    if lyricsManager.showNoLyricsNotice {
                        // "No lyrics" notice displayed for first 5 seconds
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5)
                        
                        Spacer()
                            .frame(width: 8)
                    } else if !lyricsManager.hasLyrics && !lyricsManager.isLoading {
                        // After 5 seconds: Revert to the audio waveform pulse!
                        if let item = item {
                            let pulseColors = isPlaying ? item.pulseColors : item.pulseColors.map { $0.opacity(0.75) }
                            AudioWaveformIndicator(
                                isPlaying: isPlaying,
                                colors: pulseColors
                            )
                            .matchedGeometryEffect(id: "islandWaveform", in: namespace)
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
                        // Active singing: 14pt leading clearance from notch, full lyrics text
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5) // Optical vertical center in menu bar
                        
                        Spacer()
                            .frame(width: 14)
                    } else if lyricsManager.isLoading {
                        // Loading state: 14pt clearance
                        Spacer()
                            .frame(width: 14)
                        
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -1.5)
                        
                        Spacer()
                            .frame(width: 8)
                    } else {
                        // Instrumental / Intro: Animated beat tune icon centered in 44pt wing!
                        TopLyricsView(isPlaying: isPlaying)
                            .offset(y: -2)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                            .frame(width: 6) // Outward flare curve
                    }
                } else {
                    ZStack {
                        if hudManager.isHUDActive {
                            if hudManager.hudType == .battery {
                                Text(hudManager.batteryText)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(hudManager.batteryColor)
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
                            if isPlaying {
                                let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                let pulseColors = item.pulseColors
                                AudioWaveformIndicator(
                                    isPlaying: isPlaying,
                                    colors: isTitleEmpty ? [Color.islandTextTertiary] : pulseColors
                                )
                                .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                                .animation(.easeInOut(duration: 0.25), value: isPlaying)
                                .transition(.opacity)
                            } else {
                                EmptyView()
                            }
                        } else if mediaManager.isTransitioning && isPlaying {
                            AudioWaveformIndicator(
                                isPlaying: false,
                                colors: [Color.islandTextTertiary]
                            )
                            .matchedGeometryEffect(id: "islandWaveform", in: namespace)
                            .transition(.opacity)
                        } else {
                            EmptyView()
                        }
                    }
                    .offset(y: -2) // Nudged upwards for optical balance
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                        .frame(width: 6) // Accounts for the top-right outward flare curve
                }
            }
            .frame(width: rightWingWidth, height: windowManager.collapsedHeight, alignment: .leading)
            .clipped()
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
    
    // MARK: - Standard Non-Notched Screen Layout
    private var standardCenteredLayout: some View {
        HStack(spacing: 8) {
            if hudManager.isHUDActive {
                if hudManager.hudType == .brightness {
                    Image(systemName: hudManager.brightnessIconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.islandTextPrimary)
                } else if hudManager.hudType == .battery {
                    HStack(spacing: 3) {
                        Text("\(hudManager.batteryPercentage)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(hudManager.batteryColor)
                            .lineLimit(1)
                            .fixedSize()
                        
                        Image(systemName: hudManager.batteryIconName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(hudManager.batteryColor)
                    }
                } else {
                    Image(systemName: hudManager.volumeIconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.islandTextPrimary)
                }
                
                if hudManager.hudType == .battery {
                    Text(hudManager.batteryText)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(hudManager.batteryColor)
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
            } else if let item = item {
                let isTitleEmpty = item.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let showSkeleton = mediaManager.isTransitioning || isTitleEmpty
                if showSkeleton || (item.artworkData == nil && isTitleEmpty) {
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
                    let pulseColors = isPlaying ? item.pulseColors : item.pulseColors.map { $0.opacity(0.75) }
                    
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
                }
            } else if mediaManager.isTransitioning {
                SkeletonArtworkView(size: 16, cornerRadius: 4)
                SkeletonTextLine(width: 80, height: 10)
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, 10)
    }
}
