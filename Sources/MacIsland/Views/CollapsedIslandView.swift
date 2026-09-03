import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// On notched displays, renders two independent transparent glass wings flanking the cutout.
// Backed by NSVisualEffectView for true hardware GPU behind-window glass blur.
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
    
    // MARK: - Notched Display: Two Independent Transparent Glass Wings
    // [Left Glass Wing] <--- 100% Clear Notch Space ---> [Right Glass Wing]
    private var notchWingLayout: some View {
        HStack(spacing: 0) {
            // LEFT WING: Mini artwork inside independent transparent glass pill
            ZStack {
                if let item = item {
                    ArtworkImageView(artworkData: item.artworkData, size: 18, cornerRadius: 4.5)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
            .frame(width: 36, height: windowManager.collapsedHeight)
            .transparentGlass(cornerRadius: 10, material: .hudWindow)
            .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 1.5)
            
            // CENTER: Physical camera cutout gap (100% transparent, ZERO pixels drawn)
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING: Mini audio equalizer inside independent transparent glass pill
            ZStack {
                if isPlaying {
                    AudioWaveformIndicator(isPlaying: true)
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
            .frame(width: 36, height: windowManager.collapsedHeight)
            .transparentGlass(cornerRadius: 10, material: .hudWindow)
            .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 1.5)
        }
    }
    
    // MARK: - Standard Non-Notched Screen Layout
    private var standardCenteredLayout: some View {
        HStack(spacing: 7) {
            if let item = item {
                ArtworkImageView(artworkData: item.artworkData, size: 18, cornerRadius: 4.5)
                
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                AudioWaveformIndicator(isPlaying: isPlaying)
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
        .frame(height: windowManager.collapsedHeight)
        .transparentGlass(cornerRadius: 12, material: .hudWindow)
        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 1.5)
    }
}
