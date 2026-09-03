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
    private let colorCache = NSCache<NSString, NSColor>()
    private let appIconCache = NSCache<NSString, NSImage>()
    
    private init() {}
    
    // MARK: - Primary Color Resolution
    /// Resolves the pulse accent color for a MediaItem following priority:
    /// 1. Album Artwork (`artworkData`)
    /// 2. Streaming Service Logo / Brand Color (if `service != .generic`)
    /// 3. Application Icon (e.g. Brave lion orange, Safari blue, Chrome green)
    /// 4. Fallback accent (`Color.islandWaveformPeach`)
    public func color(for item: MediaItem) -> Color {
        let cacheKey = cacheKey(for: item)
        if let cached = colorCache.object(forKey: cacheKey as NSString) {
            return Color(nsColor: cached)
        }
        
        // 1. Album Artwork
        if let data = item.artworkData,
           let image = NSImage(data: data),
           let extracted = dominantColor(from: image) {
            colorCache.setObject(extracted, forKey: cacheKey as NSString)
            return Color(nsColor: extracted)
        }
        
        // 2. Recognized Streaming Service
        if item.service != .generic {
            if let logo = BrandLogoProvider.logo(for: item.service),
               let extracted = dominantColor(from: logo) {
                colorCache.setObject(extracted, forKey: cacheKey as NSString)
                return Color(nsColor: extracted)
            }
            let brandNSColor = NSColor(item.service.brandColor)
            colorCache.setObject(brandNSColor, forKey: cacheKey as NSString)
            return item.service.brandColor
        }
        
        // 3. Application Icon (Brave, Chrome, Safari, etc.)
        if let appIcon = appIcon(for: item.bundleIdentifier, appName: item.application),
           let extracted = dominantColor(from: appIcon) {
            colorCache.setObject(extracted, forKey: cacheKey as NSString)
            return Color(nsColor: extracted)
        }
        
        // 4. Default Fallback
        let fallback = NSColor(Color.islandWaveformPeach)
        colorCache.setObject(fallback, forKey: cacheKey as NSString)
        return Color.islandWaveformPeach
    }
    
    // MARK: - Cache Key Generation
    private func cacheKey(for item: MediaItem) -> String {
        if let data = item.artworkData {
            return "art_\(item.id)_\(data.count)"
        }
        return "srv_\(item.service.rawValue)_\(item.bundleIdentifier ?? item.application)"
    }
    
    // MARK: - Application Icon Resolution
    /// Retrieves and caches the native app icon for a bundle identifier or application name
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
    
    // MARK: - Core Color Extraction Algorithm
    /// Extracts the most prominent, vibrant color from an NSImage.
    /// Resizes to a 32x32 bitmap (1,024 pixels) for sub-millisecond execution.
    /// Uses HSB binning weighted by saturation and luminance to locate the primary colorful accent.
    /// Ensures output has high contrast on OLED black backgrounds (brightness >= 0.68).
    public func dominantColor(from image: NSImage) -> NSColor? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = 32
        let height = 32
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 24 Hue Bins (15 degrees each across 360 degree color spectrum)
        let binCount = 24
        var binWeights = [Double](repeating: 0, count: binCount)
        var binHueSum = [Double](repeating: 0, count: binCount)
        var binSatSum = [Double](repeating: 0, count: binCount)
        var binBriSum = [Double](repeating: 0, count: binCount)
        
        var neutralCount = 0
        var neutralBriSum: Double = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let a = Double(rawData[offset + 3]) / 255.0
                if a < 0.4 { continue } // Discard transparent pixels
                
                let r = Double(rawData[offset + 0]) / 255.0
                let g = Double(rawData[offset + 1]) / 255.0
                let b = Double(rawData[offset + 2]) / 255.0
                
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let delta = maxC - minC
                let bri = maxC
                let sat = maxC > 0 ? delta / maxC : 0
                
                // Discard pure black or near-black background shadows
                if bri < 0.10 { continue }
                
                // Track neutral/greyscale pixels
                if sat < 0.15 {
                    neutralCount += 1
                    neutralBriSum += bri
                    continue
                }
                
                // Calculate hue
                var hue: Double = 0
                if delta > 0 {
                    if maxC == r {
                        hue = (g - b) / delta
                        if hue < 0 { hue += 6 }
                    } else if maxC == g {
                        hue = ((b - r) / delta) + 2
                    } else {
                        hue = ((r - g) / delta) + 4
                    }
                    hue /= 6.0
                }
                
                let binIndex = min(binCount - 1, max(0, Int(hue * Double(binCount))))
                // Weight formula: rewards high saturation and visible brightness
                let weight = (sat * 2.0) * (bri > 0.3 ? 1.0 : bri * 3.0)
                
                binWeights[binIndex] += weight
                binHueSum[binIndex] += hue * weight
                binSatSum[binIndex] += sat * weight
                binBriSum[binIndex] += bri * weight
            }
        }
        
        // Find highest-scoring colorful bin
        var bestBin = -1
        var maxWeight: Double = 0
        for i in 0..<binCount {
            if binWeights[i] > maxWeight {
                maxWeight = binWeights[i]
                bestBin = i
            }
        }
        
        if bestBin >= 0 && maxWeight > 1.0 {
            let avgH = binHueSum[bestBin] / binWeights[bestBin]
            let avgS = binSatSum[bestBin] / binWeights[bestBin]
            let avgV = binBriSum[bestBin] / binWeights[bestBin]
            
            // Adjust values so the pulse glows distinctly and vibrantly on pure black
            let finalV = min(1.0, max(0.68, avgV * 1.25))
            let finalS = min(1.0, max(0.55, avgS * 1.15))
            
            return NSColor(hue: CGFloat(avgH), saturation: CGFloat(finalS), brightness: CGFloat(finalV), alpha: 1.0)
        }
        
        // Monochromatic / Grayscale artwork (e.g. black and white photos)
        if neutralCount > 0 {
            let avgNeutralBri = neutralBriSum / Double(neutralCount)
            let finalV = min(1.0, max(0.85, avgNeutralBri))
            return NSColor(white: CGFloat(finalV), alpha: 1.0)
        }
        
        return nil
    }
}
