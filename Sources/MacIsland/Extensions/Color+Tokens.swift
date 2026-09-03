import SwiftUI
import AppKit

// MARK: - Semantic Color Tokens
// Designed for authentic macOS Transparent Liquid Glass UI.
// Highly translucent vibrant glass allowing wallpapers and desktop windows to refract through.
extension Color {
    /// Highly translucent frosted glass tint
    public static let islandSurface = Color.white.opacity(0.06)
    
    /// Specular reflection on the glass surface
    public static let islandGlassHighlight = Color.white.opacity(0.25)
    
    /// Subtle inner border/ring highlighting the glass edge
    public static let islandBorder = Color.white.opacity(0.28)
    
    /// Primary high-contrast label color (track title, icons)
    public static let islandTextPrimary = Color.white
    
    /// Secondary muted label color (artist, elapsed time)
    public static let islandTextSecondary = Color.white.opacity(0.72)
    
    /// Tertiary subtle color (timestamps, placeholder icons)
    public static let islandTextTertiary = Color.white.opacity(0.50)
    
    /// Dynamic Island accent color (used for play progress and active equalizer bars)
    public static let islandAccent = Color(nsColor: NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0))
    
    /// Subtle track background for progress bars
    public static let islandProgressTrack = Color.white.opacity(0.18)
    
    /// Active filled progress bar
    public static let islandProgressFill = Color.white.opacity(0.95)
    
    /// Subtle button and interactive hover background
    public static let islandControlHover = Color.white.opacity(0.18)
    
    /// App source pill badge background
    public static let islandBadgeBackground = Color.white.opacity(0.12)
    
    /// App source pill badge border
    public static let islandBadgeBorder = Color.white.opacity(0.20)
}

extension ShapeStyle where Self == LinearGradient {
    /// Apple-style polished glass rim highlight
    public static var islandRimBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.45),
                Color.white.opacity(0.16),
                Color.white.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Transparent Glass View Modifier
// Utilizes AppKit's NSVisualEffectView with `.behindWindow` blending mode and `.popover` material
// to ensure macOS WindowServer dynamically samples and blurs whatever is behind the window.
public struct TransparentGlassModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let material: NSVisualEffectView.Material
    
    public init(cornerRadius: CGFloat = 16, material: NSVisualEffectView.Material = .popover) {
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // True macOS behind-window GPU compositor glass blur
                    VisualEffectView(
                        material: material,
                        blendingMode: .behindWindow,
                        state: .active,
                        cornerRadius: cornerRadius
                    )
                    
                    // Translucent specular glass sheen
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LinearGradient.islandRimBorder, lineWidth: 0.75)
            )
    }
}

extension View {
    public func transparentGlass(
        cornerRadius: CGFloat = 16,
        material: NSVisualEffectView.Material = .popover
    ) -> some View {
        self.modifier(TransparentGlassModifier(cornerRadius: cornerRadius, material: material))
    }
}
