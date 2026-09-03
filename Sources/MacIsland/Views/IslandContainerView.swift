import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the sleek dark glass container and manages the smooth spring morphing
// between collapsed and expanded states.
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
        let cornerRadius: CGFloat = isExpanded ? 20 : 17
        
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
        // Native macOS dark translucent glass styling
        .background(
            ZStack {
                // Blur material layer
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Dark tint surface
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.islandSurface)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.islandBorder, lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.40), radius: isExpanded ? 16 : 8, x: 0, y: isExpanded ? 6 : 2)
        .onHover { hovering in
            windowManager.setHovered(hovering)
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: windowManager.islandState)
    }
}
