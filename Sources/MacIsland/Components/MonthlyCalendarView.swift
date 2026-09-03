import SwiftUI
import AppKit

// MARK: - MonthlyCalendarView
// Precision replica of the Apple red header monthly calendar widget:
// - Header: All-caps red month name ("SEPTEMBER") in bold/heavy weight.
// - Weekdays: "S M T W T F S" in bold muted white.
// - Grid: Clean bold day numbers with empty slots before the 1st.
// - Today Indicator: Filled vibrant red circle with white text.
// - Sunday Column: Subtle muted white tone.
public struct MonthlyCalendarView: View {
    private let calendar = Calendar.current
    private let today = Date()
    
    public init() {}
    
    // MARK: - Date Calculations
    
    private var monthNameUppercase: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: today).uppercased()
    }
    
    private var weekdaySymbols: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private struct DaySlot: Identifiable {
        let id: Int
        let dayNumber: Int?
        let isToday: Bool
        let isSunday: Bool
    }
    
    private var monthSlots: [DaySlot] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: today),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let range = calendar.range(of: .day, in: .month, for: today) else {
            return []
        }
        _ = monthInterval
        
        // Sunday = 1, Saturday = 7
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingBlanks = weekdayOfFirst - 1
        let numberOfDays = range.count
        let todayDay = calendar.component(.day, from: today)
        
        var slots: [DaySlot] = []
        var slotId = 0
        
        // Leading blank slots
        for _ in 0..<leadingBlanks {
            slots.append(DaySlot(id: slotId, dayNumber: nil, isToday: false, isSunday: (slotId % 7 == 0)))
            slotId += 1
        }
        
        // Active days in month
        for day in 1...numberOfDays {
            let isSunday = (slotId % 7 == 0)
            let isToday = (day == todayDay)
            slots.append(DaySlot(id: slotId, dayNumber: day, isToday: isToday, isSunday: isSunday))
            slotId += 1
        }
        
        return slots
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. All-caps Month Header (Screenshot Reference)
            Button {
                openCalendarApp()
            } label: {
                Text(monthNameUppercase)
                    .font(.system(size: 13, weight: .heavy, design: .default))
                    .foregroundColor(Color.islandPinkLight)
                    .tracking(0.6)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
            
            // 2. Weekday Row: S M T W T F S
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.islandCalendarWeekday)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 3. 7-Column Days Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                spacing: 4
            ) {
                ForEach(monthSlots) { slot in
                    if let day = slot.dayNumber {
                        ZStack {
                            if slot.isToday {
                                Circle()
                                    .fill(Color.islandPinkLight)
                                    .frame(width: 21, height: 21)
                            }
                            
                            Text("\(day)")
                                .font(.system(size: 13, weight: .bold, design: .default))
                                .foregroundColor(
                                    slot.isToday ? Color.islandPinkOnText :
                                    (slot.isSunday ? Color.islandCalendarSunday : Color.white)
                                )
                        }
                        .frame(height: 21)
                    } else {
                        // Empty leading slot before the 1st
                        Color.clear
                            .frame(height: 21)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func openCalendarApp() {
        if let url = URL(string: "ical:") {
            NSWorkspace.shared.open(url)
        }
    }
}
