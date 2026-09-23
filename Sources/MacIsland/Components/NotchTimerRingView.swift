import SwiftUI

// MARK: - NotchTimerRingView
// Displays clean, crisp countdown digits in the left wing of the notch when collapsed.
// Shows the remaining timer numbers on the left side of the notch instead of a circular ring.
@MainActor
public struct NotchTimerRingView: View {
    @ObservedObject var manager: PomodoroManager
    
    @MainActor
    public init(manager: PomodoroManager) {
        self.manager = manager
    }
    
    @MainActor
    public init() {
        self.manager = PomodoroManager.shared
    }
    
    public var body: some View {
        let isRunning = manager.timerState == .running
        
        Text(manager.formattedTime)
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.islandFocusDigits.opacity(isRunning ? 1.0 : 0.65))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .animation(IslandAnimation.notchSpring, value: isRunning)
    }
}
