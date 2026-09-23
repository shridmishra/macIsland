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
    
    public var isHidden: Bool {
        self == .hidden
    }
}

// MARK: - Island Widget Pages
// Defines the selectable widgets in the Expanded Island view:
// - Page 0 (Default): Media player (Now Playing / Audio controls)
// - Page 1: Focus timer (Pomodoro tuner)
public enum IslandPage: Int, CaseIterable, Identifiable, Sendable {
    case media = 0
    case timer = 1
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .media: return "Now Playing"
        case .timer: return "Timer"
        }
    }
    
    public var canGoPrevious: Bool {
        rawValue > 0
    }
    
    public var canGoNext: Bool {
        rawValue < IslandPage.allCases.count - 1
    }
    
    public var previous: IslandPage? {
        IslandPage(rawValue: rawValue - 1)
    }
    
    public var next: IslandPage? {
        IslandPage(rawValue: rawValue + 1)
    }
}
