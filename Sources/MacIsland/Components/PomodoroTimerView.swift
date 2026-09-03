import SwiftUI
import AppKit

// MARK: - PomodoroTimerView
// Precision replica of the orange Tuner / Focus timer UI:
// - Top: Orange radio-tuner style scrolling ruler with minute numbers (30 35 40 45 50 55 60),
//   orange vertical tick marks, and an orange triangle pointer (▲) at center.
// - Bottom Row (Idle): Vibrant orange "Start Timer" pill button on left + large orange digital timer ("45:00") on right.
// - Bottom Row (Running): Circular pause button + dark cancel "✕" button on left + "Timer  44:57" on right.
@MainActor
public struct PomodoroTimerView: View {
    @ObservedObject public var manager: PomodoroManager
    @State private var dragStartMinutes: Int? = nil
    @State private var dragOffset: CGFloat = 0.0
    
    @MainActor
    public init(manager: PomodoroManager) {
        self.manager = manager
    }
    
    @MainActor
    public init() {
        self.manager = PomodoroManager.shared
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // 1. Orange Tuner / Ruler Scrubber with numbers, ticks, and center indicator
            rulerScrubberView
                .frame(height: 48)
            
            // 2. Bottom Action Controls & Digital Countdown
            HStack(alignment: .center) {
                if manager.timerState == .idle {
                    // IDLE: "Start Timer" orange pill button (Screenshot 1)
                    Button {
                        manager.start()
                    } label: {
                        Text("Start Timer")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color.islandFocusButtonText)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 7.5)
                            .background(
                                Capsule()
                                    .fill(Color.islandFocusButtonFill)
                            )
                    }
                    .buttonStyle(.springPress(scale: 0.94, haptic: true))
                    .transition(.opacity)
                } else {
                    // ACTIVE / RUNNING: [⏸] [✕] buttons (Screenshot 2)
                    HStack(spacing: 8) {
                        // Pause / Play Button
                        Button {
                            manager.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.islandFocusButtonFill)
                                    .frame(width: 27, height: 27)
                                
                                Image(systemName: manager.timerState == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.islandFocusButtonText)
                            }
                        }
                        .buttonStyle(.springPress(scale: 0.90, haptic: true))
                        
                        // Cancel [✕] Button
                        Button {
                            manager.cancel()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.islandFocusCloseBackground)
                                    .frame(width: 27, height: 27)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(Color.islandFocusCloseIcon)
                            }
                        }
                        .buttonStyle(.springPress(scale: 0.90, haptic: true))
                    }
                    .transition(.opacity)
                }
                
                Spacer(minLength: 8)
                
                // Digital Timer Display (Screenshot 1 & 2)
                if manager.timerState == .idle {
                    // Idle: "45:00" in orange
                    Text(manager.formattedTime)
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Color.islandFocusDigits)
                        .lineLimit(1)
                        .fixedSize()
                } else {
                    // Running: "Timer  44:57" in orange
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text("Timer")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.islandFocusTimerLabel)
                        
                        Text(manager.formattedTime)
                            .font(.system(size: 28, weight: .regular, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(Color.islandFocusDigits)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Tuner Scrubber View
    
    private var rulerScrubberView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let centerX = width / 2.0
            let step: CGFloat = 6.2 // Spacing between minute ticks
            
            // Effective current minute value (floating-point for smooth animation)
            let currentMinutes: Double = {
                if manager.timerState == .idle {
                    if let start = dragStartMinutes {
                        return Double(start) - Double(dragOffset / step)
                    }
                    return Double(manager.selectedMinutes)
                } else {
                    return manager.timeRemaining / 60.0
                }
            }()
            
            ZStack(alignment: .top) {
                // Background ticks & numbers
                Canvas { context, size in
                    let minMinute = max(5, Int(currentMinutes - Double(centerX / step) - 3))
                    let maxMinute = min(120, Int(currentMinutes + Double(centerX / step) + 3))
                    
                    for m in minMinute...maxMinute {
                        let x = centerX + CGFloat(Double(m) - currentMinutes) * step
                        guard x >= -10 && x <= size.width + 10 else { continue }
                        
                        let isMajor = (m % 5 == 0)
                        let tickHeight: CGFloat = isMajor ? 16.0 : 9.5
                        let tickY: CGFloat = 20.0
                        
                        // Draw tick line
                        var tickPath = Path()
                        tickPath.move(to: CGPoint(x: x, y: tickY))
                        tickPath.addLine(to: CGPoint(x: x, y: tickY + tickHeight))
                        
                        let strokeColor = isMajor ? Color.islandFocusRulerTick : Color.islandFocusRulerTickSubtle
                        context.stroke(
                            tickPath,
                            with: .color(strokeColor),
                            lineWidth: 1.2
                        )
                        
                        // Draw major number label
                        if isMajor {
                            let text = Text("\(m)")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.islandFocusRulerNumber)
                            
                            context.draw(
                                text,
                                at: CGPoint(x: x, y: 8),
                                anchor: .center
                            )
                        }
                    }
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.12),
                            .init(color: .black, location: 0.88),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Orange Upward Triangle Pointer (▲) centered below ticks
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 38)
                    
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundColor(Color.islandFocusIndicator)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard manager.timerState == .idle else { return }
                        if dragStartMinutes == nil {
                            dragStartMinutes = manager.selectedMinutes
                        }
                        dragOffset = value.translation.width
                        let newMinutes = max(5, min(120, Int(round(Double(dragStartMinutes!) - Double(dragOffset / step)))))
                        if newMinutes != manager.selectedMinutes {
                            manager.setMinutes(newMinutes)
                        }
                    }
                    .onEnded { _ in
                        dragStartMinutes = nil
                        dragOffset = 0.0
                    }
            )
        }
    }
}
