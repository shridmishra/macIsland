import SwiftUI
import AppKit
import Combine

// MARK: - DashboardTab
public enum DashboardTab: String, CaseIterable, Identifiable {
    case nowPlaying = "Now Playing"
    case lyrics = "Lyrics"
    case focus = "Focus & Timer"
    case system = "System & Power"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .nowPlaying: return "play.circle.fill"
        case .lyrics: return "quote.bubble.fill"
        case .focus: return "timer"
        case .system: return "bolt.batteryblock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - DesktopDashboardView
// The primary desktop companion window for Mac Island:
// Allows users to view and control Now Playing media, synced lyrics, Pomodoro timers,
// system audio routes, battery status, and notch preferences on their desktop.
public struct DesktopDashboardView: View {
    @State private var selectedTab: DashboardTab = .nowPlaying
    
    @ObservedObject private var mediaManager = MediaManager.shared
    @ObservedObject private var lyricsManager = LyricsManager.shared
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    @ObservedObject private var batteryManager = BatteryHUDManager.shared
    @ObservedObject private var routeManager = AudioRouteManager.shared
    @ObservedObject private var proManager = ProManager.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginManager.shared
    
    @AppStorage("isAccessoryOnly") private var isAccessoryOnly: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // MARK: - Dynamic Ambient Artwork Backdrop (Apple Music style)
            AppleMusicAmbientBackgroundView(mediaItem: mediaManager.currentItem)
            
            HStack(spacing: 0) {
                // MARK: - Left Translucent Sidebar Navigation
                sidebarView
                    .frame(width: 220)
                    .background(
                        VisualEffectView(
                            material: .sidebar,
                            blendingMode: .behindWindow,
                            state: .active,
                            cornerRadius: 0
                        )
                        .overlay(Color.black.opacity(0.30))
                    )
                
                Divider()
                    .overlay(Color.white.opacity(0.12))
                
                // MARK: - Main Content Area
                ZStack {
                    Color.clear
                        .ignoresSafeArea()
                    
                    Group {
                        switch selectedTab {
                        case .nowPlaying:
                            nowPlayingTabView
                        case .lyrics:
                            lyricsTabView
                        case .focus:
                            focusTabView
                        case .system:
                            systemTabView
                        case .settings:
                            settingsTabView
                        }
                    }
                    .padding(26)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 820, idealWidth: 920, minHeight: 520, idealHeight: 620)
    }
    
    // MARK: - Sidebar
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App Header (spaced cleanly below macOS traffic lights)
            HStack(spacing: 8) {
                Image(systemName: "circle.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.islandRose)
                
                Text("Mac Island")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                
                Spacer()
                
                if proManager.isPro {
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.14)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 46)
            
            // Section Category Label
            Text("LIBRARY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(.horizontal, 16)
                .padding(.top, 6)
            
            // Navigation Items
            VStack(spacing: 3) {
                ForEach(DashboardTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedTab = tab
                        }
                        if tab == .lyrics && lyricsManager.currentLyrics == nil {
                            lyricsManager.fetchCurrentTrackLyrics()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 18)
                                .foregroundStyle(selectedTab == tab ? Color.white : Color.white.opacity(0.55))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? Color.white : Color.white.opacity(0.75))
                            
                            Spacer()
                            
                            if tab == .nowPlaying && mediaManager.playbackState == .playing {
                                AudioWaveformIndicator(isPlaying: true)
                                    .scaleEffect(0.60)
                            }
                            
                            if tab == .focus && pomodoroManager.isTimerActive {
                                Text(pomodoroManager.formattedPillTime)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.islandPomodoroFocus)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(selectedTab == tab ? Color.white.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Minimal Understated Status Footer
            HStack(spacing: 7) {
                Circle()
                    .fill(mediaManager.playbackState == .playing ? Color.islandAccent : Color.white.opacity(0.30))
                    .frame(width: 6.5, height: 6.5)
                
                Text(mediaManager.playbackState == .playing ? "Playing" : "Idle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                
                Spacer()
                
                HStack(spacing: 3) {
                    if batteryManager.isConnectedToAC {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.islandBatteryCharging)
                    }
                    Text("\(batteryManager.currentPercentage)%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }
    
    // MARK: - 1. Now Playing Tab
    private var nowPlayingTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOW PLAYING")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    Text("Studio & Playback Controls")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                }
                Spacer()
                
                if let item = mediaManager.currentItem {
                    Button(action: {
                        mediaManager.openCurrentSource()
                    }) {
                        HStack(spacing: 6) {
                            BrandIconView(service: item.service, size: 14)
                            Text("Open in \(item.effectiveAppName)")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.islandBorder)
                        .cornerRadius(6)
                        .foregroundStyle(Color.islandTextPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let item = mediaManager.currentItem {
                HStack(alignment: .top, spacing: 24) {
                    // Artwork with ambient glow
                    ZStack {
                        if let img = item.artworkImage {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 170, height: 170)
                                .cornerRadius(14)
                                .blur(radius: 20)
                                .opacity(0.45)
                        }
                        
                        ArtworkImageView(
                            artworkData: item.artworkData,
                            artworkImage: item.artworkImage,
                            service: item.service,
                            size: 170,
                            cornerRadius: 14
                        )
                    }
                    .frame(width: 170, height: 170)
                    
                    // Track Information & Controls
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayTitle)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.islandTextPrimary)
                                .lineLimit(2)
                            
                            Text(item.artist.isEmpty ? "Unknown Artist" : item.artist)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.islandTextSecondary)
                            
                            if !item.album.isEmpty {
                                Text(item.album)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color.islandTextTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        // Scrubber Slider
                        PlaybackProgressSlider(
                            progress: mediaManager.interpolatedProgress,
                            currentTimeString: mediaManager.formattedCurrentTime,
                            remainingTimeString: mediaManager.formattedRemainingTime,
                            onSeek: { fraction in
                                mediaManager.seek(to: fraction)
                            }
                        )
                        
                        // Control Buttons
                        HStack(spacing: 24) {
                            Button(action: { mediaManager.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.islandTextPrimary)
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Button(action: { mediaManager.togglePlayPause() }) {
                                Image(systemName: mediaManager.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 38))
                                    .foregroundStyle(Color.islandTextPrimary)
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Button(action: { mediaManager.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.islandTextPrimary)
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Spacer()
                            
                            // Audio Route Button
                            Button(action: {
                                selectedTab = .system
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: routeManager.activeRouteIcon ?? "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                    Text(routeManager.deviceName)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.islandBorder)
                                .cornerRadius(6)
                                .foregroundStyle(Color.islandTextSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                
                // Live Lyrics Teaser Card
                if lyricsManager.isLyricsEnabled || lyricsManager.hasLyrics {
                    HStack(spacing: 12) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.islandAccent)
                        
                        if let currentLine = lyricsManager.currentLine, !currentLine.text.isEmpty {
                            Text(currentLine.text)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                        } else {
                            Text("Instrumental or waiting for vocals...")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button("View Lyrics in Apple Music View") {
                            selectedTab = .lyrics
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.islandAccent)
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                }
            } else {
                // Empty Media State
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    Text("No Audio Playing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                    
                    Text("Start playing a song on Apple Music, Spotify, YouTube Music, or any web browser, and it will appear here instantly.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.islandTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 2. Lyrics Tab (Apple Music Experience)
    private var lyricsTabView: some View {
        Group {
            if let item = mediaManager.currentItem {
                HStack(alignment: .top, spacing: 44) {
                    // MARK: - Left: Floating Artwork, Track Info & Centered Controls
                    VStack(alignment: .leading, spacing: 18) {
                        // Floating Artwork with ambient glow & specular border
                        ZStack {
                            if let img = item.artworkImage ?? (item.artworkData.flatMap { NSImage(data: $0) }) {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .blur(radius: 28)
                                    .opacity(0.50)
                                    .offset(y: 8)
                            }
                            
                            ArtworkImageView(
                                artworkData: item.artworkData,
                                artworkImage: item.artworkImage,
                                service: item.service,
                                size: 200,
                                cornerRadius: 18
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.38), radius: 24, x: 0, y: 12)
                        }
                        .frame(width: 200, height: 200)
                        .padding(.top, 2)
                        
                        // Metadata & Source App Badge
                        VStack(alignment: .leading, spacing: 5) {
                            Button(action: { mediaManager.openCurrentSource() }) {
                                HStack(spacing: 5) {
                                    BrandIconView(service: item.service, size: 12)
                                    Text(item.effectiveAppName)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 8, weight: .bold))
                                        .opacity(0.65)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                                .foregroundStyle(Color.white.opacity(0.80))
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 2)
                            
                            Text(item.displayTitle)
                                .font(.system(size: 22, weight: .bold))
                                .tracking(-0.4)
                                .foregroundStyle(Color.white)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(item.artist.isEmpty ? "Unknown Artist" : item.artist)
                                .font(.system(size: 14.5, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.72))
                                .lineLimit(1)
                            
                            if !item.album.isEmpty && item.album.lowercased() != item.displayTitle.lowercased() {
                                Text(item.album)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.40))
                                    .lineLimit(1)
                            }
                        }
                        
                        // Audio Scrubber
                        PlaybackProgressSlider(
                            progress: mediaManager.interpolatedProgress,
                            currentTimeString: mediaManager.formattedCurrentTime,
                            remainingTimeString: mediaManager.formattedRemainingTime,
                            onSeek: { fraction in
                                mediaManager.seek(to: fraction)
                            }
                        )
                        .padding(.top, 2)
                        
                        // Centered Iconic Transport Controls
                        HStack(spacing: 26) {
                            Spacer()
                            
                            Button(action: { mediaManager.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Button(action: { mediaManager.togglePlayPause() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 48, height: 48)
                                        .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
                                    
                                    Image(systemName: mediaManager.playbackState == .playing ? "pause.fill" : "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.black)
                                        .offset(x: mediaManager.playbackState == .playing ? 0 : 1.5)
                                }
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Button(action: { mediaManager.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            .buttonStyle(SpringPressButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        // Unified Frosted Glass Toolbar Capsule
                        HStack(spacing: 0) {
                            // Toggle 1: Notch Lyrics
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    lyricsManager.toggleLyrics()
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: lyricsManager.isLyricsEnabled ? "inset.filled.rectangle.and.cursorarrow" : "rectangle.dashed")
                                        .font(.system(size: 10.5, weight: .semibold))
                                    Text("Notch")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .fixedSize()
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    lyricsManager.isLyricsEnabled ? Capsule().fill(Color.white.opacity(0.20)) : Capsule().fill(Color.clear)
                                )
                                .foregroundStyle(lyricsManager.isLyricsEnabled ? Color.white : Color.white.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 1, height: 14)
                                .padding(.horizontal, 3)
                            
                            // Toggle 2: Romanize
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    lyricsManager.toggleRomanization()
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "character.bubble")
                                        .font(.system(size: 10.5, weight: .semibold))
                                    Text("Romanize")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .fixedSize()
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    lyricsManager.isRomanizationEnabled ? Capsule().fill(Color.white.opacity(0.20)) : Capsule().fill(Color.clear)
                                )
                                .foregroundStyle(lyricsManager.isRomanizationEnabled ? Color.white : Color.white.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 1, height: 14)
                                .padding(.horizontal, 3)
                            
                            // Micro Sync Timing Offset
                            HStack(spacing: 2) {
                                Button(action: { lyricsManager.nudgeSyncOffset(by: -0.1) }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .frame(width: 18, height: 18)
                                        .background(Circle().fill(Color.white.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                                
                                Text(String(format: "%+.1fs", lyricsManager.syncOffset))
                                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.65))
                                    .frame(width: 36)
                                    .fixedSize()
                                
                                Button(action: { lyricsManager.nudgeSyncOffset(by: 0.1) }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .frame(width: 18, height: 18)
                                        .background(Circle().fill(Color.white.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.trailing, 2)
                        }
                        .padding(3)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                    }
                    .frame(width: 280)
                    
                    // MARK: - Right: Immersive Apple Music Lyrics Canvas
                    VStack(alignment: .leading, spacing: 0) {
                        if let lyrics = lyricsManager.currentLyrics, !lyrics.lines.isEmpty {
                            ScrollViewReader { proxy in
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 22) {
                                        // Instrumental Intro Indicator
                                        if (mediaManager.currentItem?.currentProgress() ?? 0) < (lyrics.lines.first?.timestamp ?? 0) {
                                            AppleMusicInstrumentalDotsView()
                                                .padding(.bottom, 8)
                                        }
                                        
                                        ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                                            let isCurrent = (lyricsManager.currentLine?.id == line.id)
                                            AppleMusicLyricLineRow(
                                                line: line,
                                                isCurrent: isCurrent,
                                                onSeek: {
                                                    mediaManager.seek(toSeconds: line.timestamp)
                                                }
                                            )
                                            .id(line.id)
                                            
                                            // Inline Instrumental Dots if a long pause follows this line
                                            if let progress = mediaManager.currentItem?.currentProgress(),
                                               lyricsManager.currentLine == nil,
                                               index + 1 < lyrics.lines.count {
                                                let nextLine = lyrics.lines[index + 1]
                                                let gap = nextLine.timestamp - line.timestamp
                                                if gap > 8.0 && progress >= (line.timestamp + 5.5) && progress < nextLine.timestamp {
                                                    AppleMusicInstrumentalDotsView()
                                                        .padding(.vertical, 8)
                                                        .id("dots_\(line.id)")
                                                }
                                            }
                                        }
                                        
                                        // Instrumental Outro indicator
                                        if let lastLine = lyrics.lines.last, (mediaManager.currentItem?.currentProgress() ?? 0) > (lastLine.timestamp + 6.0) {
                                            AppleMusicInstrumentalDotsView()
                                                .padding(.top, 8)
                                        }
                                    }
                                    .padding(.vertical, 100)
                                    .padding(.trailing, 24)
                                }
                                .mask(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.08),
                                            .init(color: .black, location: 0.90),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .onAppear {
                                    if let current = lyricsManager.currentLine {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                proxy.scrollTo(current.id, anchor: .center)
                                            }
                                        }
                                    }
                                }
                                .onChange(of: lyricsManager.currentLine) { _, newLine in
                                    if let target = newLine {
                                        withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                                            proxy.scrollTo(target.id, anchor: .center)
                                        }
                                    }
                                }
                            }
                        } else if lyricsManager.isLoading {
                            VStack(spacing: 12) {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.1)
                                Text("Searching lyrics...")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.60))
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 14) {
                                Spacer()
                                Image(systemName: "quote.bubble")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.white.opacity(0.30))
                                Text("No Lyrics Available")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                Text("Synchronized lyrics aren't available for this track.")
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Color.white.opacity(0.50))
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Empty Media State
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.white.opacity(0.35))
                    
                    Text("No Audio Playing")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.white)
                    
                    Text("Play a song on Apple Music, Spotify, YouTube Music, or any web browser to experience synchronized lyrics.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if lyricsManager.currentLyrics == nil && !lyricsManager.isLoading {
                lyricsManager.fetchCurrentTrackLyrics()
            }
        }
    }
    
    // MARK: - 3. Focus & Timer Tab
    private var focusTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FOCUS & POMODORO")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    Text("Productivity Timer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                }
                Spacer()
                
                Toggle("Show Ring in Notch", isOn: $pomodoroManager.isTimerInNotchEnabled)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .medium))
            }
            
            HStack(spacing: 24) {
                // Large Timer Dial
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.islandPomodoroTrack, lineWidth: 10)
                            .frame(width: 170, height: 170)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(pomodoroManager.progress))
                            .stroke(
                                Color.islandPomodoroFocus,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 170, height: 170)
                        
                        VStack(spacing: 4) {
                            Text(pomodoroManager.formattedTime)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.islandTextPrimary)
                            
                            Text(pomodoroManager.mode == .focus ? "FOCUS SESSION" : "BREAK")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(Color.islandPomodoroFocus)
                        }
                    }
                    
                    // Controls
                    HStack(spacing: 14) {
                        if !pomodoroManager.isTimerActive {
                            Button("Start Focus") {
                                pomodoroManager.start()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.islandPomodoroFocus)
                        } else if pomodoroManager.timerState == .running {
                            Button("Pause") {
                                pomodoroManager.pause()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Cancel") {
                                pomodoroManager.cancel()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Resume") {
                                pomodoroManager.start()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.islandPomodoroFocus)
                            
                            Button("Reset") {
                                pomodoroManager.cancel()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.islandBorder.opacity(0.3))
                )
                
                // Presets & Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("DURATION PRESETS")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    HStack(spacing: 10) {
                        ForEach([25, 45, 60], id: \.self) { mins in
                            Button("\(mins)m") {
                                pomodoroManager.selectPreset(minutes: mins)
                            }
                            .buttonStyle(.bordered)
                            .tint(pomodoroManager.selectedMinutes == mins ? Color.islandPomodoroFocus : Color.white)
                        }
                    }
                    
                    Divider().overlay(Color.islandDivider)
                    
                    Text("TODAY'S STATS")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(pomodoroManager.completedSessions)")
                                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.islandTextPrimary)
                            Text("Completed Sessions")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.islandTextSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.islandBorder.opacity(0.3))
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - 4. System & Power Tab
    private var systemTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HARDWARE & AUDIO")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.islandTextTertiary)
                
                Text("System Routes & Power")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.islandTextPrimary)
            }
            
            HStack(spacing: 20) {
                // Battery Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: batteryManager.isConnectedToAC ? "battery.100.bolt" : "battery.75")
                            .font(.system(size: 24))
                            .foregroundStyle(batteryManager.isConnectedToAC ? Color.islandBatteryCharging : Color.islandTextPrimary)
                        
                        Spacer()
                        
                        Text(batteryManager.isConnectedToAC ? "Connected to AC" : "Battery Power")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.islandTextSecondary)
                    }
                    
                    Text("\(batteryManager.currentPercentage)%")
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.islandTextPrimary)
                    
                    Text("MacBook Internal Battery")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.islandTextSecondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.islandBorder.opacity(0.3))
                )
                
                // Audio Route Summary Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: routeManager.activeRouteIcon ?? "speaker.wave.2")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.islandAccent)
                        
                        Spacer()
                        
                        Text("Active Output")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.islandTextSecondary)
                    }
                    
                    Text(routeManager.deviceName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                        .lineLimit(1)
                    
                    Text("Click below to manage destination")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.islandTextTertiary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.islandBorder.opacity(0.3))
                )
            }
            
            // Connected Audio Destinations
            VStack(alignment: .leading, spacing: 10) {
                Text("AVAILABLE AUDIO OUTPUTS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.islandTextTertiary)
                
                ForEach(routeManager.availableDevices) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.iconName)
                            .font(.system(size: 16))
                            .foregroundStyle(device.isDefault ? Color.islandAccent : Color.islandTextSecondary)
                            .frame(width: 24)
                        
                        Text(device.name)
                            .font(.system(size: 13, weight: device.isDefault ? .semibold : .regular))
                            .foregroundStyle(Color.islandTextPrimary)
                        
                        Spacer()
                        
                        if device.isDefault {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.islandAccent)
                        } else {
                            Button("Switch") {
                                routeManager.selectOutputDevice(device)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(device.isDefault ? Color.islandControlHover : Color.islandBorder.opacity(0.2))
                    )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - 5. Settings Tab
    private var settingsTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PREFERENCES")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.islandTextTertiary)
                
                Text("Application & Display Mode")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.islandTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // App Mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("APPLICATION PRESENTATION")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Color.islandTextTertiary)
                    
                    // Launch at Login
                    Toggle(isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.islandTextPrimary)
                            Text("Start Mac Island automatically in the background when your Mac turns on or logs in.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.islandTextSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Show in Dock while open
                    Toggle(isOn: Binding(
                        get: { !isAccessoryOnly },
                        set: { showInDock in
                            isAccessoryOnly = !showInDock
                            (NSApp.delegate as? AppDelegate)?.updateActivationPolicy(isAccessory: !showInDock)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Mac Island in macOS Dock & App Switcher")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.islandTextPrimary)
                            Text("When closed, the Dock icon automatically hides while the notch remains active in the background.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.islandTextSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Explicit Quit button
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quit Mac Island")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.islandTextPrimary)
                            Text("Completely exit Mac Island and close the notch.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.islandTextSecondary)
                        }
                        Spacer()
                        Button(action: {
                            (NSApp.delegate as? AppDelegate)?.quitApp()
                        }) {
                            Text("Quit Completely")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.islandBatteryCritical)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.islandBatteryCritical.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.islandBorder.opacity(0.3))
                )
                
                // Mac Island Edition Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EDITION")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(0.5)
                                .foregroundStyle(Color.islandTextTertiary)
                            
                            Text(proManager.isPro ? "Mac Island Pro" : "Mac Island Free")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.islandTextPrimary)
                        }
                        
                        Spacer()
                        
                        Text(proManager.isPro ? "All Pro Features Active" : "All Core Features Unlocked")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.islandTextSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.islandBorder.opacity(0.3))
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - AppleMusicAmbientBackgroundView
// Fluid multi-color chromatic background field sampling dominant album art colors.
// Mimics Apple Music's signature blurred moving atmospheric backdrop.
public struct AppleMusicAmbientBackgroundView: View {
    let mediaItem: MediaItem?
    @State private var animateGlow: Bool = false
    
    public init(mediaItem: MediaItem?) {
        self.mediaItem = mediaItem
    }
    
    public var body: some View {
        ZStack {
            // Deep base foundation
            Color(nsColor: NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1.0))
                .ignoresSafeArea()
            
            if let item = mediaItem, (item.isPlaying || item.artworkData != nil || item.artworkImage != nil) {
                let resolvedArtwork = item.artworkImage ?? (item.artworkData.flatMap { NSImage(data: $0) })
                
                ZStack {
                    // Base: Heavily blurred, gently breathing artwork canvas
                    if let art = resolvedArtwork {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .blur(radius: 70)
                            .scaleEffect(animateGlow ? 1.45 : 1.30)
                            .rotationEffect(.degrees(animateGlow ? 7 : -7))
                            .opacity(0.70)
                            .clipped()
                    }
                    
                    // Layer 2: Radiant Chromatic Fluid Blobs sampling dominant artwork colors
                    let colors = ArtworkColorExtractor.shared.colors(for: item)
                    let c0 = colors.count > 0 ? colors[0] : Color.islandWaveformPeach
                    let c1 = colors.count > 1 ? colors[1] : Color.islandRose
                    let c2 = colors.count > 2 ? colors[2] : Color.islandAccent
                    let c3 = colors.count > 3 ? colors[3] : Color.purple
                    
                    ZStack {
                        // Blob 1: Top Right primary vibrant accent
                        Circle()
                            .fill(c1.opacity(0.55))
                            .frame(width: 580, height: 580)
                            .offset(x: animateGlow ? 190 : 130, y: animateGlow ? -140 : -190)
                            .blur(radius: 85)
                        
                        // Blob 2: Bottom Center/Left foundation tone
                        Circle()
                            .fill(c0.opacity(0.60))
                            .frame(width: 620, height: 620)
                            .offset(x: animateGlow ? -170 : -110, y: animateGlow ? 160 : 110)
                            .blur(radius: 95)
                        
                        // Blob 3: Center transition tone
                        Circle()
                            .fill(c2.opacity(0.45))
                            .frame(width: 480, height: 480)
                            .offset(x: animateGlow ? 80 : -40, y: animateGlow ? 40 : -30)
                            .blur(radius: 80)
                        
                        // Blob 4: Luminous tinted highlight
                        Circle()
                            .fill(c3.opacity(0.35))
                            .frame(width: 420, height: 420)
                            .offset(x: animateGlow ? -190 : -140, y: animateGlow ? -110 : -60)
                            .blur(radius: 75)
                    }
                }
                .animation(.easeInOut(duration: 16.0).repeatForever(autoreverses: true), value: animateGlow)
                .onAppear {
                    animateGlow = true
                }
            } else {
                // Subtle static ambient glow when idle
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 50,
                    endRadius: 550
                )
                .ignoresSafeArea()
            }
            
            // Atmospheric dark overlay scrim ensuring vibrant Apple Music luminescence with crisp contrast
            LinearGradient(
                colors: [
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - AppleMusicLyricLineRow
// Individual lyric line styled after Apple Music's large kinetic typography:
// Features high-contrast active line, optical depth-of-field blur on inactive lines,
// smooth hover preview, and tap-to-seek playback integration.
struct AppleMusicLyricLineRow: View {
    let line: LyricLine
    let isCurrent: Bool
    let onSeek: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSeek) {
            Text(line.text)
                .font(.system(size: isCurrent ? 31 : 23, weight: isCurrent ? .bold : .semibold, design: .default))
                .tracking(isCurrent ? -0.45 : -0.2)
                .foregroundStyle(Color.white)
                .opacity(isCurrent ? 1.0 : (isHovered ? 0.75 : 0.36))
                .scaleEffect(isCurrent ? 1.03 : 1.0, anchor: .leading)
                .shadow(color: isCurrent ? Color.white.opacity(0.28) : Color.clear, radius: 16, x: 0, y: 0)
                .blur(radius: isCurrent ? 0 : (isHovered ? 0 : 0.45))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.07) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isCurrent)
    }
}

// MARK: - AppleMusicInstrumentalDotsView
// Rhythmic pulsing dots displayed during instrumental breaks or track intros,
// matching Apple Music's signature interlude indicator.
struct AppleMusicInstrumentalDotsView: View {
    @State private var phase: Int = 0
    let timer = Timer.publish(every: 0.42, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .opacity(phase == index ? 1.0 : 0.35)
                    .scaleEffect(phase == index ? 1.25 : 0.88)
                    .offset(y: phase == index ? -3 : 0)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.12))
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.68), value: phase)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
