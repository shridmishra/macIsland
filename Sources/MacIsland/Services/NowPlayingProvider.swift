import Foundation

// MARK: - NowPlayingProvider Protocol
// Clean media provider abstraction layer.
// This decouples the UI and state manager from the underlying macOS media mechanism.
// In TypeScript/React terms, this is like an interface `interface NowPlayingProvider { ... }`.
// It allows swapping between MediaRemote (system-wide) or AppleScript/Mock providers cleanly.
public protocol NowPlayingProvider: AnyObject, Sendable {
    /// Handler invoked whenever media state changes (new song, play/pause, stop).
    var onMediaChange: (@Sendable (MediaItem?) -> Void)? { get set }
    
    /// Starts observing live system media changes.
    func startObserving()
    
    /// Stops observing.
    func stopObserving()
    
    /// Toggles play/pause on the currently active media player.
    func togglePlayPause()
    
    /// Skips to the next track.
    func nextTrack()
    
    /// Skips to the previous track.
    func previousTrack()
    
    /// Seeks playback to the specified elapsed time in seconds.
    func seek(to seconds: Double)
}
