import SwiftUI
import AppKit

// MARK: - ExpandedIslandView
// The rich, interactive floating card revealed when the user hovers over Mac Island.
// Shows album artwork, song title, artist, application source badge, playback progress, and controls.
public struct ExpandedIslandView: View {
    @ObservedObject var mediaManager: MediaManager
    
    public init(mediaManager: MediaManager) {
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if let item = mediaManager.currentItem {
                // Top section: Artwork + Track details + App Badge
                HStack(alignment: .top, spacing: 12) {
                    ArtworkImageView(artworkData: item.artworkData, size: 54, cornerRadius: 8)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        // Title
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.islandTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Artist
                        Text(item.artist.isEmpty ? "Unknown Artist" : item.artist)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.islandTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Active Application Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.isPlaying ? Color.islandAccent : Color.islandTextTertiary)
                                .frame(width: 5, height: 5)
                            
                            Text(item.application)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.islandTextTertiary)
                        }
                        .padding(.top, 2)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Manual collapse button
                    Button(action: {
                        WindowManager.shared.collapse()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
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
                
                // Bottom section: Playback controls
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.islandTextSecondary)
                        
                        Text("Play audio in Apple Music, Spotify, or your browser")
                            .font(.system(size: 10, weight: .regular))
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
                            .frame(width: 20, height: 20)
                            .background(Color.islandControlHover)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Island")
                }
            }
        }
        .padding(14)
    }
}
