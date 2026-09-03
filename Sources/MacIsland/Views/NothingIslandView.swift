import SwiftUI

// MARK: - NothingIslandView
// The productivity dashboard rendered in the Dynamic Island in the Nothing State.
// Features a two-column split layout:
// - Left Column: Orange radio-tuner Pomodoro Focus timer.
// - Right Column: Apple-styled Monthly Calendar with day grid and navigation.
@MainActor
public struct NothingIslandView: View {
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    
    @MainActor
    public init() {}
    
    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left Column: Focus Tuner
            PomodoroTimerView(manager: pomodoroManager)
                .frame(maxWidth: .infinity)
            
            // Subtle Vertical Divider
            Rectangle()
                .fill(Color.islandDivider)
                .frame(width: 1)
                .padding(.vertical, 2)
            
            // Right Column: Monthly Calendar
            MonthlyCalendarView()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.islandPinkSubtle)
                .padding(-6)
        )
    }
}
