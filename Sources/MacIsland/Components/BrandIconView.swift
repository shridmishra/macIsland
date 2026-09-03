import SwiftUI

// MARK: - BrandIconView
// High-resolution, vector-crisp brand icons for media services
// (Prime Video, Netflix, YouTube, Spotify, Apple Music, Disney+, SoundCloud, Twitch).
// Displayed when playing media inside browsers (Brave, Chrome, Safari, Arc)
// so the user sees the media service icon instead of the browser logo.
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
        ZStack {
            switch service {
            case .primeVideo:
                primeVideoIcon
            case .netflix:
                netflixIcon
            case .youtube:
                youtubeIcon
            case .spotify:
                spotifyIcon
            case .appleMusic:
                appleMusicIcon
            case .disneyPlus:
                disneyPlusIcon
            case .soundcloud:
                soundCloudIcon
            case .twitch:
                twitchIcon
            case .appleTV:
                appleTVIcon
            case .generic:
                genericIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    // MARK: - Prime Video Icon
    private var primeVideoIcon: some View {
        ZStack {
            Color(red: 0.05, green: 0.12, blue: 0.22)
            
            VStack(spacing: size * 0.02) {
                Text("prime")
                    .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .italic()
                
                // Signature Prime Video curved smile arrow
                PrimeSmileShape()
                    .stroke(
                        Color(red: 0.0, green: 0.66, blue: 0.88),
                        style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                    )
                    .frame(width: size * 0.58, height: size * 0.18)
            }
            .offset(y: size * 0.02)
        }
    }
    
    // MARK: - Netflix Icon
    private var netflixIcon: some View {
        ZStack {
            Color.black
            
            // Netflix iconic "N"
            HStack(spacing: size * 0.02) {
                NetflixBar(size: size)
            }
        }
    }
    
    // MARK: - YouTube Icon
    private var youtubeIcon: some View {
        ZStack {
            Color(red: 0.95, green: 0.08, blue: 0.10)
            
            // White play triangle
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundColor(.white)
                .offset(x: size * 0.02)
        }
    }
    
    // MARK: - Spotify Icon
    private var spotifyIcon: some View {
        ZStack {
            Color(red: 0.11, green: 0.73, blue: 0.33)
            
            VStack(spacing: size * 0.06) {
                SoundWaveArc(widthFactor: 0.54, heightFactor: 0.08, lineWidth: size * 0.065)
                SoundWaveArc(widthFactor: 0.44, heightFactor: 0.07, lineWidth: size * 0.06)
                SoundWaveArc(widthFactor: 0.34, heightFactor: 0.06, lineWidth: size * 0.055)
            }
            .foregroundColor(.black)
            .rotationEffect(.degrees(-10))
            .offset(y: -size * 0.02)
        }
    }
    
    // MARK: - Apple Music Icon
    private var appleMusicIcon: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.20, blue: 0.38),
                    Color(red: 0.88, green: 0.08, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "music.note")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Disney+ Icon
    private var disneyPlusIcon: some View {
        ZStack {
            Color(red: 0.06, green: 0.14, blue: 0.36)
            
            Text("D+")
                .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - SoundCloud Icon
    private var soundCloudIcon: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.25, blue: 0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            Image(systemName: "cloud.fill")
                .font(.system(size: size * 0.48, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Twitch Icon
    private var twitchIcon: some View {
        ZStack {
            Color(red: 0.57, green: 0.27, blue: 1.0)
            
            Image(systemName: "bubble.left.fill")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Apple TV Icon
    private var appleTVIcon: some View {
        ZStack {
            Color.black
            
            HStack(spacing: size * 0.02) {
                Image(systemName: "applelogo")
                    .font(.system(size: size * 0.38, weight: .semibold))
                Text("tv")
                    .font(.system(size: size * 0.36, weight: .bold))
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Generic Icon
    private var genericIcon: some View {
        ZStack {
            Color.white.opacity(0.12)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Prime Video Smile Shape
private struct PrimeSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

// MARK: - SoundWave Arc for Spotify
private struct SoundWaveArc: View {
    let widthFactor: CGFloat
    let heightFactor: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width * widthFactor
                let h = geo.size.height * heightFactor
                let startX = (geo.size.width - w) / 2.0
                path.move(to: CGPoint(x: startX, y: geo.size.height / 2.0 + h))
                path.addQuadCurve(
                    to: CGPoint(x: startX + w, y: geo.size.height / 2.0 + h),
                    control: CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0 - h)
                )
            }
            .stroke(Color.black, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .frame(height: lineWidth * 2.0)
    }
}

// MARK: - Netflix "N" Ribbon
private struct NetflixBar: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Left leg
            Rectangle()
                .fill(Color(red: 0.89, green: 0.04, blue: 0.08))
                .frame(width: size * 0.16, height: size * 0.58)
                .offset(x: -size * 0.14)
            
            // Right leg
            Rectangle()
                .fill(Color(red: 0.89, green: 0.04, blue: 0.08))
                .frame(width: size * 0.16, height: size * 0.58)
                .offset(x: size * 0.14)
            
            // Diagonal ribbon
            Rectangle()
                .fill(Color(red: 1.0, green: 0.15, blue: 0.15))
                .frame(width: size * 0.16, height: size * 0.65)
                .rotationEffect(.degrees(-26))
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 1, y: 0)
        }
    }
}
