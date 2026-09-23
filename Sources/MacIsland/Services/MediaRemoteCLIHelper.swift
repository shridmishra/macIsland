import Foundation
import AppKit
import os.log

// MARK: - MediaRemoteCLIHelper
// Persistent background helper bridge to Apple's MediaRemote framework.
// On macOS 15.4+ and macOS 26, direct in-process calls to `MRMediaRemoteGetNowPlayingInfo`
// from user-space GUI applications are rejected with Error Code 3 ("Operation not permitted")
// due to private framework sandboxing.
// However, Apple's signed system interpreter `/usr/bin/swift` possesses the required Apple-internal
// entitlements to query MediaRemote without permission restrictions.
//
// Architecture:
// 1. Spawns `/usr/bin/swift <script>` ONCE as a persistent background child process.
// 2. The child process registers for MediaRemote notifications (`MRMediaRemoteRegisterForNowPlayingNotifications`)
//    and Darwin notification center events.
// 3. Whenever media state changes, the child process streams a single-line JSON payload to stdout.
// 4. The parent process reads lines asynchronously via Pipe's readabilityHandler at 0% idle CPU.
// 5. Commands (toggle, play, pause, next, prev, seek, query) are written to the child process's stdin Pipe.
// 6. Child process automatically monitors parent PID; if the parent terminates or stdin closes, it exits cleanly.
public final class MediaRemoteCLIHelper: @unchecked Sendable {
    public static let shared = MediaRemoteCLIHelper()
    
    private let logger = Logger(subsystem: "com.macisland.app", category: "MediaCLI")
    private let queue = DispatchQueue(label: "com.macisland.mediaremote.cli", qos: .userInitiated)
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var stdoutBuffer = Data()
    
    private var isRunning = false
    private var shouldKeepRunning = false
    
    private var listeners: [@Sendable (MediaItem?) -> Void] = []
    private var pendingCompletions: [@Sendable (MediaItem?) -> Void] = []
    
    private var cachedItem: MediaItem?
    private var lastArtworkData: Data?
    private var lastArtworkId: String?
    
    // Embedded minimal Swift script that queries MediaRemote within Apple's privileged context
    private let helperScript: String = """
    import Foundation
    import AppKit

    setbuf(stdout, nil)

    let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    typealias MRRegisterFunc = @convention(c) (DispatchQueue) -> Void
    typealias MRGetInfoFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    typealias MRGetPIDFunc = @convention(c) (DispatchQueue, @escaping (pid_t) -> Void) -> Void
    typealias MRSendCommandFunc = @convention(c) (Int32, AnyObject?) -> Bool
    typealias MRSetElapsedTimeFunc = @convention(c) (Double) -> Void

    guard let h = handle,
          let regSym = dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications"),
          let infoSym = dlsym(h, "MRMediaRemoteGetNowPlayingInfo"),
          let pidSym = dlsym(h, "MRMediaRemoteGetNowPlayingApplicationPID") else {
        exit(1)
    }

    let regFn = unsafeBitCast(regSym, to: MRRegisterFunc.self)
    let getInfo = unsafeBitCast(infoSym, to: MRGetInfoFunc.self)
    let getPID = unsafeBitCast(pidSym, to: MRGetPIDFunc.self)

    var sendCmd: MRSendCommandFunc?
    if let cmdSym = dlsym(h, "MRMediaRemoteSendCommand") {
        sendCmd = unsafeBitCast(cmdSym, to: MRSendCommandFunc.self)
    }

    var setSeek: MRSetElapsedTimeFunc?
    if let seekSym = dlsym(h, "MRMediaRemoteSetElapsedTime") {
        setSeek = unsafeBitCast(seekSym, to: MRSetElapsedTimeFunc.self)
    }

    regFn(DispatchQueue.main)

    var lastArtworkKey = ""
    var lastTrackKey = ""
    var lastRate: Double = 0.0
    var emitScheduled = false

    func emitNowPlaying() {
        if emitScheduled { return }
        emitScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            emitScheduled = false
            getInfo(DispatchQueue.main) { info in
                guard let info = info, !info.isEmpty else {
                    let empty: [String: Any] = ["empty": true]
                    if let j = try? JSONSerialization.data(withJSONObject: empty), let s = String(data: j, encoding: .utf8) {
                        print(s)
                        fflush(stdout)
                    }
                    return
                }
                
                getPID(DispatchQueue.main) { pid in
                var d: [String: Any] = [:]
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                let duration = (info["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? (info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0.0)
                let rate = (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? (info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0.0)
                lastRate = rate
                
                var elapsed = (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? (info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0.0)
                if let ts = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date, rate > 0.0 {
                    let diff = Date().timeIntervalSince(ts)
                    if diff > 0 {
                        elapsed += diff * rate
                    }
                }
                if duration > 0 {
                    elapsed = min(duration, max(0.0, elapsed))
                } else {
                    elapsed = max(0.0, elapsed)
                }
                
                d["title"] = title
                d["artist"] = artist
                d["album"] = album
                d["duration"] = duration
                d["elapsedTime"] = elapsed
                d["playbackRate"] = rate
                d["timestamp"] = Date().timeIntervalSince1970
                d["pid"] = pid
                
                let rawArtId = (info["kMRMediaRemoteNowPlayingInfoArtworkIdentifier"] as? String) ?? ""
                let artworkId = rawArtId.isEmpty ? "\\(title)_\\(artist)" : rawArtId
                d["artworkId"] = artworkId
                
                let trackKey = "\\(title)_\\(artist)"
                let isTrackChange = (trackKey != lastTrackKey)
                if isTrackChange {
                    lastTrackKey = trackKey
                    lastArtworkKey = ""
                }
                
                if let artwork = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data, !artwork.isEmpty {
                    let currentKey = "\\(artworkId)_\\(artwork.count)"
                    if currentKey != lastArtworkKey {
                        lastArtworkKey = currentKey
                        d["artwork"] = artwork.base64EncodedString()
                    }
                } else if isTrackChange {
                    if lastArtworkKey != "\\(artworkId)_empty" {
                        lastArtworkKey = "\\(artworkId)_empty"
                        d["artwork"] = ""
                    }
                }
                
                if let j = try? JSONSerialization.data(withJSONObject: d), let s = String(data: j, encoding: .utf8) {
                    print(s)
                    fflush(stdout)
                }
            }
        }
    }
    }

    // In-process notifications from MediaRemote (MediaRemote posts in-process NSNotifications)
    let notifNames = [
        "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
        "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
        "kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification",
        "kMRMediaRemotePlayerNowPlayingInfoDidChangeNotification",
        "kMRMediaRemotePlayerPlaybackStateDidChangeNotification",
        "kMRMediaRemotePlayerIsPlayingDidChangeNotification",
        "kMRNowPlayingPlaybackQueueChangedNotification",
        "_kMRMediaRemotePlayerPlaybackStateDidChangeNotification"
    ]
    for name in notifNames {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(name),
            object: nil,
            queue: .main
        ) { _ in
            emitNowPlaying()
        }
    }

    if let center = CFNotificationCenterGetDarwinNotifyCenter() {
        for notif in notifNames {
            CFNotificationCenterAddObserver(
                center,
                nil,
                { _, _, _, _, _ in
                    emitNowPlaying()
                },
                notif as CFString,
                nil,
                .deliverImmediately
            )
        }
    }

    let inputSource = DispatchSource.makeReadSource(fileDescriptor: FileHandle.standardInput.fileDescriptor, queue: .main)
    var inputBuffer = Data()

    inputSource.setEventHandler {
        var buf = [UInt8](repeating: 0, count: 1024)
        let bytesRead = read(FileHandle.standardInput.fileDescriptor, &buf, buf.count)
        if bytesRead <= 0 {
            exit(0)
        }
        inputBuffer.append(contentsOf: buf[0..<bytesRead])
        
        while let newlineIdx = inputBuffer.firstIndex(of: 10) {
            let lineData = inputBuffer[..<newlineIdx]
            inputBuffer.removeSubrange(...newlineIdx)
            if let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                if line == "query" {
                    emitNowPlaying()
                } else if line == "toggle" {
                    _ = sendCmd?(2, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { emitNowPlaying() }
                } else if line == "play" {
                    _ = sendCmd?(0, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { emitNowPlaying() }
                } else if line == "pause" {
                    _ = sendCmd?(1, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { emitNowPlaying() }
                } else if line == "next" {
                    _ = sendCmd?(4, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { emitNowPlaying() }
                } else if line == "prev" {
                    _ = sendCmd?(5, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { emitNowPlaying() }
                } else if line.hasPrefix("seek:"), let val = Double(line.dropFirst(5)) {
                    setSeek?(val)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { emitNowPlaying() }
                }
            }
        }
    }
    inputSource.resume()

    let initialPPID = getppid()
    let poller = DispatchSource.makeTimerSource(queue: .main)
    poller.schedule(deadline: .now() + 1.0, repeating: 1.0)
    var tickCounter = 0
    poller.setEventHandler {
        tickCounter += 1
        let curPPID = getppid()
        if curPPID != initialPPID || curPPID <= 1 {
            exit(0)
        }
        if lastRate > 0.0 || (tickCounter % 3 == 0) {
            emitNowPlaying()
        }
    }
    poller.resume()

    emitNowPlaying()
    CFRunLoopRun()
    """
    
    private init() {}
    
    deinit {
        stopObserving()
    }
    
    public func startObserving(onUpdate: @escaping @Sendable (MediaItem?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.listeners.append(onUpdate)
            self.shouldKeepRunning = true
            
            if let cached = self.cachedItem {
                DispatchQueue.main.async {
                    onUpdate(cached)
                }
            }
            
            if !self.isRunning {
                self.launchProcess()
            } else {
                self.sendCommand("query")
            }
        }
    }
    
    public func stopObserving() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.shouldKeepRunning = false
            self.listeners.removeAll()
            self.pendingCompletions.removeAll()
            self.terminateProcess()
        }
    }
    
    public func fetchNowPlaying(completion: @escaping @Sendable (MediaItem?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.pendingCompletions.append(completion)
            
            if let cached = self.cachedItem {
                DispatchQueue.main.async {
                    completion(cached)
                }
            }
            
            if !self.isRunning {
                self.launchProcess()
            } else {
                self.sendCommand("query")
            }
        }
    }
    
    public func sendCommand(_ command: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if !self.isRunning || self.process == nil || self.process?.isRunning == false {
                if self.shouldKeepRunning {
                    self.launchProcess()
                }
            }
            guard let pipe = self.inputPipe else { return }
            guard let data = "\(command)\n".data(using: .utf8) else { return }
            do {
                try pipe.fileHandleForWriting.write(contentsOf: data)
            } catch {
                self.logger.error("❌ [MediaCLI] Failed to write command '\(command)': \(error.localizedDescription)")
                self.terminateProcess()
                if self.shouldKeepRunning {
                    self.launchProcess()
                }
            }
        }
    }
    
    public func seek(to seconds: Double) {
        sendCommand("seek:\(seconds)")
    }
    
    // MARK: - Process Management
    
    private func getHelperScriptURL() -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("macisland_mr_helper.swift")
        
        let shouldWrite: Bool
        if let existing = try? String(contentsOf: fileURL, encoding: .utf8) {
            shouldWrite = existing != helperScript
        } else {
            shouldWrite = true
        }
        
        if shouldWrite {
            try? helperScript.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        return fileURL
    }
    
    private func launchProcess() {
        guard !isRunning else { return }
        isRunning = true
        
        let scriptURL = getHelperScriptURL()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = [scriptURL.path]
        
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        
        process.standardInput = inPipe
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        self.inputPipe = inPipe
        self.outputPipe = outPipe
        self.process = process
        self.stdoutBuffer = Data()
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.queue.async {
                self?.handleOutputData(data)
            }
        }
        
        process.terminationHandler = { [weak self] proc in
            self?.queue.async {
                guard let self = self else { return }
                self.logger.warning("⚠️ [MediaCLI] Helper process terminated with code \(proc.terminationStatus)")
                self.isRunning = false
                self.outputPipe?.fileHandleForReading.readabilityHandler = nil
                self.inputPipe = nil
                self.outputPipe = nil
                self.process = nil
                
                if self.shouldKeepRunning {
                    self.logger.info("🔄 [MediaCLI] Restarting helper process in 1.0s...")
                    self.queue.asyncAfter(deadline: .now() + 1.0) {
                        if self.shouldKeepRunning && !self.isRunning {
                            self.launchProcess()
                        }
                    }
                }
            }
        }
        
        do {
            try process.run()
            logger.info("🚀 [MediaCLI] Persistent helper process started (PID: \(process.processIdentifier))")
        } catch {
            logger.error("❌ [MediaCLI] Failed to start helper process: \(error.localizedDescription)")
            isRunning = false
            inputPipe = nil
            outputPipe = nil
            self.process = nil
        }
    }
    
    private func terminateProcess() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        inputPipe = nil
        outputPipe = nil
        
        if let proc = process, proc.isRunning {
            proc.terminate()
        }
        process = nil
        isRunning = false
    }
    
    private func handleOutputData(_ data: Data) {
        stdoutBuffer.append(data)
        while let newlineIndex = stdoutBuffer.firstIndex(of: 0x0A) {
            let lineData = stdoutBuffer[..<newlineIndex]
            stdoutBuffer.removeSubrange(...newlineIndex)
            
            guard !lineData.isEmpty,
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }
            
            parseMediaJSON(json)
        }
    }
    
    private func parseMediaJSON(_ json: [String: Any]) {
        if json["empty"] as? Bool == true {
            cachedItem = nil
            dispatchMediaUpdate(nil)
            return
        }
        
        let title = json["title"] as? String ?? ""
        let artist = json["artist"] as? String ?? ""
        let album = json["album"] as? String ?? ""
        let duration = json["duration"] as? Double ?? 0.0
        let elapsedTime = json["elapsedTime"] as? Double ?? 0.0
        let playbackRate = json["playbackRate"] as? Double ?? 0.0
        let pid = json["pid"] as? pid_t ?? 0
        let timestamp = json["timestamp"] as? Double ?? Date().timeIntervalSince1970
        let lastUpdated = Date(timeIntervalSince1970: timestamp)
        
        // Artwork handling: only transmitted on change to minimize payload size
        let artworkId = json["artworkId"] as? String
        var artworkData: Data? = nil
        if let b64 = json["artwork"] as? String {
            if !b64.isEmpty {
                artworkData = Data(base64Encoded: b64)
                self.lastArtworkData = artworkData
                self.lastArtworkId = artworkId
            } else {
                let isSameTrack = (!title.isEmpty && title == self.cachedItem?.title && artist == self.cachedItem?.artist)
                if !isSameTrack {
                    self.lastArtworkData = nil
                    self.lastArtworkId = artworkId
                } else {
                    artworkData = self.lastArtworkData
                }
            }
        } else {
            // Delta JSON omitted artwork (common in periodic progress ticks) -> preserve existing artwork
            if let artworkId = artworkId, artworkId == self.lastArtworkId, self.lastArtworkData != nil {
                artworkData = self.lastArtworkData
            } else if let prev = self.cachedItem, !title.isEmpty, (title == prev.title || title.contains(prev.title) || prev.title.contains(title)) {
                artworkData = self.lastArtworkData ?? prev.artworkData
            } else {
                artworkData = self.lastArtworkData
            }
        }
        
        // Drop empty title if there is no active playback or PID
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard pid > 0 || duration > 0 || playbackRate > 0 else {
                cachedItem = nil
                dispatchMediaUpdate(nil)
                return
            }
        }
        
        var appName = "Media Player"
        var bundleId: String? = nil
        if pid > 0, let app = NSRunningApplication(processIdentifier: pid) {
            appName = app.localizedName ?? "Media Player"
            bundleId = app.bundleIdentifier
        }
        let lowerIdentifier = ((bundleId ?? "") + " " + appName).lowercased()
        if bundleId == nil || bundleId?.contains("helper") == true || appName.lowercased().contains("helper") {
            if lowerIdentifier.contains("brave") {
                bundleId = "com.brave.Browser"
                appName = "Brave Browser"
            } else if lowerIdentifier.contains("chrome") {
                bundleId = "com.google.Chrome"
                appName = "Google Chrome"
            } else if lowerIdentifier.contains("safari") {
                bundleId = "com.apple.Safari"
                appName = "Safari"
            } else if lowerIdentifier.contains("edge") {
                bundleId = "com.microsoft.edgemac"
                appName = "Microsoft Edge"
            } else if lowerIdentifier.contains("arc") {
                bundleId = "company.thebrowser.Arc"
                appName = "Arc"
            } else if lowerIdentifier.contains("opera") {
                bundleId = "com.operasoftware.Opera"
                appName = "Opera"
            }
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
        
        self.cachedItem = item
        dispatchMediaUpdate(item)
    }
    
    private func dispatchMediaUpdate(_ item: MediaItem?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for listener in self.listeners {
                listener(item)
            }
            let completions = self.pendingCompletions
            self.pendingCompletions.removeAll()
            for completion in completions {
                completion(item)
            }
        }
    }
}
