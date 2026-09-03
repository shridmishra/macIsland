import Foundation

// MARK: - Playback State
// Represents whether media is currently actively emitting audio, paused, or completely stopped.
public enum PlaybackState: String, Sendable, Equatable {
    case playing
    case paused
    case stopped
    
    public var isPlaying: Bool {
        self == .playing
    }
}
