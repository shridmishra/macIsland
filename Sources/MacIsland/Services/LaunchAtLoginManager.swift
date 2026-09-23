import Foundation
import ServiceManagement

// MARK: - LaunchAtLoginManager
// Manages the application's auto-start at login and KeepAlive 24/7 background persistence via macOS LaunchAgent.
@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    @Published public private(set) var isEnabled: Bool = false
    
    private let plistURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.macisland.app.plist")
    }()
    
    private init() {
        refreshStatus()
    }
    
    public func refreshStatus() {
        self.isEnabled = FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    public func setEnabled(_ enable: Bool) {
        if enable {
            installLaunchAgent()
        } else {
            uninstallLaunchAgent()
        }
        refreshStatus()
    }
    
    public func installLaunchAgent() {
        let binaryPath: String
        if let bundlePath = Bundle.main.bundlePath as String?, bundlePath.hasSuffix(".app") {
            binaryPath = (bundlePath as NSString).appendingPathComponent("Contents/MacOS/MacIsland")
        } else {
            binaryPath = "/Users/shrid/Repos/projects/macIsland/MacIsland.app/Contents/MacOS/MacIsland"
        }
        
        let plistDict: [String: Any] = [
            "Label": "com.macisland.app",
            "ProgramArguments": [binaryPath],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
            let launchAgentsDir = plistURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try data.write(to: plistURL)
            
            // Register and load with launchctl
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["load", "-w", plistURL.path]
            try? process.run()
        } catch {
            print("⚠️ Failed to install LaunchAgent: \(error.localizedDescription)")
        }
    }
    
    public func uninstallLaunchAgent() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", "-w", plistURL.path]
        try? process.run()
        
        try? FileManager.default.removeItem(at: plistURL)
    }
    
    public func toggle() {
        setEnabled(!isEnabled)
    }
}
