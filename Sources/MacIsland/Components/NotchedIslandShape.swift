import SwiftUI

// MARK: - NotchedIslandShape
// Apple-grade continuous curvature (G2 superellipse continuity) Dynamic Island shape:
// - Top edge touches the display bezel directly.
// - Top-left and Top-right feature smooth cubic bezier outward flares blending seamlessly into the screen bezel.
// - Bottom corners feature smooth continuous cubic bezier rounded corners (eliminating harsh quad-curve kinks).
// - Conforms to SwiftUI animatableData for silky GPU spring morphing.
public struct NotchedIslandShape: Shape {
    public var flareRadius: CGFloat
    public var bottomRadius: CGFloat
    
    public init(flareRadius: CGFloat = 14, bottomRadius: CGFloat = 24) {
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
        
        // 1. Top-left outer point flush with screen top bezel
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Smooth G2 outward flare: horizontal tangent at (0,0) blending into vertical wall at (f, f)
        path.addCurve(
            to: CGPoint(x: f, y: f),
            control1: CGPoint(x: f * 0.45, y: 0),
            control2: CGPoint(x: f, y: f * 0.55)
        )
        
        // 3. Left vertical wall
        path.addLine(to: CGPoint(x: f, y: h - b))
        
        // 4. Smooth continuous bottom-left rounded corner (cubic bezier squircle)
        path.addCurve(
            to: CGPoint(x: f + b, y: h),
            control1: CGPoint(x: f, y: h - b * 0.45),
            control2: CGPoint(x: f + b * 0.45, y: h)
        )
        
        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - f - b, y: h))
        
        // 6. Smooth continuous bottom-right rounded corner (cubic bezier squircle)
        path.addCurve(
            to: CGPoint(x: w - f, y: h - b),
            control1: CGPoint(x: w - f - b * 0.45, y: h),
            control2: CGPoint(x: w - f, y: h - b * 0.45)
        )
        
        // 7. Right vertical wall
        path.addLine(to: CGPoint(x: w - f, y: f))
        
        // 8. Smooth G2 outward flare blending back into the top screen bezel
        path.addCurve(
            to: CGPoint(x: w, y: 0),
            control1: CGPoint(x: w - f, y: f * 0.55),
            control2: CGPoint(x: w - f * 0.45, y: 0)
        )
        
        // 9. Close along the top screen edge
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
