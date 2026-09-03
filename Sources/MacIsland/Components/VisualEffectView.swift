import AppKit
import SwiftUI

// MARK: - VisualEffectView
// NSViewRepresentable wrapper around AppKit's NSVisualEffectView with `.behindWindow` blending mode.
// Unlike SwiftUI's built-in `Material` (which only blurs within the same window hierarchy),
// `NSVisualEffectView(blendingMode: .behindWindow)` commands the macOS WindowServer GPU compositor
// to sample and blur the actual desktop wallpaper and background windows behind this transparent panel.
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    public let state: NSVisualEffectView.State
    public let cornerRadius: CGFloat
    
    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        cornerRadius: CGFloat = 12
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = state
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = cornerRadius
        effectView.layer?.masksToBounds = true
        return effectView
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}
