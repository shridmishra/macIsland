import SwiftUI
import AppKit

// MARK: - ArtworkImageView
// Displays high-resolution album artwork with rounded squircle corners and subtle border stroke.
// Falls back to a sleek system music glyph when no artwork is provided.
public struct ArtworkImageView: View {
    public let artworkData: Data?
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(artworkData: Data?, size: CGFloat = 56, cornerRadius: CGFloat = 12) {
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
                        .fill(Color.islandBorder)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.42, weight: .medium))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.islandBorder, lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
    }
}
