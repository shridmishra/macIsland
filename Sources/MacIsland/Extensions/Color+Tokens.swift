import SwiftUI

// MARK: - Semantic Color Tokens
// In macOS native development (like in web design systems), we define semantic color tokens
// so components never hardcode arbitrary hex values.
// These adapt gracefully to dark mode and translucent vibrant materials.
extension Color {
    /// Deep dark glass surface for the Island capsule/card
    public static let islandSurface = Color(nsColor: NSColor(deviceWhite: 0.06, alpha: 0.92))
    
    /// Subtle inner border/ring highlighting the glass edge
    public static let islandBorder = Color.white.opacity(0.16)
    
    /// Primary high-contrast label color (track title, icons)
    public static let islandTextPrimary = Color.white
    
    /// Secondary muted label color (artist, elapsed time)
    public static let islandTextSecondary = Color.white.opacity(0.70)
    
    /// Tertiary subtle color (timestamps, placeholder icons)
    public static let islandTextTertiary = Color.white.opacity(0.45)
    
    /// Dynamic Island accent color (used for play progress and active equalizer bars)
    public static let islandAccent = Color(nsColor: NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0))
    
    /// Subtle track background for progress bars
    public static let islandProgressTrack = Color.white.opacity(0.14)
    
    /// Active filled progress bar
    public static let islandProgressFill = Color.white.opacity(0.88)
    
    /// Subtle button and interactive hover background
    public static let islandControlHover = Color.white.opacity(0.12)
    
    /// App source pill badge background
    public static let islandBadgeBackground = Color.white.opacity(0.10)
    
    /// App source pill badge border
    public static let islandBadgeBorder = Color.white.opacity(0.12)
}

extension ShapeStyle where Self == LinearGradient {
    /// Apple-style rim highlight gradient for the island border
    public static var islandRimBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.10),
                Color.white.opacity(0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
