import SwiftUI

// MARK: - HUDLevelBarView
// Apple Dynamic Island style progress bar used on the right wing of the notch
// when system volume or display brightness is being adjusted.
// Features a smooth rounded capsule track and fluid spring animations as the level increases or decreases.
public struct HUDLevelBarView: View {
    public let level: Float
    public var onLevelChanged: ((Float) -> Void)?
    
    private let trackWidth: CGFloat = 54.0
    private let trackHeight: CGFloat = 3.5
    
    public init(level: Float, onLevelChanged: ((Float) -> Void)? = nil) {
        self.level = level
        self.onLevelChanged = onLevelChanged
    }
    
    public var body: some View {
        let clampedLevel = CGFloat(max(0.0, min(1.0, level)))
        let fillWidth = max(0.0, trackWidth * clampedLevel)
        
        ZStack(alignment: .leading) {
            // Background track (thin sleek capsule)
            Capsule()
                .fill(Color.islandProgressTrack)
                .frame(width: trackWidth, height: trackHeight)
            
            // Dynamic level fill (thin sleek capsule)
            Capsule()
                .fill(Color.islandProgressFill)
                .frame(width: fillWidth, height: trackHeight)
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newFraction = Float(max(0.0, min(1.0, value.location.x / trackWidth)))
                    onLevelChanged?(newFraction)
                }
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: level)
    }
}
