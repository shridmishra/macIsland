import SwiftUI

// MARK: - NotchedIslandShape
// Signature Dynamic Island shape with hardware-matching outward top curves:
// - Top edge touches the display bezel directly.
// - Top-left and Top-right feature outward curves (concave fillets / flares) blending into the top edge.
// - Bottom-left and Bottom-right feature smooth continuous rounded corners.
// - Supports SwiftUI animatableData for fluid spring morphing between collapsed and expanded states.
public struct NotchedIslandShape: Shape {
    public var flareRadius: CGFloat
    public var bottomRadius: CGFloat
    
    public init(flareRadius: CGFloat = 10, bottomRadius: CGFloat = 20) {
        self.flareRadius = flareRadius
        self.bottomRadius = bottomRadius
    }
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(flareRadius, bottomRadius) }
        set {
            flareRadius = newValue.first
            bottomRadius = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let f = min(flareRadius, w / 4, h / 2)
        let b = min(bottomRadius, (w - 2 * f) / 2, h - f)
        
        // 1. Start at top-left outer ear touching the top screen edge
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Concave curve curving down and inward to meet vertical left wall
        path.addQuadCurve(
            to: CGPoint(x: f, y: f),
            control: CGPoint(x: f, y: 0)
        )
        
        // 3. Left vertical wall
        path.addLine(to: CGPoint(x: f, y: h - b))
        
        // 4. Convex bottom-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: f + b, y: h),
            control: CGPoint(x: f, y: h)
        )
        
        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - f - b, y: h))
        
        // 6. Convex bottom-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: w - f, y: h - b),
            control: CGPoint(x: w - f, y: h)
        )
        
        // 7. Right vertical wall
        path.addLine(to: CGPoint(x: w - f, y: f))
        
        // 8. Concave curve curving up and outward to meet top screen edge
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w - f, y: 0)
        )
        
        // 9. Top edge flush with screen
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
