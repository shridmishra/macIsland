import SwiftUI
import AppKit

// MARK: - ArtworkImageView
// Displays high-resolution album artwork or smart brand vector icons.
// When playing in a browser (e.g. Brave, Chrome) on services like Prime Video, Netflix, YouTube,
// or Spotify, displays the true streaming service icon instead of the generic browser icon.
public struct ArtworkImageView: View {
    public let artworkData: Data?
    public let service: MediaService
    public let isBrowserMedia: Bool
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(
        artworkData: Data? = nil,
        service: MediaService = .generic,
        isBrowserMedia: Bool = false,
        size: CGFloat = 46,
        cornerRadius: CGFloat = 10
    ) {
        self.artworkData = artworkData
        self.service = service
        self.isBrowserMedia = isBrowserMedia
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public init(item: MediaItem?, size: CGFloat = 46, cornerRadius: CGFloat = 10) {
        self.artworkData = item?.artworkData
        self.service = item?.service ?? .generic
        self.isBrowserMedia = item?.isBrowserMedia ?? false
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            // When playing in a web browser with a recognized streaming service (Prime Video, Netflix, YouTube, Spotify, etc.),
            // show the media service brand icon instead of the browser logo (Brave/Chrome)!
            if isBrowserMedia && service != .generic {
                BrandIconView(service: service, size: size, cornerRadius: cornerRadius)
            } else if let data = artworkData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if service != .generic {
                BrandIconView(service: service, size: size, cornerRadius: cornerRadius)
            } else {
                // Sleek fallback glyph with subtle translucent background
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.42, weight: .medium))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
