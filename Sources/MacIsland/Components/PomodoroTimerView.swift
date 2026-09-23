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
        VStack(spacing: 0) {
            // 1. Top Section: Tuner / Ruler Scrubber with pink indicator needle (▲)
            rulerScrubberView
                .frame(height: 34)
                .padding(.top, 2)
            
            Spacer()
            
            // 2. Bottom Section: Digital Countdown on Left, Action Controls on Right
            HStack(alignment: .center) {
                // Time on Left (padded comfortably away from edge, no "Timer" prefix)
                Text(manager.formattedTime)
                    .font(.system(size: 23, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.islandFocusDigits)
                    .lineLimit(1)
                    .fixedSize()
                
                Spacer(minLength: 12)
                
                // Action Controls on Right
                if manager.timerState == .idle {
                    Button {
                        manager.start()
                    } label: {
                        Text("Start")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.springPress(scale: 0.94, haptic: true))
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .transition(.opacity)
                } else {
                    // ACTIVE / RUNNING: Pause / Resume & Cancel controls
                    HStack(spacing: 8) {
                        Button {
                            manager.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: manager.timerState == .running ? "pause.fill" : "play.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(manager.timerState == .running ? "Pause" : "Resume")
                                    .font(.system(size: 11.5, weight: .semibold))
                            }
                            .lineLimit(1)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.springPress(scale: 0.94, haptic: true))
                        
                        Button {
                            manager.cancel()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11.5, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(Color.islandTextTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.springPress(scale: 0.94, haptic: true))
                    }
                    .transition(.opacity)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        let tickHeight: CGFloat = isMajor ? 11.0 : 6.5
                        let tickY: CGFloat = 15.0
                        
                        // Draw tick line
                        var tickPath = Path()
                        tickPath.move(to: CGPoint(x: x, y: tickY))
                        tickPath.addLine(to: CGPoint(x: x, y: tickY + tickHeight))
                        
                        let strokeColor = isMajor ? Color.islandFocusRulerTick : Color.islandFocusRulerTickSubtle
                        context.stroke(
                            tickPath,
                            with: .color(strokeColor),
                            lineWidth: 1.1
                        )
                        
                        // Draw major number label
                        if isMajor {
                            let text = Text("\(m)")
                                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.islandFocusRulerNumber)
                            
                            context.draw(
                                text,
                                at: CGPoint(x: x, y: 6),
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
                
                // White Upward Triangle Pointer (▲) centered below ticks
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 27)
                    
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 5.5, weight: .bold))
                        .foregroundStyle(Color.white)
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
