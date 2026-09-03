import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the authentic macOS Liquid Frosted Glass surface and manages
// the spring morphing between collapsed and expanded states.
@MainActor
public struct IslandContainerView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var mediaManager: MediaManager
    
    @MainActor
    public init() {
        self.windowManager = WindowManager.shared
        self.mediaManager = MediaManager.shared
    }
    
    @MainActor
    public init(windowManager: WindowManager, mediaManager: MediaManager) {
        self.windowManager = windowManager
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        let isExpanded = windowManager.islandState.isExpanded
        // Collapsed radius matches the physical MacBook notch bottom curvature (~12pt)
        let cornerRadius: CGFloat = isExpanded ? 20 : 12
        
        ZStack {
            if isExpanded {
                ExpandedIslandView(mediaManager: mediaManager)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                CollapsedIslandView(
                    item: mediaManager.currentItem,
                    isPlaying: mediaManager.playbackState.isPlaying
                )
                .transition(.opacity)
            }
        }
        .frame(
            width: isExpanded ? windowManager.expandedWidth : windowManager.collapsedWidth,
            height: isExpanded ? windowManager.expandedHeight : windowManager.collapsedHeight
        )
        // Authentic macOS Frosted Glass styling
        .background(
            ZStack {
                // Layer 1: Native macOS Ultra-thin Material Blur
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Layer 2: Translucent dark glass tint
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.islandSurface)
                
                // Layer 3: Specular glass top reflection highlight
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.islandGlassHighlight, Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient.islandRimBorder, lineWidth: 0.75)
        )
        // Frosted glass elevation shadows
        .shadow(color: Color.black.opacity(isExpanded ? 0.30 : 0.16), radius: isExpanded ? 18 : 5, x: 0, y: isExpanded ? 8 : 2)
        .shadow(color: Color.black.opacity(isExpanded ? 0.18 : 0.08), radius: isExpanded ? 5 : 2, x: 0, y: isExpanded ? 2 : 1)
        .onHover { hovering in
            windowManager.setHovered(hovering)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: windowManager.islandState)
    }
}
