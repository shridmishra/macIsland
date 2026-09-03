import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when the user hovers over Mac Island.
// On notched displays, all content starts below the notch cutout so nothing is obscured.
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject private var windowManager = WindowManager.shared
    
    public init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        VStack(spacing: 11) {
            if let item = mediaManager.currentItem {
                // Top section: Artwork + Track details + App Badge + Collapse button
                // Positioned safely below the hardware notch
                HStack(alignment: .top, spacing: 14) {
                    ArtworkImageView(artworkData: item.artworkData, size: 56, cornerRadius: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.islandTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Artist or Media Info
                        Text(item.artist.isEmpty ? "Now Playing" : item.artist)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.islandTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Active Application Pill Badge
                        HStack(spacing: 5) {
                            Circle()
                                .fill(item.isPlaying ? Color.islandAccent : Color.islandTextTertiary)
                                .frame(width: 5.5, height: 5.5)
                            
                            Text(item.application)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.islandTextSecondary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.islandBadgeBackground))
                        .overlay(Capsule().stroke(Color.islandBadgeBorder, lineWidth: 0.5))
                        .padding(.top, 1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Manual collapse button
                    Button(action: {
                        WindowManager.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.islandTextSecondary)
                            .frame(width: 22, height: 22)
                            .background(Color.islandControlHover)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Island")
                }
                
                // Middle section: Progress bar
                PlaybackProgressSlider(
                    progress: mediaManager.interpolatedProgress,
                    currentTimeString: mediaManager.formattedCurrentTime,
                    durationString: mediaManager.formattedDuration
                )
                .padding(.horizontal, 1)
                
                // Bottom section: Centered Playback controls
                MediaControlButtons(
                    isPlaying: mediaManager.playbackState.isPlaying,
                    onPrevious: { mediaManager.previousTrack() },
                    onTogglePlayPause: { mediaManager.togglePlayPause() },
                    onNext: { mediaManager.nextTrack() }
                )
            } else {
                // Empty state when no media is playing system-wide
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.islandTextTertiary)
                        
                        Text("No Media Playing")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.islandTextSecondary)
                        
                        Text("Play audio in Apple Music, Spotify, or your browser")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.islandTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        WindowManager.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.islandTextSecondary)
                            .frame(width: 22, height: 22)
                            .background(Color.islandControlHover)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Island")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 14)
    }
}
