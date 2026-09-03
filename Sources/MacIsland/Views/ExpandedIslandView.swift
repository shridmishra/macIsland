import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when hovering over Mac Island.
// Maps and displays the true streaming media service (Prime Video, Netflix, YouTube, Spotify)
// even when audio/video is playing inside browsers like Brave, Chrome, Safari, or Arc.
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject private var windowManager = WindowManager.shared
    
    public init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if let item = mediaManager.currentItem {
                // Top section: Service/Album Artwork + Clean Track details + Streaming Service Badge + Collapse
                HStack(alignment: .center, spacing: 12) {
                    ArtworkImageView(item: item, size: 46, cornerRadius: 10)
                    
                    VStack(alignment: .leading, spacing: 2.5) {
                        // Title (cleaned of "Prime Video: " or " - YouTube")
                        Text(item.displayTitle)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(Color.islandTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Artist or Media Info
                        Text(item.artist.isEmpty ? "Now Playing" : item.artist)
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color.islandTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Streaming Service Pill Badge (e.g. "Prime Video" instead of "Brave Browser")
                        HStack(spacing: 4.5) {
                            Circle()
                                .fill(item.isPlaying ? item.service.brandColor : Color.islandTextTertiary)
                                .frame(width: 5, height: 5)
                            
                            Text(item.effectiveAppName)
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(Color.islandTextSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.islandBadgeBackground))
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Manual collapse button
                    Button(action: {
                        WindowManager.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.islandTextSecondary)
                            .frame(width: 20, height: 20)
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
                    VStack(spacing: 6) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.islandTextTertiary)
                        
                        Text("No Media Playing")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.islandTextSecondary)
                        
                        Text("Play audio in Apple Music, Spotify, or your browser")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color.islandTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        WindowManager.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.islandTextSecondary)
                            .frame(width: 20, height: 20)
                            .background(Color.islandControlHover)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Island")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, windowManager.expandedTopPadding)
        .padding(.bottom, 12)
    }
}
