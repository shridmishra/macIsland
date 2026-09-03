import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// On notched displays, compact wings flank the physical cutout at the exact 28pt height of the notch.
// Shows the true streaming service icon (Prime Video, Netflix, YouTube, Spotify) instead of the browser logo.
public struct CollapsedIslandView: View {
    public let item: MediaItem?
    public let isPlaying: Bool
    @ObservedObject private var windowManager = WindowManager.shared
    
    public init(item: MediaItem?, isPlaying: Bool) {
        self.item = item
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        Group {
            if windowManager.hasNotch {
                notchWingLayout
            } else {
                standardCenteredLayout
            }
        }
        .frame(height: windowManager.collapsedHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            WindowManager.shared.expand()
        }
    }
    
    // MARK: - Notched Display Wing Layout (Left Wing | Hardware Notch | Right Wing)
    private var notchWingLayout: some View {
        HStack(spacing: 0) {
            // LEFT WING: Outside the notch on the left
            HStack(spacing: 0) {
                if let item = item {
                    ArtworkImageView(item: item, size: 18, cornerRadius: 4.5)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
            .frame(width: 38, height: windowManager.collapsedHeight)
            
            // CENTER: Physical camera cutout zone
            // Empty space where the physical hardware notch sits
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING: Outside the notch on the right
            HStack(spacing: 0) {
                if isPlaying {
                    AudioWaveformIndicator(
                        isPlaying: true,
                        color: item?.service.brandColor ?? Color.islandAccent
                    )
                } else if item != nil {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.islandTextTertiary)
                } else {
                    Circle()
                        .fill(Color.islandTextTertiary)
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .frame(width: 38, height: windowManager.collapsedHeight)
        }
    }
    
    // MARK: - Standard Non-Notched Screen Layout
    private var standardCenteredLayout: some View {
        HStack(spacing: 7) {
            if let item = item {
                ArtworkImageView(item: item, size: 18, cornerRadius: 4.5)
                
                Text(item.displayTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                AudioWaveformIndicator(
                    isPlaying: isPlaying,
                    color: item.service.brandColor
                )
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.islandTextSecondary)
                
                Text("Mac Island")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.islandTextSecondary)
            }
        }
        .padding(.horizontal, 10)
    }
}
