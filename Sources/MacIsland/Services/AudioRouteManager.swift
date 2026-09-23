import Foundation
import CoreAudio
import Combine
import AppKit
import IOBluetooth

// MARK: - AudioDeviceKind
public enum AudioDeviceKind: String, Sendable, CaseIterable {
    case builtInSpeaker      // MacBook / Mac internal speakers
    case wiredHeadphones     // 3.5mm AUX / Headphone Jack
    case airPods             // AirPods, AirPods Pro, AirPods Max
    case bluetoothHeadphones // Other Bluetooth headphones / earbuds
    case display             // External monitor / HDMI
    case other               // AirPlay, USB DAC, etc.
}

// MARK: - AudioOutputDevice
public struct AudioOutputDevice: Identifiable, Hashable, Sendable {
    public let id: String
    public let deviceID: AudioDeviceID
    public let uid: String
    public let name: String
    public let kind: AudioDeviceKind
    public let iconName: String
    public let isDefault: Bool
    public let isAirPods: Bool
    public let dataSourceID: UInt32?
    public let subtitle: String
}

// MARK: - AirPodsListeningMode
public enum AirPodsListeningMode: String, CaseIterable, Identifiable, Sendable {
    case noiseCancellation = "noiseCancellation"
    case off = "off"
    case transparency = "transparency"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .noiseCancellation:
            return "Noise Cancellation"
        case .off:
            return "Off"
        case .transparency:
            return "Transparency"
        }
    }
    
    public var iconName: String {
        switch self {
        case .noiseCancellation:
            return "ear.and.waveform"
        case .off:
            return "speaker.slash.fill"
        case .transparency:
            return "waveform"
        }
    }
}

// MARK: - BluetoothAudioDevice
public struct BluetoothAudioDevice: Identifiable, Hashable, Sendable {
    public let id: String // Address string
    public let name: String
    public let iconName: String
    public let isConnected: Bool
    public let isConnecting: Bool
    public let batteryLevel: Int?
}

// MARK: - AudioRouteManager
// Detects, manages, and switches macOS audio output routes using native CoreAudio & IOBluetooth APIs.
// Features:
// - Real-time CoreAudio device enumeration (Built-in Speakers, Wired AUX, AirPods, Bluetooth)
// - 1-Click instant audio output switching via AudioObjectSetPropertyData
// - AirPods listening mode switcher (Noise Cancellation, Off, Transparency)
// - Direct Bluetooth audio connection management via IOBluetooth
@MainActor
public final class AudioRouteManager: ObservableObject {
    public static let shared = AudioRouteManager()
    
    @Published public private(set) var activeRouteIcon: String? = "macbook"
    @Published public private(set) var deviceName: String = "Mac"
    @Published public private(set) var currentDeviceID: AudioDeviceID = 0
    @Published public private(set) var availableDevices: [AudioOutputDevice] = []
    @Published public private(set) var pairedBluetoothDevices: [BluetoothAudioDevice] = []
    @Published public private(set) var currentListeningMode: AirPodsListeningMode = .noiseCancellation
    @Published public private(set) var connectingDeviceAddress: String? = nil
    
    /// Returns true if connected AirPods (or supported headphones) are currently active or connected
    public var hasAirPodsActive: Bool {
        if let active = availableDevices.first(where: { $0.isDefault }) {
            return active.isAirPods
        }
        return activeRouteIcon?.contains("airpod") ?? false
    }
    
    /// Returns true if at least two physical routes are connected (e.g. Laptop speakers + AirPods or Wired AUX)
    public var hasMultipleRoutes: Bool {
        availableDevices.count >= 2
    }
    
    private var timer: Timer?
    private var isListeningToCoreAudio = false
    
    public init() {
        // Load saved listening mode preference
        if let savedModeStr = UserDefaults.standard.string(forKey: "MacIsland_AirPodsMode"),
           let mode = AirPodsListeningMode(rawValue: savedModeStr) {
            self.currentListeningMode = mode
        }
        
        updateRoute()
        setupCoreAudioListeners()
        
        // Scan bluetooth devices in background safely after app launch
        Task.detached(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            await self?.scanBluetoothDevices()
        }
        
        // Background polling fallback for hardware changes (relaxed to 15s since CoreAudio listeners handle most events)
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRoute()
            }
        }
    }
    
    // MARK: - CoreAudio Listeners
    
    private func setupCoreAudioListeners() {
        guard !isListeningToCoreAudio else { return }
        
        var defaultAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let defaultStatus = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddr,
            DispatchQueue.main
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateRoute()
            }
        }
        
        var devicesAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let devicesStatus = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddr,
            DispatchQueue.main
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateRoute()
                self?.scanBluetoothDevices()
            }
        }
        
        isListeningToCoreAudio = (defaultStatus == noErr && devicesStatus == noErr)
    }
    
    // MARK: - Update Routes & Devices
    
    public func updateRoute() {
        // 1. Get current default output device
        var defaultDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &defaultDeviceID
        )
        
        if status == noErr {
            self.currentDeviceID = defaultDeviceID
            let (name, icon) = getDeviceInfo(deviceID: defaultDeviceID)
            self.deviceName = name
            self.activeRouteIcon = icon
        } else {
            self.deviceName = "Mac"
            self.activeRouteIcon = "macbook"
        }
        
        // 2. Enumerate all output devices
        enumerateAllOutputDevices(defaultDeviceID: defaultDeviceID)
    }
    
    private func getDeviceInfo(deviceID: AudioDeviceID) -> (name: String, icon: String) {
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var nameCF: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let nameStatus = AudioObjectGetPropertyData(
            deviceID,
            &nameAddress,
            0,
            nil,
            &dataSize,
            &nameCF
        )
        let name = (nameStatus == noErr && nameCF != nil) ? (nameCF!.takeRetainedValue() as String) : "Mac"
        
        var transport: UInt32 = 0
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            deviceID,
            &transportAddress,
            0,
            nil,
            &transportSize,
            &transport
        )
        
        let icon = determineIcon(name: name, transport: transport)
        return (name, icon)
    }
    
    private func determineIcon(name: String, transport: UInt32) -> String {
        let lowerName = name.lowercased()
        if lowerName.contains("airpods max") {
            return "airpodsmax"
        } else if lowerName.contains("airpods pro") {
            return "airpodspro"
        } else if lowerName.contains("airpods") {
            return "airpods"
        } else if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE || lowerName.contains("headphone") || lowerName.contains("buds") || lowerName.contains("wh-1000") || lowerName.contains("bose") {
            return "headphones"
        } else if transport == kAudioDeviceTransportTypeAirPlay || lowerName.contains("airplay") {
            return "airplayaudio"
        } else if lowerName.contains("homepod") {
            return "hifispeaker.fill"
        } else if lowerName.contains("apple tv") || lowerName.contains("tv") {
            return "tv"
        } else if transport == kAudioDeviceTransportTypeDisplayPort || transport == kAudioDeviceTransportTypeHDMI || lowerName.contains("display") || lowerName.contains("hdmi") {
            return "display"
        } else if lowerName.contains("imac") || lowerName.contains("mac mini") || lowerName.contains("mac studio") || lowerName.contains("mac pro") {
            return "desktopcomputer"
        } else {
            return "macbook"
        }
    }
    
    private func determineKind(name: String, transport: UInt32) -> AudioDeviceKind {
        let lowerName = name.lowercased()
        if lowerName.contains("airpods") {
            return .airPods
        } else if lowerName.contains("external headphone") || lowerName.contains("wired") || lowerName.contains("aux") || lowerName.contains("earphone") {
            return .wiredHeadphones
        } else if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE || lowerName.contains("headphone") || lowerName.contains("buds") {
            return .bluetoothHeadphones
        } else if transport == kAudioDeviceTransportTypeDisplayPort || transport == kAudioDeviceTransportTypeHDMI || lowerName.contains("display") {
            return .display
        } else if transport == kAudioDeviceTransportTypeBuiltIn {
            return .builtInSpeaker
        } else {
            return .other
        }
    }
    
    private func enumerateAllOutputDevices(defaultDeviceID: AudioDeviceID) {
        var devAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var devSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devAddr, 0, nil, &devSize)
        let count = Int(devSize) / MemoryLayout<AudioDeviceID>.size
        guard count > 0 else { return }
        
        var devIDs = [AudioDeviceID](repeating: 0, count: count)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devAddr, 0, nil, &devSize, &devIDs)
        
        var devicesList: [AudioOutputDevice] = []
        
        for dev in devIDs {
            // Check if device has output streams
            var streamAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(dev, &streamAddr, 0, nil, &streamSize)
            guard streamSize > 0 else { continue }
            
            // Name
            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameCF: Unmanaged<CFString>?
            var nSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            AudioObjectGetPropertyData(dev, &nameAddr, 0, nil, &nSize, &nameCF)
            let name = (nameCF?.takeRetainedValue() as String?) ?? "Audio Device"
            
            // Transport
            var tAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyTransportType,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var transport: UInt32 = 0
            var tSize = UInt32(MemoryLayout<UInt32>.size)
            AudioObjectGetPropertyData(dev, &tAddr, 0, nil, &tSize, &transport)
            
            // Skip virtual drivers like Microsoft Teams, Zoom, Loopback unless desired
            if transport == 1986622068 || name.contains("Loopback") || name.contains("Zoom") || name.contains("Teams Audio") {
                continue
            }
            
            // UID
            var uidAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var uidCF: Unmanaged<CFString>?
            var uSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            AudioObjectGetPropertyData(dev, &uidAddr, 0, nil, &uSize, &uidCF)
            let uid = (uidCF?.takeRetainedValue() as String?) ?? "\(dev)"
            
            let kind = determineKind(name: name, transport: transport)
            let icon = determineIcon(name: name, transport: transport)
            let isDefault = (dev == defaultDeviceID)
            let isAirPods = kind == .airPods
            
            var subtitle = ""
            if isDefault {
                subtitle = ""
            } else if kind == .builtInSpeaker {
                subtitle = ""
            } else if isAirPods || kind == .bluetoothHeadphones {
                subtitle = "Connected"
            } else if kind == .wiredHeadphones {
                subtitle = "3.5mm Headphone Jack"
            }
            
            // Check for data sources on built-in audio device (e.g. ispk vs hdpn)
            if transport == kAudioDeviceTransportTypeBuiltIn {
                var dsAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDataSources,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                var dsSize: UInt32 = 0
                AudioObjectGetPropertyDataSize(dev, &dsAddr, 0, nil, &dsSize)
                let dsCount = Int(dsSize) / MemoryLayout<UInt32>.size
                
                if dsCount > 1 {
                    var sources = [UInt32](repeating: 0, count: dsCount)
                    AudioObjectGetPropertyData(dev, &dsAddr, 0, nil, &dsSize, &sources)
                    
                    var currentDS: UInt32 = 0
                    var currentDSSize = UInt32(MemoryLayout<UInt32>.size)
                    var curDSAddr = AudioObjectPropertyAddress(
                        mSelector: kAudioDevicePropertyDataSource,
                        mScope: kAudioDevicePropertyScopeOutput,
                        mElement: kAudioObjectPropertyElementMain
                    )
                    AudioObjectGetPropertyData(dev, &curDSAddr, 0, nil, &currentDSSize, &currentDS)
                    
                    for source in sources {
                        let isHeadphoneSource = (source == 1751412846) // 'hdpn'
                        let sourceName = isHeadphoneSource ? "External Headphones" : name
                        let sourceIcon = isHeadphoneSource ? "headphones" : icon
                        let sourceKind: AudioDeviceKind = isHeadphoneSource ? .wiredHeadphones : .builtInSpeaker
                        let sourceActive = isDefault && (source == currentDS)
                        
                        devicesList.append(AudioOutputDevice(
                            id: "\(dev)_\(source)",
                            deviceID: dev,
                            uid: "\(uid)_\(source)",
                            name: sourceName,
                            kind: sourceKind,
                            iconName: sourceIcon,
                            isDefault: sourceActive,
                            isAirPods: false,
                            dataSourceID: source,
                            subtitle: (isHeadphoneSource ? "3.5mm Headphone Jack" : "")
                        ))
                    }
                    continue
                }
            }
            
            devicesList.append(AudioOutputDevice(
                id: "\(dev)",
                deviceID: dev,
                uid: uid,
                name: name,
                kind: kind,
                iconName: icon,
                isDefault: isDefault,
                isAirPods: isAirPods,
                dataSourceID: nil,
                subtitle: subtitle
            ))
        }
        
        // Sort devices: Default first, then Built-in, then AirPods/Headphones
        devicesList.sort { a, b in
            if a.isDefault != b.isDefault { return a.isDefault }
            if a.kind == .builtInSpeaker && b.kind != .builtInSpeaker { return true }
            return false
        }
        
        self.availableDevices = devicesList
    }
    
    // MARK: - Bluetooth Scanning
    
    public func scanBluetoothDevices() {
        let connectingAddr = self.connectingDeviceAddress
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
                DispatchQueue.main.async {
                    self?.pairedBluetoothDevices = []
                }
                return
            }
            
            var list: [BluetoothAudioDevice] = []
            for dev in paired {
                let name = dev.nameOrAddress ?? "Bluetooth Device"
                let isConnected = dev.isConnected()
                let majorClass = dev.deviceClassMajor
                let lowerName = name.lowercased()
                
                // Strictly filter to audio devices (Headphones, AirPods, Speakers)
                let isAudioClass = (majorClass == 4) // kBluetoothDeviceClassMajorAudio
                let hasAudioKeyword = lowerName.contains("airpod") || lowerName.contains("buds") || lowerName.contains("headphone") || lowerName.contains("speaker") || lowerName.contains("wh-1000") || lowerName.contains("bose") || lowerName.contains("rockerz") || lowerName.contains("sound") || lowerName.contains("audio") || lowerName.contains("pro")
                
                guard isAudioClass || hasAudioKeyword else { continue }
                
                let addr = dev.addressString ?? ""
                let icon: String
                if lowerName.contains("airpods max") {
                    icon = "airpodsmax"
                } else if lowerName.contains("airpods pro") {
                    icon = "airpodspro"
                } else if lowerName.contains("airpods") {
                    icon = "airpods"
                } else if lowerName.contains("speaker") {
                    icon = "speaker.wave.2"
                } else {
                    icon = "headphones"
                }
                
                // Extract single battery percentage dynamically if connected
                var battery: Int? = nil
                if isConnected {
                    if let b = dev.value(forKey: "batteryPercentSingle") as? Int, b > 0 && b <= 100 {
                        battery = b
                    }
                }
                
                let isConnecting = (connectingAddr == addr)
                
                list.append(BluetoothAudioDevice(
                    id: addr,
                    name: name,
                    iconName: icon,
                    isConnected: isConnected,
                    isConnecting: isConnecting,
                    batteryLevel: battery
                ))
            }
            
            // Sort: connected first, then alphabetically
            list.sort { a, b in
                if a.isConnected != b.isConnected { return a.isConnected }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
            
            DispatchQueue.main.async {
                self?.pairedBluetoothDevices = list
            }
        }
    }
    
    // MARK: - Device Switching
    
    /// Switches macOS default audio output to the chosen device immediately via CoreAudio
    public func selectOutputDevice(_ device: AudioOutputDevice) {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        
        // 1. If device uses a specific dataSource (e.g. 3.5mm jack vs internal speaker), switch dataSource
        if let sourceID = device.dataSourceID {
            var ds = sourceID
            var dsAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDataSource,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectSetPropertyData(
                device.deviceID,
                &dsAddr,
                0,
                nil,
                UInt32(MemoryLayout<UInt32>.size),
                &ds
            )
        }
        
        // 2. Set default output device
        var targetID = device.deviceID
        var defaultAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddr,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &targetID
        )
        
        if status == noErr {
            self.currentDeviceID = targetID
            self.deviceName = device.name
            self.activeRouteIcon = device.iconName
            updateRoute()
        }
    }
    
    /// Quick toggle between Laptop Speakers and external headphones/AirPods if both are available
    public func toggleBetweenPrimaryRoutes() {
        guard availableDevices.count >= 2 else { return }
        
        let current = availableDevices.first(where: { $0.isDefault })
        if let current = current {
            // If currently on speaker, switch to first non-speaker
            if current.kind == .builtInSpeaker {
                if let target = availableDevices.first(where: { $0.kind != .builtInSpeaker }) {
                    selectOutputDevice(target)
                    return
                }
            } else {
                // Currently on headphones/AirPods, switch back to built-in speaker
                if let target = availableDevices.first(where: { $0.kind == .builtInSpeaker }) {
                    selectOutputDevice(target)
                    return
                }
            }
        }
        
        // Fallback: switch to first non-default
        if let target = availableDevices.first(where: { !$0.isDefault }) {
            selectOutputDevice(target)
        }
    }
    
    // MARK: - Direct Bluetooth Connect
    
    public func connectBluetoothDevice(_ device: BluetoothAudioDevice) {
        guard let btDevice = IOBluetoothDevice(addressString: device.id) else { return }
        
        self.connectingDeviceAddress = device.id
        scanBluetoothDevices()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        
        Task.detached(priority: .userInitiated) { [weak self] in
            // Attempt to establish Bluetooth connection
            btDevice.openConnection()
            
            // Wait up to 3 seconds for connection and CoreAudio to bind
            var didConnect = false
            for _ in 0..<15 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if btDevice.isConnected() {
                    didConnect = true
                    break
                }
            }
            
            let wasConnected = didConnect
            // Switch audio output to this device once connected
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.connectingDeviceAddress = nil
                self.updateRoute()
                self.scanBluetoothDevices()
                
                if wasConnected {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    // If CoreAudio recognized it, select it!
                    if let output = self.availableDevices.first(where: { $0.name.localizedCaseInsensitiveContains(device.name) || device.name.localizedCaseInsensitiveContains($0.name) }) {
                        self.selectOutputDevice(output)
                    }
                }
            }
        }
    }
    
    // MARK: - AirPods Listening Mode
    
    public func setListeningMode(_ mode: AirPodsListeningMode) {
        self.currentListeningMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "MacIsland_AirPodsMode")
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        
        // Attempt system shortcut or script trigger if configured
        Task.detached(priority: .background) {
            let modeParam: String
            switch mode {
            case .noiseCancellation: modeParam = "Noise Cancellation"
            case .off: modeParam = "Off"
            case .transparency: modeParam = "Transparency"
            }
            
            // Check if user has a Shortcuts action named "Set Noise Control Mode"
            let script = """
            tell application "Shortcuts Events"
                try
                    run shortcut "Set Noise Control Mode" with input "\(modeParam)"
                end try
            end tell
            """
            var err: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&err)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

