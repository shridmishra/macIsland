import SwiftUI

// MARK: - MediaControlButtons
// Native playback controls: Previous, Play/Pause toggle, and Next.
// Clean, flat, borderless and shadowless to match the pure black aesthetic.
public struct MediaControlButtons: View {
    public let isPlaying: Bool
    public let onPrevious: () -> Void
    public let onTogglePlayPause: () -> Void
    public let onNext: () -> Void
    
    @State private var hoverPrevious = false
    @State private var hoverPlayPause = false
    @State private var hoverNext = false
    @State private var hoverDevice = false
    
    public init(
        isPlaying: Bool,
        onPrevious: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.onPrevious = onPrevious
        self.onTogglePlayPause = onTogglePlayPause
        self.onNext = onNext
    }
    
    public var body: some View {
        ZStack {
            // Centered playback controls: Previous, Play/Pause, Next
            HStack(spacing: 38) {
                // Previous button
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.islandTextPrimary.opacity(hoverPrevious ? 1.0 : 0.85))
                        .scaleEffect(hoverPrevious ? 1.08 : 1.0)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hoverPrevious = $0 }
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoverPrevious)
                
                // Play / Pause prominent flat icon
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.islandTextPrimary)
                        .scaleEffect(hoverPlayPause ? 1.08 : 1.0)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hoverPlayPause = $0 }
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoverPlayPause)
                
                // Next button
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.islandTextPrimary.opacity(hoverNext ? 1.0 : 0.85))
                        .scaleEffect(hoverNext ? 1.08 : 1.0)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hoverNext = $0 }
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoverNext)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Right-aligned audio output destination icon (AirPods)
            HStack {
                Spacer()
                
                Button(action: {
                    openSoundSettings()
                }) {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.islandScrubberMuted.opacity(hoverDevice ? 1.0 : 0.75))
                        .scaleEffect(hoverDevice ? 1.06 : 1.0)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hoverDevice = $0 }
                .help("Audio Output Settings")
            }
        }
        .frame(height: 34)
    }
    
    private func openSoundSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "/System/Library/PreferencePanes/Sound.prefPane") {
            NSWorkspace.shared.open(url)
        }
    }
}
