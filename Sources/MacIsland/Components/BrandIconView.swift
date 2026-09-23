import SwiftUI
import AppKit

// MARK: - BrandIconView
// High-resolution official brand logos for media streaming services
// (Prime Video, Netflix, YouTube, Spotify, Apple Music, Disney+, SoundCloud, Twitch).
// Renders pure graphic logo emblems with zero network lag and razor-sharp Retina fidelity.
public struct BrandIconView: View {
    public let service: MediaService
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(service: MediaService, size: CGFloat = 46, cornerRadius: CGFloat = 10) {
        self.service = service
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let logoImage = BrandLogoProvider.logo(for: service) {
                Image(nsImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var fallbackIcon: some View {
        ZStack {
            Color.white.opacity(0.12)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
