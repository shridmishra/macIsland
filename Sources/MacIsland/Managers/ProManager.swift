import Foundation
import AppKit
import Combine

// MARK: - ProManager
// Manages Pro feature access and status for Mac Island.
// All core features (Media controls, synchronized lyrics, stealth HUD, Pomodoro timer, etc.)
// are 100% free and unrestricted.
// Future advanced features can check `isPro` to gate access.
@MainActor
public final class ProManager: ObservableObject {
    public static let shared = ProManager()
    
    private let kIsProUnlocked = "MacIsland_IsProUnlocked"
    
    @Published public private(set) var isPro: Bool = false
    
    private init() {
        let defaults = UserDefaults.standard
        isPro = defaults.bool(forKey: kIsProUnlocked)
    }
    
    public var editionDescription: String {
        isPro ? "Pro Edition" : "Free Edition"
    }
    
    public func unlockPro() {
        UserDefaults.standard.set(true, forKey: kIsProUnlocked)
        isPro = true
    }
    
    #if DEBUG
    public func resetPro() {
        UserDefaults.standard.set(false, forKey: kIsProUnlocked)
        isPro = false
    }
    #endif
}
