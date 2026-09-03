import SwiftUI
import AppKit

// MARK: - ArtworkImageView
// Displays high-resolution album artwork with rounded squircle corners.
// Clean, flat, borderless and shadowless to match the pure black aesthetic.
public struct ArtworkImageView: View {
    public let artworkData: Data?
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(artworkData: Data?, size: CGFloat = 46, cornerRadius: CGFloat = 10) {
        self.artworkData = artworkData
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let data = artworkData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
