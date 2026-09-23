import SwiftUI
import AppKit

// MARK: - ArtworkImageView
// Displays high-resolution album artwork or smart brand vector icons.
// When playing in a browser (e.g. Brave, Chrome) on services like Prime Video, Netflix, YouTube,
// or Spotify, displays the true streaming service icon instead of the generic browser icon.
public struct ArtworkImageView: View {
    public let artworkData: Data?
    public let artworkImage: NSImage?
    public let service: MediaService
    public let isBrowserMedia: Bool
    public let bundleIdentifier: String?
    public let application: String?
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(
        artworkData: Data? = nil,
        artworkImage: NSImage? = nil,
        service: MediaService = .generic,
        isBrowserMedia: Bool = false,
        bundleIdentifier: String? = nil,
        application: String? = nil,
        size: CGFloat = 46,
        cornerRadius: CGFloat = 10
    ) {
        self.artworkData = artworkData
        self.artworkImage = artworkImage ?? (artworkData.flatMap { NSImage(data: $0) })
        self.service = service
        self.isBrowserMedia = isBrowserMedia
        self.bundleIdentifier = bundleIdentifier
        self.application = application
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public init(item: MediaItem?, size: CGFloat = 46, cornerRadius: CGFloat = 10) {
        self.artworkData = item?.artworkData
        self.artworkImage = item?.artworkImage
        self.service = item?.service ?? .generic
        self.isBrowserMedia = item?.isBrowserMedia ?? false
        self.bundleIdentifier = item?.bundleIdentifier
        self.application = item?.application
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            // 1. High-resolution album artwork or video thumbnail always takes highest priority
            if let image = artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if service != .generic {
                // 2. Recognized streaming service (YouTube Music, YouTube, Spotify, Prime Video, Netflix, etc.)
                BrandIconView(service: service, size: size, cornerRadius: cornerRadius)
            } else if isBrowserMedia {
                // 3. Web browser media without artwork -> fallback to clean music glyph
                fallbackGlyph
            } else if let appIcon = ArtworkColorExtractor.shared.appIcon(for: bundleIdentifier, appName: application) {
                // 4. Native media player application (QuickTime, VLC, IINA, etc.)
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                fallbackGlyph
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var fallbackGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.12))
            Image(systemName: service.isVideoService ? "play.tv.fill" : "music.note")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(Color.islandTextSecondary)
        }
    }
}
