import SwiftUI
import AppKit

// MARK: - Semantic Color Tokens
// Designed to merge seamlessly with the MacBook hardware camera notch:
// Pure pitch-black background (#000000) that makes the physical cutout and the digital island
// indistinguishable from each other, just like Apple's Dynamic Island.
extension Color {
    /// Pure pitch-black surface to merge seamlessly with the hardware camera notch
    public static let islandSurface = Color.black
    
    /// Subtle inner border/ring highlighting the island edge
    public static let islandBorder = Color.white.opacity(0.14)
    
    /// Primary high-contrast label color (track title, icons)
    public static let islandTextPrimary = Color.white
    
    /// Secondary muted label color (artist, elapsed time)
    public static let islandTextSecondary = Color.white.opacity(0.70)
    
    /// Tertiary subtle color (timestamps, placeholder icons)
    public static let islandTextTertiary = Color.white.opacity(0.45)
    
    /// Dynamic Island accent color (used for play progress and active equalizer bars)
    public static let islandAccent = Color(nsColor: NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0))
    
    /// Subtle track background for progress bars
    public static let islandProgressTrack = Color.white.opacity(0.18)
    
    /// Active filled progress bar
    public static let islandProgressFill = Color.white
    
    /// Subtle button and interactive hover background
    public static let islandControlHover = Color.white.opacity(0.15)
    
    /// App source pill badge background
    public static let islandBadgeBackground = Color.white.opacity(0.12)
    
    /// App source pill badge border
    public static let islandBadgeBorder = Color.white.opacity(0.16)
    
    /// iOS Now Playing warm waveform terracotta/peach tone
    public static let islandWaveformPeach = Color(nsColor: NSColor(red: 0.85, green: 0.54, blue: 0.44, alpha: 1.0))
    
    /// iOS Now Playing scrubber secondary muted text and device icons
    public static let islandScrubberMuted = Color.white.opacity(0.55)
    
    /// iOS Now Playing scrubber active progress fill
    public static let islandScrubberFill = Color.white.opacity(0.80)
}

extension ShapeStyle where Self == LinearGradient {
    /// Apple Dynamic Island polished rim border
    public static var islandRimBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.22),
                Color.white.opacity(0.10),
                Color.white.opacity(0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
