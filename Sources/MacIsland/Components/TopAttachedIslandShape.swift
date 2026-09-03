import SwiftUI

// MARK: - TopAttachedIslandShape
// Clean, top-attached dynamic island dropdown shape:
// - Top edge touches the display bezel directly (100% flat across top-left to top-right).
// - Top-left and top-right are straight corners (radius 0) that anchor flush to the screen bezel.
// - Bottom-left and bottom-right feature continuous rounded corners.
// - Zero ears, zero horns, and zero awkward cutouts.
public struct TopAttachedIslandShape: Shape {
    public var bottomRadius: CGFloat
    
    public init(bottomRadius: CGFloat = 18) {
        self.bottomRadius = bottomRadius
    }
    
    public var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let b = min(bottomRadius, w / 2, h)
        
        // 1. Start at top-left touching bezel
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Straight down left vertical wall
        path.addLine(to: CGPoint(x: 0, y: h - b))
        
        // 3. Bottom-left smooth rounded corner
        path.addQuadCurve(
            to: CGPoint(x: b, y: h),
            control: CGPoint(x: 0, y: h)
        )
        
        // 4. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - b, y: h))
        
        // 5. Bottom-right smooth rounded corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: h - b),
            control: CGPoint(x: w, y: h)
        )
        
        // 6. Straight up right vertical wall
        path.addLine(to: CGPoint(x: w, y: 0))
        
        // 7. Flush top edge touching screen bezel
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
