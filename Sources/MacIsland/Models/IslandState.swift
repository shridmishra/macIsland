import Foundation

// MARK: - Island Expansion State
// Manages whether the Dynamic Island is currently in its minimal pill state (collapsed)
// or opened showing full controls, album art, and progress bar (expanded).
public enum IslandState: Equatable, Sendable {
    case collapsed
    case expanded
    case hidden
    
    public var isExpanded: Bool {
        self == .expanded
    }
    
    public var isCollapsed: Bool {
        self == .collapsed
    }
}
