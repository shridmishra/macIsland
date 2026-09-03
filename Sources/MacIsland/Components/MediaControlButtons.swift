import SwiftUI

// MARK: - MediaControlButtons
// Native playback controls matching Apple Dynamic Island:
// Previous, frameless Play/Pause glyph with symbol replacement transitions,
// Next, tactile SpringPressButtonStyle with trackpad haptics,
// and dynamic audio route icon (only displayed when external headphones/AirPods are connected).
public struct MediaControlButtons: View {
    public let isPlaying: Bool
    public let audioRouteIcon: String?
    public let onPrevious: () -> Void
    public let onTogglePlayPause: () -> Void
    public let onNext: () -> Void
    
    @State private var hoverPrevious = false
    @State private var hoverNext = false
    
    public init(
        isPlaying: Bool,
        audioRouteIcon: String? = nil,
        onPrevious: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.audioRouteIcon = audioRouteIcon
        self.onPrevious = onPrevious
        self.onTogglePlayPause = onTogglePlayPause
        self.onNext = onNext
    }
    
    public var body: some View {
        ZStack {
            // Centered playback buttons: Previous | Play/Pause | Next
            HStack(spacing: 32) {
                // Previous button with tactile press feedback
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.white.opacity(hoverPrevious ? 1.0 : 0.85))
                }
                .buttonStyle(.springPress(scale: 0.88))
                .onHover { hoverPrevious = $0 }
                
                // Play / Pause frameless glyph with SF Symbol smooth transition
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.springPress(scale: 0.90))
                
                // Next button with tactile press feedback
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.white.opacity(hoverNext ? 1.0 : 0.85))
                }
                .buttonStyle(.springPress(scale: 0.88))
                .onHover { hoverNext = $0 }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Audio destination route icon (only rendered if external device like AirPods is connected!)
            if let iconName = audioRouteIcon {
                HStack {
                    Spacer()
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.40))
                }
            }
        }
        .frame(height: 26)
    }
}
