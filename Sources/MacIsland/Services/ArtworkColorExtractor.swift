import Cocoa
import SwiftUI

// MARK: - ArtworkColorExtractor
// High-performance, low-latency color extraction engine for macOS Island.
// Samples album art, streaming service logos, or application icons and resolves
// the optimal vibrant accent color for the audio visualizer pulse.
// Results are cached in-memory with NSCache for instantaneous 0ms subsequent lookups.
public final class ArtworkColorExtractor: @unchecked Sendable {
    public static let shared = ArtworkColorExtractor()
    
    // In-memory cache keyed by unique item or artwork signatures
    private let paletteCache = NSCache<NSString, NSArray>()
    private let appIconCache = NSCache<NSString, NSImage>()
    
    private init() {}
    
    // MARK: - Multi-Color Palette Resolution
    /// Resolves the pulse accent gradient palette (2 to 4 colors) for a MediaItem:
    /// 1. Album Artwork (`artworkData`)
    /// 2. Streaming Service Logo / Signature Palette (if `service != .generic`)
    /// 3. Application Icon (e.g. Brave lion orange, Safari blue, Chrome multi-color)
    /// 4. Fallback vibrant multi-color gradient
    public func colors(for item: MediaItem) -> [Color] {
        let cacheKey = cacheKey(for: item)
        if let cached = paletteCache.object(forKey: cacheKey as NSString) as? [NSColor], !cached.isEmpty {
            return cached.map { Color(nsColor: $0) }
        }
        
        // 1. Recognized Video Streaming Service: strictly prioritize iconic brand pulse colors
        // (Prime Video Cyan Blue, Netflix Red, Disney+ Royal Blue, etc.) so video scene frames don't distort it!
        if item.service.isVideoService {
            let srvPalette = servicePalette(for: item.service)
            paletteCache.setObject(srvPalette as NSArray, forKey: cacheKey as NSString)
            return srvPalette.map { Color(nsColor: $0) }
        }
        
        // 2. Album Artwork (for Music items)
        if let data = item.artworkData,
           let image = NSImage(data: data) {
            let extracted = dominantPalette(from: image)
            if !extracted.isEmpty {
                paletteCache.setObject(extracted as NSArray, forKey: cacheKey as NSString)
                return extracted.map { Color(nsColor: $0) }
            }
        }
        
        // 3. Recognized Music Streaming Service
        if item.service != .generic {
            let srvPalette = servicePalette(for: item.service)
            paletteCache.setObject(srvPalette as NSArray, forKey: cacheKey as NSString)
            return srvPalette.map { Color(nsColor: $0) }
        }
        
        // 4. Application Icon (Brave, Chrome, Safari, etc.)
        if let appIcon = appIcon(for: item.bundleIdentifier, appName: item.application) {
            let extracted = dominantPalette(from: appIcon)
            if !extracted.isEmpty {
                paletteCache.setObject(extracted as NSArray, forKey: cacheKey as NSString)
                return extracted.map { Color(nsColor: $0) }
            }
        }
        
        // 5. Default Fallback Palette (Approved fluid harmonic gradient: rich crimson -> flame orange -> golden amber -> soft peach glow)
        let fallbackPalette: [NSColor] = [
            NSColor(srgbRed: 0.70, green: 0.22, blue: 0.15, alpha: 1.0),
            NSColor(srgbRed: 0.95, green: 0.40, blue: 0.18, alpha: 1.0),
            NSColor(srgbRed: 1.00, green: 0.70, blue: 0.30, alpha: 1.0),
            NSColor(srgbRed: 1.00, green: 0.92, blue: 0.82, alpha: 1.0)
        ]
        paletteCache.setObject(fallbackPalette as NSArray, forKey: cacheKey as NSString)
        return fallbackPalette.map { Color(nsColor: $0) }
    }
    
    /// Single dominant color for backwards compatibility
    public func color(for item: MediaItem) -> Color {
        colors(for: item).first ?? Color.islandWaveformPeach
    }
    
    // MARK: - Streaming Service Signature Palettes
    private func servicePalette(for service: MediaService) -> [NSColor] {
        switch service {
        case .spotify:
            return [
                NSColor(srgbRed: 0.06, green: 0.45, blue: 0.20, alpha: 1.0), // Deep Forest Green #0F7333
                NSColor(srgbRed: 0.11, green: 0.73, blue: 0.33, alpha: 1.0), // Spotify Green #1DB954
                NSColor(srgbRed: 0.20, green: 0.90, blue: 0.45, alpha: 1.0), // Luminous Mint #33E673
                NSColor(srgbRed: 0.85, green: 0.98, blue: 0.90, alpha: 1.0)  // Glowing Mint Highlight
            ]
        case .youtube, .youtubeMusic:
            return [
                NSColor(srgbRed: 0.60, green: 0.05, blue: 0.05, alpha: 1.0), // Deep Crimson #990D0D
                NSColor(srgbRed: 0.98, green: 0.10, blue: 0.10, alpha: 1.0), // YouTube Red #FA1A1A
                NSColor(srgbRed: 1.00, green: 0.50, blue: 0.15, alpha: 1.0), // Flame Gold
                NSColor(srgbRed: 1.00, green: 0.90, blue: 0.80, alpha: 1.0)  // Soft Warm Glow
            ]
        case .appleMusic:
            return [
                NSColor(srgbRed: 0.50, green: 0.08, blue: 0.32, alpha: 1.0), // Deep Violet Wine
                NSColor(srgbRed: 0.98, green: 0.14, blue: 0.24, alpha: 1.0), // Apple Music Red
                NSColor(srgbRed: 1.00, green: 0.45, blue: 0.60, alpha: 1.0), // Radiant Pink
                NSColor(srgbRed: 1.00, green: 0.88, blue: 0.92, alpha: 1.0)  // Soft Blush Glow
            ]
        case .netflix:
            return [
                NSColor(srgbRed: 0.45, green: 0.02, blue: 0.04, alpha: 1.0), // Dark Scarlet #73050A
                NSColor(srgbRed: 0.90, green: 0.04, blue: 0.08, alpha: 1.0), // Netflix Red #E50914
                NSColor(srgbRed: 1.00, green: 0.30, blue: 0.30, alpha: 1.0), // Scarlet Red
                NSColor(srgbRed: 1.00, green: 0.85, blue: 0.85, alpha: 1.0)  // Luminous Rose Glow
            ]
        case .primeVideo:
            return [
                NSColor(srgbRed: 0.00, green: 0.28, blue: 0.52, alpha: 1.0), // Deep Ocean Azure
                NSColor(srgbRed: 0.00, green: 0.66, blue: 0.88, alpha: 1.0), // Prime Blue #00A8E1
                NSColor(srgbRed: 0.35, green: 0.85, blue: 1.00, alpha: 1.0), // Electric Cyan
                NSColor(srgbRed: 0.88, green: 0.96, blue: 1.00, alpha: 1.0)  // Ice Blue Highlight
            ]
        case .disneyPlus:
            return [
                NSColor(srgbRed: 0.02, green: 0.15, blue: 0.45, alpha: 1.0), // Deep Midnight Navy
                NSColor(srgbRed: 0.07, green: 0.39, blue: 0.90, alpha: 1.0), // Disney+ Royal Blue #0063E5
                NSColor(srgbRed: 0.25, green: 0.65, blue: 1.00, alpha: 1.0), // Radiant Sky Blue
                NSColor(srgbRed: 0.85, green: 0.94, blue: 1.00, alpha: 1.0)  // Luminous Glow
            ]
        case .soundcloud:
            return [
                NSColor(srgbRed: 0.65, green: 0.18, blue: 0.00, alpha: 1.0), // Deep Amber Fire
                NSColor(srgbRed: 1.00, green: 0.45, blue: 0.00, alpha: 1.0), // SoundCloud Orange #FF7300
                NSColor(srgbRed: 1.00, green: 0.72, blue: 0.15, alpha: 1.0), // Amber Gold
                NSColor(srgbRed: 1.00, green: 0.92, blue: 0.80, alpha: 1.0)  // Glowing Peach
            ]
        case .x:
            return [
                NSColor(srgbRed: 0.30, green: 0.30, blue: 0.35, alpha: 1.0), // Deep Slate Titanium
                NSColor(srgbRed: 0.90, green: 0.90, blue: 0.95, alpha: 1.0), // Crisp Platinum
                NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0), // Pure Electric White
                NSColor(srgbRed: 0.75, green: 0.78, blue: 0.85, alpha: 1.0)  // Luminous Chrome Glow
            ]
        default:
            let base = NSColor(service.brandColor)
            return [
                NSColor(srgbRed: max(0.2, base.redComponent * 0.7), green: max(0.15, base.greenComponent * 0.7), blue: max(0.15, base.blueComponent * 0.7), alpha: 1.0),
                base,
                NSColor(srgbRed: min(1.0, base.redComponent * 0.6 + 0.35), green: min(1.0, base.greenComponent * 0.6 + 0.35), blue: min(1.0, base.blueComponent * 0.6 + 0.35), alpha: 1.0),
                NSColor(srgbRed: min(1.0, 0.85 + base.redComponent * 0.15), green: min(1.0, 0.85 + base.greenComponent * 0.15), blue: min(1.0, 0.85 + base.blueComponent * 0.15), alpha: 1.0)
            ]
        }
    }
    
    // MARK: - Cache Key Generation
    private func cacheKey(for item: MediaItem) -> String {
        if let data = item.artworkData {
            return "art_\(item.id)_\(data.count)"
        }
        return "srv_\(item.service.rawValue)_\(item.bundleIdentifier ?? item.application)"
    }
    
    // MARK: - Application Icon Resolution
    public func appIcon(for bundleIdentifier: String?, appName: String?) -> NSImage? {
        let key = (bundleIdentifier ?? appName ?? "unknown") as NSString
        if let cached = appIconCache.object(forKey: key) {
            return cached
        }
        
        var resolvedIcon: NSImage?
        
        if let bId = bundleIdentifier, !bId.isEmpty {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bId) {
                resolvedIcon = NSWorkspace.shared.icon(forFile: url.path)
            } else if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bId).first {
                resolvedIcon = runningApp.icon
            }
        }
        
        if resolvedIcon == nil, let name = appName, !name.isEmpty {
            let running = NSWorkspace.shared.runningApplications
            if let matched = running.first(where: { $0.localizedName?.lowercased() == name.lowercased() }) {
                resolvedIcon = matched.icon
            }
        }
        
        if let icon = resolvedIcon {
            appIconCache.setObject(icon, forKey: key)
        }
        
        return resolvedIcon
    }
    
    // MARK: - Core Palette Extraction Algorithm
    /// Extracts a fluid, seamlessly harmonized 4-color gradient palette directly from artwork.
    /// Resizes to 64x64 bitmap for high fidelity color sampling.
    /// 1. Filters out muddy/pitch-black shadows.
    /// 2. Identifies the most vibrant, saturated chromatic tones from the artwork.
    /// 3. Normalizes and scales the dominant accent to brilliant display luminance.
    /// 4. Harmonizes a 4-color fluid progression:
    ///    - Color 0: Deep rich foundation tone
    ///    - Color 1: Radiant vibrant accent
    ///    - Color 2: Warm luminous transition
    ///    - Color 3: Soft glowing highlight (tinted by the artwork)
    public func dominantPalette(from image: NSImage) -> [NSColor] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }
        
        let width = 64
        let height = 64
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Quantize into 8x8x8 RGB buckets (512 total buckets)
        var bucketCounts = [Int: Int]()
        var bucketRSum = [Int: Double]()
        var bucketGSum = [Int: Double]()
        var bucketBSum = [Int: Double]()
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let a = Double(rawData[offset + 3]) / 255.0
                if a < 0.4 { continue }
                
                let r = Double(rawData[offset + 0]) / 255.0
                let g = Double(rawData[offset + 1]) / 255.0
                let b = Double(rawData[offset + 2]) / 255.0
                
                let maxC = max(r, max(g, b))
                if maxC < 0.14 { continue } // Filter out pure black / murky shadows
                
                let qr = min(7, Int(r * 8.0))
                let qg = min(7, Int(g * 8.0))
                let qb = min(7, Int(b * 8.0))
                let bucketKey = (qr << 6) | (qg << 3) | qb
                
                bucketCounts[bucketKey, default: 0] += 1
                bucketRSum[bucketKey, default: 0] += r
                bucketGSum[bucketKey, default: 0] += g
                bucketBSum[bucketKey, default: 0] += b
            }
        }
        
        struct ColorCandidate {
            let r: Double
            let g: Double
            let b: Double
            let count: Int
            
            var maxC: Double { max(r, max(g, b)) }
            var minC: Double { min(r, min(g, b)) }
            var sat: Double { maxC == 0 ? 0 : (maxC - minC) / maxC }
            var lum: Double { 0.299 * r + 0.587 * g + 0.114 * b }
            
            func distance(to other: ColorCandidate) -> Double {
                let dr = r - other.r
                let dg = g - other.g
                let db = b - other.b
                return sqrt(0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db)
            }
        }
        
        var candidates: [ColorCandidate] = []
        for (key, count) in bucketCounts {
            let cnt = Double(count)
            let r = bucketRSum[key]! / cnt
            let g = bucketGSum[key]! / cnt
            let b = bucketBSum[key]! / cnt
            candidates.append(ColorCandidate(r: r, g: g, b: b, count: count))
        }
        
        guard !candidates.isEmpty else { return [] }
        
        // Prioritize saturated, vibrant tones (filter noise with count >= 4)
        let vibrantCandidates = candidates.filter { $0.count >= 4 && $0.sat >= 0.25 }
            .sorted { s1, s2 in
                let score1 = s1.sat * 2.0 + s1.maxC + log(Double(s1.count)) * 0.3
                let score2 = s2.sat * 2.0 + s2.maxC + log(Double(s2.count)) * 0.3
                return score1 > score2
            }
        
        let prime = vibrantCandidates.first ?? candidates.sorted { $0.sat > $1.sat }.first!
        
        // Normalize prime accent to vibrant brilliance for macOS Dynamic Island
        let scale = min(2.5, 0.95 / max(0.1, prime.maxC))
        let normR = min(1.0, prime.r * scale)
        let normG = min(1.0, prime.g * scale)
        let normB = min(1.0, prime.b * scale)
        
        if prime.sat < 0.12 {
            // Monochromatic / grayscale artwork (e.g. B&W album cover)
            return [
                NSColor(white: 0.40, alpha: 1.0),
                NSColor(white: 0.65, alpha: 1.0),
                NSColor(white: 0.85, alpha: 1.0),
                NSColor(white: 1.00, alpha: 1.0)
            ]
        }
        
        // Seamless 4-color fluid progression matching approved #5:
        // Color 0: Deep rich base tone (clearly visible against black island)
        let c0 = NSColor(
            srgbRed: CGFloat(max(0.40, normR * 0.72)),
            green: CGFloat(max(0.15, normG * 0.55)),
            blue: CGFloat(max(0.12, normB * 0.55)),
            alpha: 1.0
        )
        
        // Color 1: Radiant vibrant primary accent
        let c1 = NSColor(
            srgbRed: CGFloat(normR),
            green: CGFloat(normG),
            blue: CGFloat(normB),
            alpha: 1.0
        )
        
        // Color 2: Warm golden amber / luminous transition
        let c2 = NSColor(
            srgbRed: CGFloat(min(1.0, normR * 0.50 + 0.50)),
            green: CGFloat(min(1.0, normG * 0.65 + 0.35)),
            blue: CGFloat(min(1.0, normB * 0.50 + 0.25)),
            alpha: 1.0
        )
        
        // Color 3: Soft luminous peach/tinted highlight
        let c3 = NSColor(
            srgbRed: CGFloat(min(1.0, 0.85 + normR * 0.15)),
            green: CGFloat(min(1.0, 0.85 + normG * 0.12)),
            blue: CGFloat(min(1.0, 0.82 + normB * 0.10)),
            alpha: 1.0
        )
        
        return [c0, c1, c2, c3]
    }
    
    /// Single dominant color
    public func dominantColor(from image: NSImage) -> NSColor? {
        dominantPalette(from: image).first
    }
}
