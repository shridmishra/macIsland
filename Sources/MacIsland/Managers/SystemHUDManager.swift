import Foundation
import CoreAudio
import CoreGraphics
import AppKit
import SwiftUI
import Combine

// MARK: - HUDType
public enum HUDType: Equatable, Sendable {
    case none
    case volume
    case brightness
    case battery
}

// MARK: - MediaKeyEventTap
// Runs a dedicated high-priority Thread with a persistent runloop and watchdog
// to guarantee 0ms latency, prevent timeouts, and automatically heal if disabled by macOS.
private final class MediaKeyEventTap: @unchecked Sendable {
    private(set) var eventTap: CFMachPort?
    private var tapRunLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?
    private var workerThread: Thread?
    private var isRunning: Bool = false
    
    private var savedCallback: CGEventTapCallBack?
    private var savedUserInfo: UnsafeMutableRawPointer?
    
    func start(callback: @escaping CGEventTapCallBack, userInfo: UnsafeMutableRawPointer?) -> Bool {
        self.savedCallback = callback
        self.savedUserInfo = userInfo
        stop()
        
        // NX_SYSDEFINED (14) intercepts all media and brightness keys (volume up/down/mute, brightness up/down).
        // Standard Accessibility permission allows intercepting NX_SYSDEFINED.
        // It does NOT request general keydown/keyup events, avoiding unnecessary Input Monitoring permission prompts.
        let eventMask = CGEventMask(1 << 14)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            return false
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.tapRunLoopSource = source
        self.isRunning = true
        
        let thread = Thread { [weak self] in
            guard let self = self, let source = self.tapRunLoopSource, let tap = self.eventTap else { return }
            let runLoop = CFRunLoopGetCurrent()
            self.tapRunLoop = runLoop
            CFRunLoopAddSource(runLoop, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            
            // Persistent loop - never exits on timeout or source state changes
            while self.isRunning {
                _ = CFRunLoopRunInMode(.defaultMode, 0.5, false)
                self.checkHealth()
            }
        }
        thread.name = "com.macisland.eventtap.thread"
        thread.qualityOfService = .userInteractive
        self.workerThread = thread
        thread.start()
        
        return true
    }
    
    func checkHealth() {
        guard isRunning else { return }
        guard let tap = eventTap else {
            recreateTap()
            return
        }
        
        if !CFMachPortIsValid(tap) {
            recreateTap()
            return
        }
        
        if !CGEvent.tapIsEnabled(tap: tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
    
    func ensureHealthy() {
        checkHealth()
    }
    
    func recreateTap() {
        guard let cb = savedCallback, isRunning else { return }
        let userInfo = savedUserInfo
        _ = start(callback: cb, userInfo: userInfo)
    }
    
    func stop() {
        isRunning = false
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.eventTap = nil
        }
        if let source = tapRunLoopSource {
            if let runLoop = tapRunLoop {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }
            self.tapRunLoopSource = nil
        }
        if let runLoop = tapRunLoop {
            CFRunLoopStop(runLoop)
            self.tapRunLoop = nil
        }
        self.workerThread?.cancel()
        self.workerThread = nil
    }
    
    func reEnable() {
        guard let tap = eventTap else {
            recreateTap()
            return
        }
        if !CGEvent.tapIsEnabled(tap: tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

// MARK: - SystemHUDManager
// Monitors and publishes system volume and display brightness changes in real time.
// Intercepts hardware keys (F1/F2, F10/F11/F12), CoreAudio property changes, and DisplayServices brightness
// to display Apple Dynamic Island style HUD indicators flanking the camera notch:
// - Left wing: Brightness or Volume icon
// - Right wing: Animated level bar reflecting increases / decreases
// Consumes media/brightness events to suppress the native macOS bezel overlay.
@MainActor
public final class SystemHUDManager: ObservableObject {
    public static let shared = SystemHUDManager()
    
    @Published public private(set) var isHUDActive: Bool = false
    @Published public private(set) var hudType: HUDType = .none
    @Published public private(set) var level: Float = 0.5
    @Published public private(set) var isMuted: Bool = false
    
    // Battery HUD state
    @Published public private(set) var batteryIconName: String = "battery.100percent.bolt"
    @Published public private(set) var batteryText: String = "100% · Charging"
    @Published public private(set) var batteryColor: Color = Color.islandBatteryCharging
    @Published public private(set) var batteryPercentage: Int = 100
    
    // Auto-dismiss work item
    private var dismissWorkItem: DispatchWorkItem?
    
    // CoreAudio listener state
    private var currentAudioDeviceID: AudioDeviceID = 0
    private var lastRecordedVolume: Float = 0.5
    private var isAudioInitialized = false
    
    // DisplayServices function pointers
    private typealias DisplayServicesGetBrightnessType = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetBrightnessType = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private var getBrightnessFn: DisplayServicesGetBrightnessType?
    private var setBrightnessFn: DisplayServicesSetBrightnessType?
    
    // Brightness monitoring state
    private var brightnessTimer: Timer?
    private var lastRecordedBrightness: Float = 0.5
    private var isBrightnessInitialized = false
    
    // Global event monitor for media keys (fallback when AX is not yet trusted)
    private var eventMonitor: Any?
    
    // Dedicated event tap helper & permission watcher
    private var mediaKeyTap: MediaKeyEventTap?
    private var permissionPollTimer: Timer?
    private var watchdogTimer: Timer?
    private var notificationObservers: [NSObjectProtocol] = []
    
    // OSDManager function pointer / selector cache for fast native OSD dismissal
    private typealias FadeOSDFn = @convention(c) (AnyObject, Selector, UInt32) -> Void
    private var osdManagerInstance: AnyObject?
    private var fadeOSDSelector: Selector?
    private var fadeOSDImp: FadeOSDFn?
    
    public init() {
        setupOSDManager()
        setupDisplayServices()
        setupAudioListeners()
        startBrightnessPolling()
        setupEventTap()
        setupWatchdog()
    }
    
    // MARK: - Public Dynamic Icons
    public var volumeIconName: String {
        if isMuted || level <= 0.001 {
            return "speaker.slash.fill"
        } else if level < 0.33 {
            return "speaker.wave.1.fill"
        } else if level < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    public var brightnessIconName: String {
        "sun.max.fill"
    }
    
    // MARK: - HUD Presentation & Dismissal
    public func triggerHUD(type: HUDType, level: Float, isMuted: Bool = false) {
        dismissWorkItem?.cancel()
        dismissNativeOSD()
        
        if WindowManager.shared.islandState.isExpanded {
            WindowManager.shared.collapse()
        }
        
        let targetLevel = isMuted ? 0.0 : max(0.0, min(1.0, level))
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
            self.hudType = type
            self.level = targetLevel
            self.isMuted = isMuted
            self.isHUDActive = true
        }
        
        // Auto-dismiss after 1.8 seconds of inactivity
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    self.isHUDActive = false
                    self.hudType = .none
                }
            }
        }
        self.dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }
    
    /// Triggers the Dynamic Island battery HUD notification (plugged in, charged, disconnected, low battery)
    public func triggerBatteryHUD(
        icon: String,
        text: String,
        color: Color,
        percentage: Int,
        duration: Double = 2.5
    ) {
        dismissWorkItem?.cancel()
        dismissNativeOSD()
        
        if WindowManager.shared.islandState.isExpanded {
            WindowManager.shared.collapse()
        }
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
            self.batteryIconName = icon
            self.batteryText = text
            self.batteryColor = color
            self.batteryPercentage = percentage
            self.hudType = .battery
            self.level = Float(percentage) / 100.0
            self.isHUDActive = true
        }
        
        // Auto-dismiss after specified duration (defaults to 2.5s for comfortable readability)
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    self.isHUDActive = false
                    self.hudType = .none
                }
            }
        }
        self.dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    // MARK: - OSD.framework Integration (Secondary Bezel Suppression)
    private func setupOSDManager() {
        _ = dlopen("/System/Library/PrivateFrameworks/OSD.framework/OSD", RTLD_LAZY)
        if let osdClass = NSClassFromString("OSDManager") as? NSObject.Type {
            let sharedSel = NSSelectorFromString("sharedManager")
            if osdClass.responds(to: sharedSel),
               let manager = osdClass.perform(sharedSel)?.takeUnretainedValue() {
                self.osdManagerInstance = manager
                let fadeSel = NSSelectorFromString("fadeClassicImageOnDisplay:")
                if (manager as AnyObject).responds(to: fadeSel) {
                    self.fadeOSDSelector = fadeSel
                    let imp = (manager as AnyObject).method(for: fadeSel)
                    self.fadeOSDImp = unsafeBitCast(imp, to: FadeOSDFn.self)
                }
            }
        }
    }
    
    public func dismissNativeOSD() {
        guard let manager = osdManagerInstance,
              let sel = fadeOSDSelector,
              let fn = fadeOSDImp else { return }
        fn(manager, sel, CGMainDisplayID())
    }
    
    // MARK: - CoreAudio Volume Integration
    private func setupAudioListeners() {
        let dev = getDefaultOutputDevice()
        self.currentAudioDeviceID = dev
        
        let initialVol = getVolume(deviceID: dev)
        let initialMute = getMute(deviceID: dev)
        self.lastRecordedVolume = initialVol
        self.level = initialMute ? 0.0 : initialVol
        self.isMuted = initialMute
        self.isAudioInitialized = true
        
        attachAudioDeviceListeners(to: dev)
        listenForDefaultDeviceChanges()
    }
    
    private func getDefaultOutputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return deviceID
    }
    
    private func getVolume(deviceID: AudioDeviceID) -> Float32 {
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        if status != noErr {
            address.mElement = 1
            status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        }
        return status == noErr ? volume : 0.5
    }
    
    private func getMute(deviceID: AudioDeviceID) -> Bool {
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &mute)
        if status != noErr {
            address.mElement = 1
            status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &mute)
        }
        return status == noErr ? (mute != 0) : false
    }
    
    private func attachAudioDeviceListeners(to dev: AudioDeviceID) {
        guard dev != 0 else { return }
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(dev, &volAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.handleAudioChange()
            }
        }
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(dev, &muteAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.handleAudioChange()
            }
        }
    }
    
    private func listenForDefaultDeviceChanges() {
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let newDev = self.getDefaultOutputDevice()
                if newDev != self.currentAudioDeviceID {
                    self.currentAudioDeviceID = newDev
                    self.attachAudioDeviceListeners(to: newDev)
                    self.handleAudioChange()
                }
            }
        }
    }
    
    private func handleAudioChange() {
        let dev = getDefaultOutputDevice()
        let vol = getVolume(deviceID: dev)
        let mute = getMute(deviceID: dev)
        
        if isAudioInitialized {
            triggerHUD(type: .volume, level: vol, isMuted: mute)
        }
        self.lastRecordedVolume = vol
        self.isMuted = mute
    }
    
    public func setVolume(_ newVolume: Float) {
        let dev = getDefaultOutputDevice()
        guard dev != 0 else { return }
        var vol = max(0.0, min(1.0, newVolume))
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &vol)
        if status != noErr {
            address.mElement = 1
            _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &vol)
        }
        triggerHUD(type: .volume, level: vol, isMuted: false)
    }
    
    public func toggleMute() {
        let dev = getDefaultOutputDevice()
        guard dev != 0 else { return }
        let currentMute = getMute(deviceID: dev)
        var newMute: UInt32 = currentMute ? 0 : 1
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &newMute)
        address.mElement = 1
        _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &newMute)
        
        let vol = getVolume(deviceID: dev)
        self.isMuted = (newMute != 0)
        triggerHUD(type: .volume, level: vol, isMuted: self.isMuted)
    }
    
    // MARK: - DisplayServices Brightness Integration
    private func setupDisplayServices() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let symGet = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFn = unsafeBitCast(symGet, to: DisplayServicesGetBrightnessType.self)
            }
            if let symSet = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFn = unsafeBitCast(symSet, to: DisplayServicesSetBrightnessType.self)
            }
        }
        
        let initialB = getCurrentBrightness()
        self.lastRecordedBrightness = initialB
        self.isBrightnessInitialized = true
    }
    
    public func getCurrentBrightness() -> Float {
        guard let fn = getBrightnessFn else { return 0.5 }
        var b: Float = 0
        let res = fn(CGMainDisplayID(), &b)
        return res == 0 ? max(0.0, min(1.0, b)) : 0.5
    }
    
    public func setBrightness(_ newBrightness: Float) {
        guard let fn = setBrightnessFn else { return }
        let val = max(0.0, min(1.0, newBrightness))
        _ = fn(CGMainDisplayID(), val)
        self.lastRecordedBrightness = val
        triggerHUD(type: .brightness, level: val)
    }
    
    private func startBrightnessPolling() {
        brightnessTimer?.invalidate()
        // Fast, ultra-lightweight check every 80ms
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isBrightnessInitialized else { return }
                let current = self.getCurrentBrightness()
                // Never let background brightness changes override an active Battery notification
                if self.isHUDActive && self.hudType == .battery {
                    self.lastRecordedBrightness = current
                    return
                }
                if abs(current - self.lastRecordedBrightness) > 0.005 {
                    self.lastRecordedBrightness = current
                    self.triggerHUD(type: .brightness, level: current)
                }
            }
        }
    }
    
    // MARK: - Event Tap Media Key Interception & Native OSD Suppression
    public func setupEventTap() {
        if mediaKeyTap == nil {
            mediaKeyTap = MediaKeyEventTap()
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<SystemHUDManager>.fromOpaque(refcon).takeUnretainedValue()
            
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = manager.mediaKeyTap?.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                manager.mediaKeyTap?.reEnable()
                return Unmanaged.passUnretained(event)
            }
            
            // 1. Handle regular keyboard function keys for brightness
            if type == .keyDown || type == .keyUp {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                if keyCode == 144 || keyCode == 145 || keyCode == 107 || keyCode == 113 {
                    let flags = event.flags
                    if flags.contains(.maskAlternate) && !flags.contains(.maskShift) {
                        return Unmanaged.passUnretained(event)
                    }
                    if type == .keyDown {
                        let isSmallStep = flags.contains(.maskShift) && flags.contains(.maskAlternate)
                        let step: Float = isSmallStep ? (1.0 / 64.0) : (1.0 / 16.0)
                        let isUp = (keyCode == 144 || keyCode == 113)
                        DispatchQueue.main.async {
                            manager.stepBrightness(isUp: isUp, step: step)
                        }
                    }
                    return nil
                }
                return Unmanaged.passUnretained(event)
            }
            
            // 2. Handle NX_SYSDEFINED (media keys: volume up/down/mute, brightness up/down)
            if type.rawValue == 14 {
                if let nsEvent = NSEvent(cgEvent: event) {
                    let data1 = nsEvent.data1
                    let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
                    let keyFlags = (data1 & 0x0000FFFF)
                    let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
                    
                    let isVolumeKey = (keyCode == 0 || keyCode == 1 || keyCode == 7)
                    let isBrightnessKey = (keyCode == 2 || keyCode == 3)
                    
                    if isVolumeKey || isBrightnessKey {
                        let modifierFlags = nsEvent.modifierFlags
                        if modifierFlags.contains(.option) && !modifierFlags.contains(.shift) {
                            return Unmanaged.passUnretained(event)
                        }
                        if keyState {
                            let isSmallStep = modifierFlags.contains(.shift) && modifierFlags.contains(.option)
                            let step: Float = isSmallStep ? (1.0 / 64.0) : (1.0 / 16.0)
                            DispatchQueue.main.async {
                                manager.handleMediaKey(keyCode: keyCode, step: step)
                            }
                        }
                        return nil
                    }
                }
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        let success = mediaKeyTap?.start(callback: callback, userInfo: selfPtr) ?? false
        if !success {
            ensureAccessibilityPermissions()
            setupGlobalKeyMonitor()
        } else {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    private var hasPromptedForAccessibility = false
    
    public func ensureAccessibilityPermissions() {
        if AXIsProcessTrusted() {
            return
        }
        if !hasPromptedForAccessibility {
            hasPromptedForAccessibility = true
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self.permissionPollTimer = nil
                    if let monitor = self.eventMonitor {
                        NSEvent.removeMonitor(monitor)
                        self.eventMonitor = nil
                    }
                    self.setupEventTap()
                }
            }
        }
    }
    
    // Legacy / backward-compatibility methods
    public func disableNativeOSD() {
        dismissNativeOSD()
    }
    
    public func restoreNativeOSD() {
        // No persistent configuration needed
    }
    
    public func handleMediaKey(keyCode: Int32, step: Float) {
        switch keyCode {
        case 0: // SOUND_UP
            let dev = getDefaultOutputDevice()
            if isMuted {
                unmute(deviceID: dev)
            }
            let cur = getVolume(deviceID: dev)
            let newVol = min(1.0, cur + step)
            setVolume(newVol)
            playVolumeFeedbackIfEnabled()
        case 1: // SOUND_DOWN
            let dev = getDefaultOutputDevice()
            let cur = getVolume(deviceID: dev)
            let newVol = max(0.0, cur - step)
            setVolume(newVol)
            playVolumeFeedbackIfEnabled()
        case 7: // MUTE
            toggleMute()
        case 2: // BRIGHTNESS_UP
            stepBrightness(isUp: true, step: step)
        case 3: // BRIGHTNESS_DOWN
            stepBrightness(isUp: false, step: step)
        default:
            break
        }
    }
    
    public func stepBrightness(isUp: Bool, step: Float) {
        let cur = getCurrentBrightness()
        let newB = isUp ? min(1.0, cur + step) : max(0.0, cur - step)
        setBrightness(newB)
    }
    
    public func unmute(deviceID: AudioDeviceID? = nil) {
        let dev = deviceID ?? getDefaultOutputDevice()
        guard dev != 0 else { return }
        var mute: UInt32 = 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &mute)
        address.mElement = 1
        self.isMuted = false
    }
    
    public func toggleMute(deviceID: AudioDeviceID? = nil) {
        let dev = deviceID ?? getDefaultOutputDevice()
        guard dev != 0 else { return }
        let currentMute = getMute(deviceID: dev)
        var newMute: UInt32 = currentMute ? 0 : 1
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &newMute)
        address.mElement = 1
        _ = AudioObjectSetPropertyData(dev, &address, 0, nil, size, &newMute)
        self.isMuted = !currentMute
    }
    
    private func playVolumeFeedbackIfEnabled() {
        let isFeedbackEnabled = UserDefaults.standard.persistentDomain(forName: "NSGlobalDomain")?["com.apple.sound.beep.feedback"] as? Int == 1
        if isFeedbackEnabled {
            if let sound = NSSound(contentsOfFile: "/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff", byReference: true) {
                sound.play()
            }
        }
    }
    
    // Fallback observer if event tap cannot be created
    private func setupGlobalKeyMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            guard event.type == .systemDefined, event.subtype.rawValue == 8 else { return }
            let data1 = event.data1
            let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
            let keyFlags = (data1 & 0x0000FFFF)
            let keyState = ((keyFlags & 0xFF00) >> 8) == 0xA
            
            guard keyState else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch keyCode {
                case 0, 1:
                    let dev = self.getDefaultOutputDevice()
                    let vol = self.getVolume(deviceID: dev)
                    let mute = self.getMute(deviceID: dev)
                    self.triggerHUD(type: .volume, level: vol, isMuted: mute)
                case 2, 3:
                    let b = self.getCurrentBrightness()
                    self.triggerHUD(type: .brightness, level: b)
                case 7:
                    let dev = self.getDefaultOutputDevice()
                    let vol = self.getVolume(deviceID: dev)
                    let mute = self.getMute(deviceID: dev)
                    self.triggerHUD(type: .volume, level: vol, isMuted: mute)
                default:
                    break
                }
            }
        }
    }
    
    private func setupWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.mediaKeyTap?.ensureHealthy()
            }
        }
        
        let nc = NSWorkspace.shared.notificationCenter
        let wakeObs = nc.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.mediaKeyTap?.ensureHealthy()
                self?.dismissNativeOSD()
            }
        }
        let screensObs = nc.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.mediaKeyTap?.ensureHealthy()
                self?.dismissNativeOSD()
            }
        }
        let sessionObs = nc.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.mediaKeyTap?.ensureHealthy()
                self?.dismissNativeOSD()
            }
        }
        notificationObservers = [wakeObs, screensObs, sessionObs]
    }
    
    deinit {
        brightnessTimer?.invalidate()
        permissionPollTimer?.invalidate()
        watchdogTimer?.invalidate()
        for obs in notificationObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        mediaKeyTap?.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
