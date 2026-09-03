import Foundation
import AppKit
import os.log

// MARK: - MediaRemoteCLIHelper
// Out-of-process CLI helper that queries Apple's private MediaRemote framework.
// Runs with root/user privileges via /usr/bin/swift without causing sandbox crashes.
// Extracts track info, album artwork, exact capture timestamp, and playback status.
public final class MediaRemoteCLIHelper: @unchecked Sendable {
    public static let shared = MediaRemoteCLIHelper()
    
    private let logger = Logger(subsystem: "com.macisland.app", category: "MediaCLI")
    private let swiftPath = "/usr/bin/swift"
    private var isFetching = false
    private let fetchQueue = DispatchQueue(label: "com.macisland.mediaremote.fetch", qos: .userInitiated)
    
    // Embedded minimal Swift script that queries MediaRemote within Apple's privileged context
    private let helperScript = """
    import Foundation
    let h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    typealias F1 = @convention(c) (DispatchQueue) -> Void
    typealias F2 = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    typealias F3 = @convention(c) (DispatchQueue, @escaping (pid_t) -> Void) -> Void
    guard let h = h,
          let regSym = dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications"),
          let getInfoSym = dlsym(h, "MRMediaRemoteGetNowPlayingInfo"),
          let getPIDSym = dlsym(h, "MRMediaRemoteGetNowPlayingApplicationPID") else {
        exit(0)
    }
    let reg = unsafeBitCast(regSym, to: F1.self)
    let getInfo = unsafeBitCast(getInfoSym, to: F2.self)
    let getPID = unsafeBitCast(getPIDSym, to: F3.self)
    reg(DispatchQueue.main)
    
    var done = false
    getInfo(DispatchQueue.main) { info in
        guard let info = info, !info.isEmpty else {
            exit(0)
        }
        var d: [String: Any] = [:]
        d["title"] = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        d["artist"] = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        d["album"] = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        d["duration"] = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0.0
        d["elapsedTime"] = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0
        d["playbackRate"] = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0.0
        if let ts = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date {
            d["timestamp"] = ts.timeIntervalSince1970
        } else {
            d["timestamp"] = Date().timeIntervalSince1970
        }
        if let artwork = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            d["artwork"] = artwork.base64EncodedString()
        }
        getPID(DispatchQueue.main) { pid in
            d["pid"] = pid
            if let jData = try? JSONSerialization.data(withJSONObject: d) {
                FileHandle.standardOutput.write(jData)
            }
            done = true
            exit(0)
        }
    }
    let start = Date()
    while !done && Date().timeIntervalSince(start) < 1.2 {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
    }
    exit(0)
    """
    
    private init() {}
    
    public func fetchNowPlaying(completion: @escaping @Sendable (MediaItem?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isFetching else { return }
            self.isFetching = true
            defer { self.isFetching = false }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.swiftPath)
            process.arguments = ["-e", self.helperScript]
            
            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = Pipe() // Silence stderr
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                guard !outputData.isEmpty,
                      let json = try? JSONSerialization.jsonObject(with: outputData) as? [String: Any] else {
                    completion(nil)
                    return
                }
                
                let title = json["title"] as? String ?? ""
                guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    completion(nil)
                    return
                }
                
                let artist = json["artist"] as? String ?? ""
                let album = json["album"] as? String ?? ""
                let duration = json["duration"] as? Double ?? 0.0
                let elapsedTime = json["elapsedTime"] as? Double ?? 0.0
                let playbackRate = json["playbackRate"] as? Double ?? 0.0
                let pid = json["pid"] as? pid_t ?? 0
                let timestamp = json["timestamp"] as? Double ?? Date().timeIntervalSince1970
                let lastUpdated = Date(timeIntervalSince1970: timestamp)
                
                var artworkData: Data? = nil
                if let base64Str = json["artwork"] as? String {
                    artworkData = Data(base64Encoded: base64Str)
                }
                
                var appName = "Media Player"
                var bundleId: String? = nil
                if pid > 0, let app = NSRunningApplication(processIdentifier: pid) {
                    appName = app.localizedName ?? "Media Player"
                    bundleId = app.bundleIdentifier
                }
                
                let item = MediaItem(
                    title: title,
                    artist: artist,
                    album: album,
                    artworkData: artworkData,
                    duration: duration,
                    currentTime: elapsedTime,
                    isPlaying: playbackRate > 0.0,
                    application: appName,
                    bundleIdentifier: bundleId,
                    lastUpdated: lastUpdated
                )
                
                self.logger.info("✅ Found track: \(title, privacy: .public) | app: \(appName, privacy: .public) | playing: \(playbackRate > 0.0) | time: \(elapsedTime)/\(duration)")
                completion(item)
            } catch {
                self.logger.error("❌ Process run error: \(error.localizedDescription, privacy: .public)")
                completion(nil)
            }
        }
    }
}
