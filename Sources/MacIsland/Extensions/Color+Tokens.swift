import SwiftUI

// MARK: - Semantic Color Tokens
// Designed for authentic macOS Transparent Liquid Glass UI.
// Highly translucent vibrant glass allowing wallpapers and desktop windows to refract through.
extension Color {
    /// Highly translucent frosted glass tint (~80% transparent)
    public static let islandSurface = Color(nsColor: NSColor(deviceWhite: 0.12, alpha: 0.20))
    
    /// Specular reflection on the glass surface
    public static let islandGlassHighlight = Color.white.opacity(0.20)
    
    /// Subtle inner border/ring highlighting the glass edge
    public static let islandBorder = Color.white.opacity(0.25)
    
    /// Primary high-contrast label color (track title, icons)
    public static let islandTextPrimary = Color.white
    
    /// Secondary muted label color (artist, elapsed time)
    public static let islandTextSecondary = Color.white.opacity(0.75)
    
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
    public static let islandBadgeBackground = Color.white.opacity(0.14)
    
    /// App source pill badge border
    public static let islandBadgeBorder = Color.white.opacity(0.22)
}

extension ShapeStyle where Self == LinearGradient {
    /// Apple-style polished glass rim highlight
    public static var islandRimBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.40),
                Color.white.opacity(0.18),
                Color.white.opacity(0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Transparent Glass View Modifier
public struct TransparentGlassModifier: ViewModifier {
    public let cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // System blur material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Translucent glass tint
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.islandSurface)
                    
                    // Specular light reflection on top glass edge
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.islandGlassHighlight, Color.clear],
                                startPoint: .top,
                                endPoint: .center
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
    public func transparentGlass(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(TransparentGlassModifier(cornerRadius: cornerRadius))
    }
}
