import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the pure pitch-black Dynamic Island container that merges seamlessly
// with the physical MacBook camera cutout.
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
        // Collapsed radius matches the physical MacBook notch bottom curvature (12pt)
        let cornerRadius: CGFloat = isExpanded ? 22 : 12
        
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
        // Pure pitch-black background to merge seamlessly with the physical camera notch
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient.islandRimBorder, lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.55), radius: isExpanded ? 18 : 6, x: 0, y: isExpanded ? 8 : 2)
        .onHover { hovering in
            windowManager.setHovered(hovering)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: windowManager.islandState)
    }
}
