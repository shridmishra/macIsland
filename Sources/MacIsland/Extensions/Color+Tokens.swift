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
    
    /// Skeleton shimmer base fill (subtle translucent gray)
    public static let islandSkeletonBase = Color.white.opacity(0.08)
    
    /// Skeleton shimmer highlight band (brighter pulse sweep)
    public static let islandSkeletonHighlight = Color.white.opacity(0.18)
    
    // MARK: - Battery & Power State Tokens
    /// Dynamic Island active charging green
    public static let islandBatteryCharging = Color(nsColor: NSColor.systemGreen)
    
    /// Battery full / charge limit reached emerald green
    public static let islandBatteryFull = Color(nsColor: NSColor.systemGreen)
    
    /// Low battery warning amber/orange
    public static let islandBatteryLow = Color(nsColor: NSColor.systemOrange)
    
    /// Critical battery warning red
    public static let islandBatteryCritical = Color(nsColor: NSColor.systemRed)
    
    /// Disconnected charger icon/text subtle color
    public static let islandBatteryDisconnected = Color.white.opacity(0.85)
    
    // MARK: - Pomodoro & Calendar Tokens
    /// Pomodoro focus mode vibrant coral/orange accent
    public static let islandPomodoroFocus = Color(nsColor: NSColor.systemOrange)
    
    /// Pomodoro short break refreshing mint/green accent
    public static let islandPomodoroBreak = Color(nsColor: NSColor.systemGreen)
    
    /// Pomodoro long break calm cyan/teal accent
    public static let islandPomodoroLongBreak = Color(nsColor: NSColor.systemTeal)
    
    /// Pomodoro progress ring track background
    public static let islandPomodoroTrack = Color.white.opacity(0.12)
    
    /// Calendar today highlight background fill
    public static let islandCalendarTodayFill = Color.white
    
    /// Calendar today highlight high-contrast text color
    public static let islandCalendarTodayText = Color.black
    
    /// Calendar day outside current month
    public static let islandCalendarOutsideMonth = Color.white.opacity(0.20)
    
    /// Calendar weekday header text
    public static let islandCalendarWeekdayText = Color.white.opacity(0.40)
    
    /// Calendar selected date ring/accent
    public static let islandCalendarSelectedBorder = Color.white.opacity(0.60)
    
    /// Vertical divider separating island split views
    public static let islandDivider = Color.white.opacity(0.10)
    
    // MARK: - Red Monthly Calendar Tokens (matching Screenshot)
    /// Signature month header & today's badge (using our light pink brand color)
    public static let islandCalendarRed = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Sunday column dimmed text color
    public static let islandCalendarSunday = Color.white.opacity(0.55)
    
    /// Weekday column header text color
    public static let islandCalendarWeekday = Color.white.opacity(0.60)
    
    // MARK: - Pomodoro Ruler & Pill Tokens (matching UI specs)
    /// Dark translucent background track for the timer scrubber ruler
    public static let islandRulerTrack = Color.white.opacity(0.08)
    
    /// Subtle vertical tick lines inside the timer ruler
    public static let islandRulerTick = Color.white.opacity(0.20)
    
    /// Idle indicator needle (crisp white)
    public static let islandRulerNeedleIdle = Color.white
    
    /// Active countdown indicator needle (our light pink brand color)
    public static let islandRulerNeedleActive = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Light pink capsule pill badge background for collapsed wing
    public static let islandPillBackground = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Dark text inside collapsed pill badge
    public static let islandPillText = Color(nsColor: NSColor(red: 0.12, green: 0.04, blue: 0.08, alpha: 1.0))
    
    /// Preset button active text
    public static let islandPresetActive = Color.white
    
    /// Preset button inactive text
    public static let islandPresetInactive = Color.white.opacity(0.55)
    
    /// Subtle button / ellipsis action color
    public static let islandActionEllipsis = Color.white.opacity(0.40)
    
    /// Large countdown timer font color (crisp white)
    public static let islandTimerLargeText = Color.white
    
    // MARK: - Mac Island Light Pink Signature Brand Tokens
    /// Light pastel pink (hero-pink-mid #FBAFD0 rgb(251, 175, 208))
    public static let islandPinkLight = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Soft translucent pink for subtle ambient background
    public static let islandPinkSubtle = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 0.06))
    
    /// Dark contrasting text for light pink buttons
    public static let islandPinkOnText = Color(nsColor: NSColor(red: 0.12, green: 0.04, blue: 0.08, alpha: 1.0))
    
    // MARK: - Focus Tuner Tokens (Restrained Monochrome + Light Pink Accent)
    /// Primary accent using our light pink color
    public static let islandFocusAccent = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Light pink pill button fill
    public static let islandFocusButtonFill = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Dark text on light pink button
    public static let islandFocusButtonText = Color(nsColor: NSColor(red: 0.12, green: 0.04, blue: 0.08, alpha: 1.0))
    
    /// Subtle monochrome numbers above the ruler ticks
    public static let islandFocusRulerNumber = Color.white.opacity(0.60)
    
    /// Main monochrome vertical ticks (multiples of 5)
    public static let islandFocusRulerTick = Color.white.opacity(0.40)
    
    /// Shorter intermediate monochrome vertical ticks
    public static let islandFocusRulerTickSubtle = Color.white.opacity(0.18)
    
    /// Light pink upward triangle cursor needle
    public static let islandFocusIndicator = Color(nsColor: NSColor(red: 0.984, green: 0.686, blue: 0.816, alpha: 1.0))
    
    /// Clean crisp white digital clock digits
    public static let islandFocusDigits = Color.white
    
    /// Dark translucent circle background for cancel/close button
    public static let islandFocusCloseBackground = Color.white.opacity(0.16)
    
    /// White X icon for close button
    public static let islandFocusCloseIcon = Color.white.opacity(0.85)
    
    /// Muted "Timer" label text next to digits
    public static let islandFocusTimerLabel = Color.white.opacity(0.50)
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
