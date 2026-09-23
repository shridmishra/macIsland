import Foundation
import AppKit
import Combine

// MARK: - PomodoroManager
// Central manager for the Dynamic Island Pomodoro timer.
// Employs monotonic Date timestamps to eliminate clock drift during system sleep,
// background execution, or UI interactions.
// Supports 25m, 50m, 100m presets, custom duration scrubbing, and start/pause/cancel/restart actions.
@MainActor
public final class PomodoroManager: ObservableObject {
    public static let shared = PomodoroManager()
    
    public static let presets: [Int] = [25, 50, 100]
    
    @Published public private(set) var selectedMinutes: Int = 45
    @Published public private(set) var mode: PomodoroMode = .focus
    @Published public private(set) var timerState: PomodoroTimerState = .idle
    @Published public private(set) var timeRemaining: TimeInterval = 45 * 60
    @Published public private(set) var totalDuration: TimeInterval = 45 * 60
    @Published public private(set) var completedSessions: Int = 0
    
    /// User preference to show circular timer countdown in notch: defaults to true (ON)
    @Published public var isTimerInNotchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTimerInNotchEnabled, forKey: "MacIsland.isTimerInNotchEnabled")
        }
    }
    
    private var timer: Timer?
    private var targetEndTime: Date?
    
    public init() {
        self.selectedMinutes = 45
        self.totalDuration = 45 * 60
        self.timeRemaining = 45 * 60
        
        if UserDefaults.standard.object(forKey: "MacIsland.isTimerInNotchEnabled") == nil {
            self.isTimerInNotchEnabled = true
        } else {
            self.isTimerInNotchEnabled = UserDefaults.standard.bool(forKey: "MacIsland.isTimerInNotchEnabled")
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns true when a timer is currently active (running or paused)
    public var isTimerActive: Bool {
        timerState != .idle
    }
    
    /// Remaining fraction between 1.0 (just started, full circle) and 0.0 (completed)
    public var remainingFraction: Double {
        guard totalDuration > 0 else { return 0.0 }
        let fraction = timeRemaining / totalDuration
        return min(max(fraction, 0.0), 1.0)
    }
    
    /// Progress between 0.0 (just started) and 1.0 (completed)
    public var progress: Double {
        guard totalDuration > 0 else { return 0.0 }
        let fraction = 1.0 - (timeRemaining / totalDuration)
        return min(max(fraction, 0.0), 1.0)
    }
    
    /// Needle position fraction on the ruler (0.0 to 1.0 relative to total scale of 100m)
    public var rulerFraction: Double {
        let maxScaleMinutes = 100.0
        let minutes = timeRemaining / 60.0
        return min(max(minutes / maxScaleMinutes, 0.0), 1.0)
    }
    
    /// Formatted digital time string (e.g., "50:00", "49:56")
    public var formattedTime: String {
        let totalSeconds = Int(ceil(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Compact formatted time for pill badge (e.g. "49:47")
    public var formattedPillTime: String {
        let totalSeconds = Int(ceil(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Preset & Duration Selection
    
    public func selectPreset(minutes: Int) {
        setMinutes(minutes)
    }
    
    public func setMinutes(_ minutes: Int) {
        guard timerState != .running else { return }
        
        selectedMinutes = max(1, minutes)
        totalDuration = TimeInterval(selectedMinutes * 60)
        timeRemaining = totalDuration
        timerState = .idle
    }
    
    public func scrubToFraction(_ fraction: Double) {
        guard timerState != .running else { return }
        let clamped = min(max(fraction, 0.05), 1.0)
        let minutes = Int(round(clamped * 100.0))
        setMinutes(max(1, minutes))
    }
    
    // MARK: - Timer Control
    
    public func toggle() {
        if timerState == .running {
            pause()
        } else {
            start()
        }
    }
    
    public func start() {
        guard timerState != .running else { return }
        
        targetEndTime = Date().addingTimeInterval(timeRemaining)
        timerState = .running
        
        timer?.invalidate()
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }
    
    public func pause() {
        guard timerState == .running else { return }
        
        timer?.invalidate()
        timer = nil
        
        if let target = targetEndTime {
            timeRemaining = max(0, target.timeIntervalSinceNow)
        }
        targetEndTime = nil
        timerState = .paused
    }
    
    public func cancel() {
        timer?.invalidate()
        timer = nil
        targetEndTime = nil
        timerState = .idle
        timeRemaining = totalDuration
    }
    
    public func restart() {
        timer?.invalidate()
        timer = nil
        targetEndTime = nil
        
        timeRemaining = totalDuration
        start()
    }
    
    public func reset() {
        cancel()
    }
    
    public func toggleTimerInNotch() {
        isTimerInNotchEnabled.toggle()
    }
    
    // MARK: - Internal Logic
    
    private func tick() {
        guard timerState == .running, let target = targetEndTime else { return }
        
        let remaining = target.timeIntervalSinceNow
        if remaining <= 0.0 {
            timeRemaining = 0.0
            finishSession()
        } else {
            timeRemaining = remaining
        }
    }
    
    private func finishSession() {
        timer?.invalidate()
        timer = nil
        targetEndTime = nil
        
        // Play system chime
        playCompletionFeedback()
        
        completedSessions += 1
        timerState = .idle
        timeRemaining = totalDuration
    }
    
    private func playCompletionFeedback() {
        if let sound = NSSound(named: "Ping") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
