import SwiftUI

// MARK: - Semantic Color Tokens
// Designed for authentic macOS Liquid Frosted Glass UI.
// Translucent vibrant glass allowing desktop and menu bar wallpapers to refract naturally.
extension Color {
    /// Translucent frosted glass tint (allows system ultraThinMaterial to refract beautifully)
    public static let islandSurface = Color(nsColor: NSColor(deviceWhite: 0.08, alpha: 0.45))
    
    /// Specular inner highlight for glass refraction
    public static let islandGlassHighlight = Color.white.opacity(0.14)
    
    /// Subtle inner border/ring highlighting the glass edge
    public static let islandBorder = Color.white.opacity(0.20)
    
    /// Primary high-contrast label color (track title, icons)
    public static let islandTextPrimary = Color.white
    
    /// Secondary muted label color (artist, elapsed time)
    public static let islandTextSecondary = Color.white.opacity(0.72)
    
    /// Tertiary subtle color (timestamps, placeholder icons)
    public static let islandTextTertiary = Color.white.opacity(0.48)
    
    /// Dynamic Island accent color (used for play progress and active equalizer bars)
    public static let islandAccent = Color(nsColor: NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0))
    
    /// Subtle track background for progress bars
    public static let islandProgressTrack = Color.white.opacity(0.16)
    
    /// Active filled progress bar
    public static let islandProgressFill = Color.white.opacity(0.92)
    
    /// Subtle button and interactive hover background
    public static let islandControlHover = Color.white.opacity(0.15)
    
    /// App source pill badge background
    public static let islandBadgeBackground = Color.white.opacity(0.12)
    
    /// App source pill badge border
    public static let islandBadgeBorder = Color.white.opacity(0.18)
}

extension ShapeStyle where Self == LinearGradient {
    /// Apple-style rim highlight gradient for the glass border
    public static var islandRimBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.32),
                Color.white.opacity(0.14),
                Color.white.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
