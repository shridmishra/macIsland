import SwiftUI

// MARK: - MediaControlButtons
// Native playback controls matching Apple Dynamic Island:
// Previous, frameless Play/Pause glyph, Next, and right-aligned audio route icon.
public struct MediaControlButtons: View {
    public let isPlaying: Bool
    public let onPrevious: () -> Void
    public let onTogglePlayPause: () -> Void
    public let onNext: () -> Void
    
    @State private var hoverPrevious = false
    @State private var hoverPlayPause = false
    @State private var hoverNext = false
    
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
            // Centered playback buttons: Previous | Play/Pause | Next
            HStack(spacing: 32) {
                // Previous button
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.white.opacity(hoverPrevious ? 1.0 : 0.85))
                        .scaleEffect(hoverPrevious ? 1.08 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hoverPrevious = $0 }
                
                // Play / Pause frameless glyph
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(hoverPlayPause ? 1.10 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hoverPlayPause = $0 }
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: hoverPlayPause)
                
                // Next button
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.white.opacity(hoverNext ? 1.0 : 0.85))
                        .scaleEffect(hoverNext ? 1.08 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hoverNext = $0 }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Audio destination route icon aligned to the far right (AirPods / Headphones)
            HStack {
                Spacer()
                Image(systemName: "airpodspro")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.40))
            }
        }
        .frame(height: 26)
    }
}
