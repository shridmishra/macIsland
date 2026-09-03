import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// On notched displays, splits information strictly into the side "wings" (left & right of the cutout)
// leaving the center empty so absolutely NOTHING is hidden behind the physical camera notch.
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
    
    // MARK: - Notched Display Wing Layout
    // Left Wing <--- Physical Cutout (Empty) ---> Right Wing
    private var notchWingLayout: some View {
        HStack(spacing: 0) {
            // LEFT WING: Outside the notch on the left
            HStack(spacing: 6) {
                if let item = item {
                    ArtworkImageView(artworkData: item.artworkData, size: 20, cornerRadius: 5)
                    
                    Text(item.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.islandTextPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.islandTextSecondary)
                    
                    Text("Mac Island")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.islandTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 8)
            .padding(.leading, 10)
            
            // CENTER: Physical camera cutout zone
            // Absolutely NOTHING is placed here so nothing is obscured by the hardware notch!
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING: Outside the notch on the right
            HStack(spacing: 6) {
                if isPlaying {
                    AudioWaveformIndicator(isPlaying: true)
                } else if item != nil {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color.islandTextTertiary)
                } else {
                    Circle()
                        .fill(Color.islandTextTertiary)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
            .padding(.trailing, 10)
        }
    }
    
    // MARK: - Standard Non-Notched Screen Layout
    private var standardCenteredLayout: some View {
        HStack(spacing: 8) {
            if let item = item {
                ArtworkImageView(artworkData: item.artworkData, size: 22, cornerRadius: 6)
                
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
        .padding(.horizontal, 12)
    }
}
