import Foundation

// MARK: - MediaRemote Framework Dynamic Bridge
// MediaRemote is an internal macOS / iOS framework located at
// `/System/Library/PrivateFrameworks/MediaRemote.framework`.
// Because private frameworks cannot be linked directly at compile-time with standard headers,
// we use POSIX dynamic loading (`dlopen` and `dlsym`).
//
// Why this approach:
// 1. Zero system permissions needed (no AppleScript security prompts).
// 2. Universal support: Works with Apple Music, Spotify, Safari, Chrome, Brave, Podcasts, etc.
// 3. Ultra low latency: Delivers notifications instantly when playback changes.
public final class MediaRemoteBridge: @unchecked Sendable {
    public static let shared = MediaRemoteBridge()
    
    // Function pointers bound dynamically via dlsym
    private typealias MRRegisterFunc = @convention(c) (DispatchQueue) -> Void
    private typealias MRUnregisterFunc = @convention(c) () -> Void
    private typealias MRGetInfoFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private typealias MRGetPIDFunc = @convention(c) (DispatchQueue, @escaping (pid_t) -> Void) -> Void
    private typealias MRSendCommandFunc = @convention(c) (Int32, AnyObject?) -> Bool
    
    // MediaRemote Command IDs
    public static let commandPlay: Int32 = 0
    public static let commandPause: Int32 = 1
    public static let commandTogglePlayPause: Int32 = 2
    public static let commandNextTrack: Int32 = 4
    public static let commandPreviousTrack: Int32 = 5
    
    // Notification Names posted by MediaRemote
    public static let nowPlayingInfoDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
    public static let nowPlayingAppDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification")
    public static let nowPlayingPlaybackStateDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification")
    
    // Keys in the NowPlaying dictionary
    public static let keyTitle = "kMRMediaRemoteNowPlayingInfoTitle"
    public static let keyArtist = "kMRMediaRemoteNowPlayingInfoArtist"
    public static let keyAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
    public static let keyArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
    public static let keyDuration = "kMRMediaRemoteNowPlayingInfoDuration"
    public static let keyElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
    public static let keyPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
    public static let keyContentIdentifier = "kMRMediaRemoteNowPlayingInfoContentItemIdentifier"
    
    private var isLoaded = false
    private var registerFn: MRRegisterFunc?
    private var unregisterFn: MRUnregisterFunc?
    private var getInfoFn: MRGetInfoFunc?
    private var getPIDFn: MRGetPIDFunc?
    private var sendCommandFn: MRSendCommandFunc?
    
    private init() {
        loadFramework()
    }
    
    private func loadFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            print("❌ [MediaRemoteBridge] Failed to dlopen MediaRemote: \(String(cString: dlerror()))")
            return
        }
        print("✅ [MediaRemoteBridge] Successfully loaded MediaRemote.framework")
        
        if let regSym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerFn = unsafeBitCast(regSym, to: MRRegisterFunc.self)
        }
        if let unregSym = dlsym(handle, "MRMediaRemoteUnregisterForNowPlayingNotifications") {
            unregisterFn = unsafeBitCast(unregSym, to: MRUnregisterFunc.self)
        }
        if let infoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getInfoFn = unsafeBitCast(infoSym, to: MRGetInfoFunc.self)
        }
        if let pidSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") {
            getPIDFn = unsafeBitCast(pidSym, to: MRGetPIDFunc.self)
        }
        if let cmdSym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommandFn = unsafeBitCast(cmdSym, to: MRSendCommandFunc.self)
        }
        
        isLoaded = (registerFn != nil && getInfoFn != nil)
        print("🔍 [MediaRemoteBridge] isLoaded: \(isLoaded), registerFn: \(registerFn != nil), getInfoFn: \(getInfoFn != nil), getPIDFn: \(getPIDFn != nil)")
    }
    
    public var isAvailable: Bool {
        isLoaded
    }
    
    public func registerForNotifications(queue: DispatchQueue = .main) {
        registerFn?(queue)
    }
    
    public func unregisterForNotifications() {
        unregisterFn?()
    }
    
    public func getNowPlayingInfo(queue: DispatchQueue = .main, completion: @escaping ([String: Any]?) -> Void) {
        guard let getInfoFn = getInfoFn else {
            completion(nil)
            return
        }
        getInfoFn(queue, completion)
    }
    
    public func getNowPlayingApplicationPID(queue: DispatchQueue = .main, completion: @escaping (pid_t) -> Void) {
        guard let getPIDFn = getPIDFn else {
            completion(0)
            return
        }
        getPIDFn(queue, completion)
    }
    
    @discardableResult
    public func sendCommand(_ command: Int32, userInfo: AnyObject? = nil) -> Bool {
        guard let sendCommandFn = sendCommandFn else {
            return false
        }
        return sendCommandFn(command, userInfo)
    }
}
