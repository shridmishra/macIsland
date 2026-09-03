import SwiftUI

// MARK: - SkeletonView
// Animated shimmer placeholder for loading states inside Mac Island.
// A subtle luminance sweep glides across a translucent fill, matching the pitch-black
// Dynamic Island aesthetic. Used for artwork tiles, text lines, and progress bars
// during song transitions and initial content loads.
public struct SkeletonView: View {
    public let width: CGFloat
    public let height: CGFloat
    public let cornerRadius: CGFloat
    
    @State private var shimmerPhase: CGFloat = -1.0
    
    public init(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.islandSkeletonBase)
            .frame(width: width, height: height)
            .overlay {
                GeometryReader { geo in
                    let bandWidth = geo.size.width * 0.6
                    let totalTravel = geo.size.width + bandWidth
                    
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.islandSkeletonHighlight, location: 0.4),
                            .init(color: Color.islandSkeletonHighlight, location: 0.6),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: bandWidth)
                    .offset(x: -bandWidth + shimmerPhase * totalTravel)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 1.0
                }
            }
    }
}

// MARK: - SkeletonArtworkView
// Skeleton placeholder sized and shaped for artwork tiles.
public struct SkeletonArtworkView: View {
    public let size: CGFloat
    public let cornerRadius: CGFloat
    
    public init(size: CGFloat = 36, cornerRadius: CGFloat = 8) {
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        SkeletonView(width: size, height: size, cornerRadius: cornerRadius)
    }
}

// MARK: - SkeletonTextLine
// Skeleton placeholder shaped as a pill to represent a single line of text.
public struct SkeletonTextLine: View {
    public let width: CGFloat
    public let height: CGFloat
    
    public init(width: CGFloat = 100, height: CGFloat = 10) {
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        SkeletonView(width: width, height: height, cornerRadius: height / 2)
    }
}
