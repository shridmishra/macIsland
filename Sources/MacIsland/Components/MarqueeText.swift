import SwiftUI
import AppKit

// MARK: - MarqueeText
// Apple Dynamic Island-styled continuous marquee text view.
// Key refinements:
// - Zero Idle Overhead: Pauses TimelineView completely when paused or text fits within bounds (0% idle CPU)
// - Instant Responsive Startup: Begins smoothly after a brief 0.5s initial breath (no long awkward delay)
// - Truly Continuous Ticker: Scrolls endlessly without ever freezing or stopping between loop iterations
// - Resilient State Lifecycle: View re-evaluations and hover transitions do not reset or interrupt the animation
// - Graceful Pause Settle: Smoothly glides back to origin (offset 0) over 0.35s when playback pauses
// - Soft Gradient Masks: Trailing and leading fade masks dissolve text gently at the edges
public struct MarqueeText: View {
    public let text: String
    public let font: Font
    public let nsFont: NSFont
    public let color: Color
    public let isPlaying: Bool
    public let speed: Double
    public let holdDelay: Double
    public let spacing: CGFloat
    public let fadeLength: CGFloat
    
    @State private var playStartDate: Date = Date()
    @State private var pauseDate: Date? = nil
    @State private var pauseOffset: CGFloat = 0.0
    @State private var isAtRest: Bool = false
    @State private var hasInitialized: Bool = false
    
    public init(
        text: String,
        font: Font = .system(size: 13, weight: .bold),
        nsFont: NSFont = .systemFont(ofSize: 13, weight: .bold),
        color: Color = Color.islandTextPrimary,
        isPlaying: Bool = true,
        speed: Double = 28.0,
        holdDelay: Double = 0.5,
        spacing: CGFloat = 36.0,
        fadeLength: CGFloat = 14.0
    ) {
        self.text = text
        self.font = font
        self.nsFont = nsFont
        self.color = color
        self.isPlaying = isPlaying
        self.speed = speed
        self.holdDelay = holdDelay
        self.spacing = spacing
        self.fadeLength = fadeLength
    }
    
    /// Exact width of the text rendered with the designated font metrics
    private var textWidth: CGFloat {
        guard !text.isEmpty else { return 0 }
        let attributes: [NSAttributedString.Key: Any] = [.font: nsFont]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }
    
    /// Exact single-line bounding height to prevent any vertical expansion
    private var textHeight: CGFloat {
        ceil(nsFont.ascender - nsFont.descender + nsFont.leading)
    }
    
    public var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let isOverflowing = containerWidth > 0 && textWidth > (containerWidth + 4.0)
            let isTimelinePaused = !isOverflowing || (!isPlaying && isAtRest)
            
            if !isOverflowing {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(width: containerWidth, alignment: .leading)
            } else {
                let totalDistance = textWidth + spacing
                let settleDuration: Double = 0.35
                
                TimelineView(.animation(paused: isTimelinePaused)) { timeline in
                    let currentOffset = calculateOffset(
                        timelineDate: timeline.date,
                        totalDistance: totalDistance,
                        settleDuration: settleDuration
                    )
                    
                    let hasScrolledLeading = currentOffset > 1.0
                    
                    HStack(spacing: spacing) {
                        Text(text)
                            .font(font)
                            .foregroundColor(color)
                            .lineLimit(1)
                            .fixedSize()
                        
                        Text(text)
                            .font(font)
                            .foregroundColor(color)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .offset(x: -currentOffset)
                    .frame(width: containerWidth, alignment: .leading)
                    .mask {
                        HStack(spacing: 0) {
                            if hasScrolledLeading {
                                LinearGradient(
                                    colors: [.clear, .black],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: fadeLength)
                            }
                            
                            Rectangle()
                                .fill(Color.black)
                            
                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: fadeLength)
                        }
                        .frame(width: containerWidth)
                    }
                }
            }
        }
        .frame(height: textHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: isPlaying) { _, playing in
            handlePlaybackChange(playing)
        }
        .onChange(of: text) { _, _ in
            handleTextChange()
        }
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                playStartDate = Date()
                isAtRest = !isPlaying
            }
        }
    }
    
    /// Calculates current horizontal scroll offset with quick start and continuous conveyor motion
    private func calculateOffset(
        timelineDate: Date,
        totalDistance: CGFloat,
        settleDuration: Double
    ) -> CGFloat {
        if !isPlaying {
            guard let pDate = pauseDate else { return 0 }
            let elapsed = timelineDate.timeIntervalSince(pDate)
            if elapsed >= settleDuration {
                return 0
            } else {
                let progress = elapsed / settleDuration
                let easeOut = 1.0 - pow(1.0 - progress, 3)
                return pauseOffset * CGFloat(1.0 - easeOut)
            }
        }
        
        let elapsed = max(0, timelineDate.timeIntervalSince(playStartDate))
        if elapsed < holdDelay {
            return 0
        } else {
            let scrollElapsed = elapsed - holdDelay
            return CGFloat(fmod(scrollElapsed * speed, Double(totalDistance)))
        }
    }
    
    /// Handles play/pause transitions with smooth glide back to origin
    private func handlePlaybackChange(_ playing: Bool) {
        let totalDistance = textWidth + spacing
        if playing {
            playStartDate = Date()
            pauseDate = nil
            isAtRest = false
        } else {
            let elapsed = max(0, Date().timeIntervalSince(playStartDate))
            if elapsed < holdDelay {
                pauseOffset = 0
            } else {
                let scrollElapsed = elapsed - holdDelay
                pauseOffset = CGFloat(fmod(scrollElapsed * speed, Double(totalDistance)))
            }
            
            pauseDate = Date()
            isAtRest = (pauseOffset <= 0.5)
            
            if !isAtRest {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !self.isPlaying {
                        self.isAtRest = true
                    }
                }
            }
        }
    }
    
    /// Resets scroll position to origin when track changes
    private func handleTextChange() {
        playStartDate = Date()
        pauseDate = nil
        pauseOffset = 0
        isAtRest = !isPlaying
    }
}
