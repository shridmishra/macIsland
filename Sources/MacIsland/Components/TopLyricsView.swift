import SwiftUI

// MARK: - TopLyricsView
// Displays real-time synchronized lyrics at the very top of Mac Island (the notch / menu bar level).
// Features:
// - ACTIVE SINGING: Pure, high-contrast lyrics text ONLY (tune icon removed)
// - NO LYRICS NOTICE: Displays "No lyrics" for 5 seconds before gracefully reverting to audio pulse
// - INSTRUMENTAL / BEAT PLAYING: Animated musical note icon that grooves to the beat
// - LOADING: Clean, non-clipping loading indicator
public struct TopLyricsView: View {
    @ObservedObject var lyricsManager = LyricsManager.shared
    public let isPlaying: Bool
    
    public init(isPlaying: Bool = true, maxWidth: CGFloat = 0) {
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        Group {
            if isPlaying {
                HStack(spacing: 6) {
                    if lyricsManager.isLoading {
                        // Robust loading indicator that fits smoothly
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.55)
                                .frame(width: 12, height: 12)
                            
                            Text("Loading...")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.islandTextSecondary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .transition(.opacity)
                    } else if lyricsManager.showNoLyricsNotice {
                        // "No lyrics" text displayed for 5 seconds before transitioning to audio pulse
                        Text("No lyrics")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.80))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .transition(.opacity)
                    } else if let line = lyricsManager.currentLine, !line.text.isEmpty {
                        // ACTIVE SINGING: Clean kinetic typography with blur-slide transition
                        Text(line.text)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Color.islandTextPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .id("\(line.id.uuidString)-\(line.text)")
                            .transition(.lyricBlurSlide)
                    } else {
                        // ONLY MUSIC / INSTRUMENTAL: Animated tune icon grooving with the beat!
                        AnimatedTuneIcon(isPlaying: isPlaying)
                            .transition(.scale(scale: 0.88).combined(with: .opacity))
                    }
                }
                .frame(alignment: .leading)
                .animation(IslandAnimation.lyricsSpring, value: lyricsManager.currentLine?.id)
                .animation(IslandAnimation.lyricsSpring, value: lyricsManager.currentLine?.text)
                .animation(IslandAnimation.snappySpring, value: lyricsManager.isLoading)
                .animation(IslandAnimation.snappySpring, value: lyricsManager.showNoLyricsNotice)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - AnimatedTuneIcon
// Rhythmic musical note icon that pulses and sways when the beat is actively playing.
struct AnimatedTuneIcon: View {
    let isPlaying: Bool
    @State private var isPulsing = false
    
    var body: some View {
        Image(systemName: "music.note")
            .font(.system(size: 11.5, weight: .bold))
            .foregroundColor(Color.white.opacity(0.90))
            .scaleEffect(isPlaying ? (isPulsing ? 1.18 : 0.88) : 1.0)
            .rotationEffect(.degrees(isPlaying ? (isPulsing ? 7 : -5) : 0))
            .animation(
                isPlaying ? .easeInOut(duration: 0.50).repeatForever(autoreverses: true) : .easeInOut(duration: 0.2),
                value: isPulsing
            )
            .onAppear {
                if isPlaying {
                    isPulsing = true
                }
            }
            .onChange(of: isPlaying) { _, playing in
                isPulsing = playing
            }
    }
}
