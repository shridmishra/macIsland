import Foundation

// MARK: - Pomodoro Mode
public enum PomodoroMode: String, CaseIterable, Sendable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    public var defaultDuration: TimeInterval {
        switch self {
        case .focus:
            return 25 * 60 // 25 minutes
        case .shortBreak:
            return 5 * 60  // 5 minutes
        case .longBreak:
            return 15 * 60 // 15 minutes
        }
    }
    
    public var shortTitle: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Break"
        case .longBreak: return "Long"
        }
    }
    
    public var iconName: String {
        switch self {
        case .focus: return "timer"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }
}

// MARK: - Pomodoro Timer State
public enum PomodoroTimerState: Sendable {
    case idle
    case running
    case paused
    
    public var isRunning: Bool {
        self == .running
    }
}
