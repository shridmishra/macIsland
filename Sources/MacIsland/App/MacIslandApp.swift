import SwiftUI

// MARK: - MacIslandApp Entry Point
// Standard SwiftUI app lifecycle.
// By using `@NSApplicationDelegateAdaptor`, we bridge SwiftUI with our AppKit AppDelegate.
// Instead of a default `WindowGroup` (which would create a standard macOS document window),
// we use `Settings { EmptyView() }` and let our custom `IslandPanel` control the presentation.
@main
struct MacIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
