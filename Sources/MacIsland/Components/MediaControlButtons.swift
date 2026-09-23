import SwiftUI

// MARK: - MediaControlButtons
// Native playback controls matching Apple Dynamic Island:
// Previous, frameless Play/Pause glyph with symbol replacement transitions,
// Next, tactile SpringPressButtonStyle with trackpad haptics,
// and dynamic audio route icon (only displayed when external headphones/AirPods are connected).
@MainActor
public struct MediaControlButtons: View {
    public let isPlaying: Bool
    public let isLyricsEnabled: Bool
    public let showLyricsButton: Bool
    public let audioRouteIcon: String?
    public let onPrevious: () -> Void
    public let onTogglePlayPause: () -> Void
    public let onNext: () -> Void
    public let onToggleLyrics: () -> Void
    public let onSelectAudioRoute: () -> Void
    
    @State private var hoverPrevious = false
    @State private var hoverNext = false
    @State private var hoverLyrics = false
    @State private var hoverRoute = false
    
    public init(
        isPlaying: Bool,
        isLyricsEnabled: Bool = false,
        showLyricsButton: Bool = true,
        audioRouteIcon: String? = nil,
        onPrevious: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onToggleLyrics: @escaping () -> Void = {},
        onSelectAudioRoute: @escaping () -> Void = {
            Task { @MainActor in
                WindowManager.shared.openAudioRoutePicker()
            }
        }
    ) {
        self.isPlaying = isPlaying
        self.isLyricsEnabled = isLyricsEnabled
        self.showLyricsButton = showLyricsButton
        self.audioRouteIcon = audioRouteIcon
        self.onPrevious = onPrevious
        self.onTogglePlayPause = onTogglePlayPause
        self.onNext = onNext
        self.onToggleLyrics = onToggleLyrics
        self.onSelectAudioRoute = onSelectAudioRoute
    }
    
    public var body: some View {
        ZStack {
            // Left side: Lyrics Toggle Button (only displayed for music services)
            if showLyricsButton {
                HStack {
                    Button(action: onToggleLyrics) {
                        Image(systemName: isLyricsEnabled ? "quote.bubble.fill" : "quote.bubble")
                            .font(.system(size: 13.5, weight: isLyricsEnabled ? .bold : .medium))
                            .foregroundStyle(isLyricsEnabled ? Color.islandTextPrimary : Color.white.opacity(hoverLyrics ? 0.85 : 0.48))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.springPress(scale: 0.88))
                    .onHover { hoverLyrics = $0 }
                    .help(isLyricsEnabled ? "Hide Lyrics" : "Show Lyrics")
                    .padding(.leading, 8)
                    
                    Spacer()
                }
            }
            
            // Centered playback buttons: Previous | Play/Pause | Next
            HStack(spacing: 26) {
                // Previous button with tactile press feedback
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(hoverPrevious ? 1.0 : 0.85))
                }
                .buttonStyle(.springPress(scale: 0.88))
                .onHover { hoverPrevious = $0 }
                
                // Play / Pause frameless glyph with SF Symbol smooth transition
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.springPress(scale: 0.90))
                
                // Next button with tactile press feedback
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(hoverNext ? 1.0 : 0.85))
                }
                .buttonStyle(.springPress(scale: 0.88))
                .onHover { hoverNext = $0 }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Right side: Audio destination route button (Mac / AirPods / Headphones)
            if let iconName = audioRouteIcon {
                HStack {
                    Spacer()
                    Button(action: onSelectAudioRoute) {
                        Image(systemName: iconName)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(hoverRoute ? 0.95 : 0.48))
                            .offset(y: 1) // Optically centered with transport controls
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(hoverRoute ? 0.12 : 0.0))
                            )
                    }
                    .buttonStyle(.springPress(scale: 0.88, haptic: true))
                    .onHover { isHovered in
                        hoverRoute = isHovered
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .help("Audio Output & AirPods Settings")
                }
            }
        }
        .frame(height: 22)
    }
}
