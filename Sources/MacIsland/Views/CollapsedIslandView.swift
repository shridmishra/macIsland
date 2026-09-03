import SwiftUI

// MARK: - CollapsedIslandView
// The minimal resting state of Mac Island.
// On notched displays, compact wings flank the physical cutout at the exact 28pt height of the notch.
// Shows the true streaming service logo icon (Prime Video, Netflix, YouTube, Spotify)
// with pixel-perfect symmetrical padding and optical centering.
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
    
    // MARK: - Notched Display Wing Layout (Symmetrical Optical Centering)
    private var notchWingLayout: some View {
        HStack(spacing: 0) {
            // LEFT WING (44pt): [Flare 6pt] + [11pt gap] + [Icon 16pt] + [11pt gap] -> Notch
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 6) // Accounts for the top-left outward flare curve
                
                ZStack {
                    if let item = item {
                        ArtworkImageView(item: item, size: 16, cornerRadius: 4)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.islandTextSecondary)
                    }
                }
                .offset(y: -2) // Nudged upwards for optical balance
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: 44, height: windowManager.collapsedHeight)
            
            // CENTER: Physical camera cutout zone (100% empty space for hardware notch)
            Color.clear
                .frame(width: windowManager.notchWidth)
            
            // RIGHT WING (44pt): Notch -> [11pt gap] + [Equalizer 16pt] + [11pt gap] + [Flare 6pt]
            HStack(spacing: 0) {
                ZStack {
                    if isPlaying {
                        AudioWaveformIndicator(
                            isPlaying: true,
                            color: item?.service.brandColor ?? Color.islandAccent,
                            barCount: 4
                        )
                    } else if item != nil {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(Color.islandTextTertiary)
                    } else {
                        Circle()
                            .fill(Color.islandTextTertiary)
                            .frame(width: 4, height: 4)
                    }
                }
                .offset(y: -2) // Nudged upwards for optical balance
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                    .frame(width: 6) // Accounts for the top-right outward flare curve
            }
            .frame(width: 44, height: windowManager.collapsedHeight)
        }
    }
    
    // MARK: - Standard Non-Notched Screen Layout
    private var standardCenteredLayout: some View {
        HStack(spacing: 7) {
            if let item = item {
                ArtworkImageView(item: item, size: 16, cornerRadius: 4)
                
                Text(item.displayTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.islandTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                AudioWaveformIndicator(
                    isPlaying: isPlaying,
                    color: item.service.brandColor,
                    barCount: 4
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
