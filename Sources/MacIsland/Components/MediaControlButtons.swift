import SwiftUI

// MARK: - MediaControlButtons
// Native playback controls: Previous, Play/Pause toggle, and Next.
// Includes subtle hover feedback and Apple-style tactile click feel.
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
        HStack(spacing: 24) {
            // Previous button
            Button(action: onPrevious) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary.opacity(hoverPrevious ? 1.0 : 0.70))
                    .frame(width: 28, height: 28)
                    .background(hoverPrevious ? Color.islandControlHover : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { hoverPrevious = $0 }
            
            // Play / Pause prominent button
            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.95))
                    .clipShape(Circle())
                    .scaleEffect(hoverPlayPause ? 1.06 : 1.0)
                    .shadow(color: Color.black.opacity(0.20), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
            .onHover { hoverPlayPause = $0 }
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: hoverPlayPause)
            
            // Next button
            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary.opacity(hoverNext ? 1.0 : 0.70))
                    .frame(width: 28, height: 28)
                    .background(hoverNext ? Color.islandControlHover : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { hoverNext = $0 }
        }
    }
}
