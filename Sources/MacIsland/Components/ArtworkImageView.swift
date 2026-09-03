import SwiftUI
import AppKit

// MARK: - ArtworkImageView
// Displays high-resolution album artwork with rounded corners and a subtle border stroke.
// Falls back to a sleek system music glyph when no artwork is provided.
public struct ArtworkImageView: View {
    public let artworkData: Data?
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(artworkData: Data?, size: CGFloat = 52, cornerRadius: CGFloat = 8) {
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
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.islandBorder)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.45, weight: .medium))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.islandBorder, lineWidth: 0.5)
        )
    }
}
