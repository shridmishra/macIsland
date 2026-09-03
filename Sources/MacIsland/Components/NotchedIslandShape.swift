import SwiftUI

// MARK: - NotchedIslandShape
// Dynamic Island shape matching the reference design:
// - Top edge touches the display bezel directly.
// - Subtle, gentle 5pt outward fillets at the top corners that blend seamlessly into the display edge (no oversized horns).
// - Straight, clean vertical side walls.
// - Smooth, elegant rounded bottom corners (18pt).
// - Conforms to SwiftUI animatableData for silky GPU spring morphing.
public struct NotchedIslandShape: Shape {
    public var flareRadius: CGFloat
    public var bottomRadius: CGFloat
    
    public init(flareRadius: CGFloat = 5, bottomRadius: CGFloat = 18) {
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
        let f = min(flareRadius, 6)
        let b = min(bottomRadius, 20)
        
        // 1. Top-left outer point flush with screen top bezel
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. Subtle, natural outward fillet into the vertical left wall
        if f > 0 {
            path.addQuadCurve(
                to: CGPoint(x: f, y: f),
                control: CGPoint(x: f, y: 0)
            )
        }
        
        // 3. Straight vertical left wall
        path.addLine(to: CGPoint(x: f, y: h - b))
        
        // 4. Smooth bottom-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: f + b, y: h),
            control: CGPoint(x: f, y: h)
        )
        
        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - f - b, y: h))
        
        // 6. Smooth bottom-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: w - f, y: h - b),
            control: CGPoint(x: w - f, y: h)
        )
        
        // 7. Straight vertical right wall
        path.addLine(to: CGPoint(x: w - f, y: f))
        
        // 8. Subtle, natural outward fillet blending into top screen bezel
        if f > 0 {
            path.addQuadCurve(
                to: CGPoint(x: w, y: 0),
                control: CGPoint(x: w - f, y: 0)
            )
        }
        
        // 9. Close along top edge
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}
