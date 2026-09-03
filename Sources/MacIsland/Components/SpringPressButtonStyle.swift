import SwiftUI
import AppKit

// MARK: - SpringPressButtonStyle
// Apple-grade fluid button style conforming to SwiftUI's ButtonStyle protocol.
// Encodes core WWDC fluid motion principles:
// 1. Instant response on pointer-down (scale: 0.90, opacity: 0.82)
// 2. Physical spring return (response: 0.20s, dampingFraction: 0.68)
// 3. Native macOS trackpad haptic feedback on press
public struct SpringPressButtonStyle: ButtonStyle {
    public var pressedScale: CGFloat
    public var hasHaptic: Bool
    
    public init(pressedScale: CGFloat = 0.90, hasHaptic: Bool = true) {
        self.pressedScale = pressedScale
        self.hasHaptic = hasHaptic
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.68), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hasHaptic {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }
            }
    }
}

public extension ButtonStyle where Self == SpringPressButtonStyle {
    static var springPress: SpringPressButtonStyle {
        SpringPressButtonStyle()
    }
    
    static func springPress(scale: CGFloat = 0.90, haptic: Bool = true) -> SpringPressButtonStyle {
        SpringPressButtonStyle(pressedScale: scale, hasHaptic: haptic)
    }
}
