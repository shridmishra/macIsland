import SwiftUI

// MARK: - IslandAnimation
// Design engineering motion system calibrated to Apple's Dynamic Island fluid physics
// and Emil Kowalski's animation principles:
// - Physical springs over fixed-duration easings for living, interruptible UI
// - Critically calibrated damping for zero sluggishness and zero visual hitching
// - Motion-blur masking to eliminate glyph clashing during kinetic text replacement
public enum IslandAnimation {
    /// Apple-grade fluid spring for Dynamic Island geometry morphing (notch width, height, xOffset).
    /// Response 0.40s, dampingFraction 0.82, blendDuration 0.12.
    public static let notchSpring = Animation.spring(response: 0.40, dampingFraction: 0.82, blendDuration: 0.12)
    
    /// Smooth, responsive spring for synchronized lyrics text entry and exit.
    /// Response 0.35s, dampingFraction 0.86, blendDuration 0.10.
    public static let lyricsSpring = Animation.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.10)
    
    /// Quick, snappy spring for state badges, loading indicators, and small icons.
    public static let snappySpring = Animation.spring(response: 0.26, dampingFraction: 0.82)
}

// MARK: - Lyric Transition Modifier
// Provides Emil Kowalski's motion-blur crossfade technique combined with Apple-style
// vertical kinetic text translation and subtle scale settling.
public struct LyricTransitionModifier: ViewModifier {
    public let opacity: Double
    public let offsetY: CGFloat
    public let blurRadius: CGFloat
    public let scale: CGFloat
    
    public init(opacity: Double, offsetY: CGFloat, blurRadius: CGFloat, scale: CGFloat) {
        self.opacity = opacity
        self.offsetY = offsetY
        self.blurRadius = blurRadius
        self.scale = scale
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blurRadius)
            .scaleEffect(scale, anchor: .leading)
            .offset(y: offsetY)
    }
}

extension AnyTransition {
    /// Kinetic blur-slide transition for synchronized lyric lines:
    /// - Entering line slides up from below (+7pt -> 0), defogging from 3.5pt blur to crisp focus.
    /// - Departing line drifts upward (-7pt), dissolving into a 3.5pt blur mist.
    /// Completely avoids glyph clashing and double-vision artifacts.
    public static var lyricBlurSlide: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: LyricTransitionModifier(opacity: 0.0, offsetY: 7.0, blurRadius: 3.5, scale: 0.98),
                identity: LyricTransitionModifier(opacity: 1.0, offsetY: 0.0, blurRadius: 0.0, scale: 1.0)
            ),
            removal: .modifier(
                active: LyricTransitionModifier(opacity: 0.0, offsetY: -7.0, blurRadius: 3.5, scale: 0.98),
                identity: LyricTransitionModifier(opacity: 1.0, offsetY: 0.0, blurRadius: 0.0, scale: 1.0)
            )
        )
    }
}
