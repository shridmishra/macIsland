import Foundation
import CoreAudio
import Combine

// MARK: - AudioRouteManager
// Detects the active macOS audio output device using native CoreAudio APIs.
// Intelligently maps active output device to its authentic SF Symbol:
// - MacBook Air / Pro Speakers -> "macbook"
// - Desktop Mac (iMac, Mac mini, Studio, Pro) -> "desktopcomputer"
// - AirPods / AirPods Pro / AirPods Max -> "airpods" / "airpodspro" / "airpodsmax"
// - Bluetooth headphones / Earbuds -> "headphones"
// - AirPlay -> "airplayaudio"
// - External Display / HDMI -> "display"
// - HomePod -> "hifispeaker.fill"
@MainActor
public final class AudioRouteManager: ObservableObject {
    public static let shared = AudioRouteManager()
    
    @Published public private(set) var activeRouteIcon: String? = "macbook"
    @Published public private(set) var deviceName: String = "Mac"
    
    private var timer: Timer?
    
    public init() {
        updateRoute()
        // Check for audio route changes periodically
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRoute()
            }
        }
    }
    
    public func updateRoute() {
        var deviceID = AudioDeviceID(0)
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
            &deviceID
        )
        guard status == noErr else {
            activeRouteIcon = "macbook"
            return
        }
        
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
        self.deviceName = name
        
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
        
        let lowerName = name.lowercased()
        if lowerName.contains("airpods max") {
            activeRouteIcon = "airpodsmax"
        } else if lowerName.contains("airpods pro") {
            activeRouteIcon = "airpodspro"
        } else if lowerName.contains("airpods") {
            activeRouteIcon = "airpods"
        } else if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE || lowerName.contains("headphone") || lowerName.contains("buds") || lowerName.contains("wh-1000") || lowerName.contains("bose") {
            activeRouteIcon = "headphones"
        } else if transport == kAudioDeviceTransportTypeAirPlay || lowerName.contains("airplay") {
            activeRouteIcon = "airplayaudio"
        } else if lowerName.contains("homepod") {
            activeRouteIcon = "hifispeaker.fill"
        } else if lowerName.contains("apple tv") || lowerName.contains("tv") {
            activeRouteIcon = "tv"
        } else if transport == kAudioDeviceTransportTypeDisplayPort || transport == kAudioDeviceTransportTypeHDMI || lowerName.contains("display") || lowerName.contains("hdmi") {
            activeRouteIcon = "display"
        } else if lowerName.contains("imac") || lowerName.contains("mac mini") || lowerName.contains("mac studio") || lowerName.contains("mac pro") {
            activeRouteIcon = "desktopcomputer"
        } else {
            // Built-in MacBook Speakers (MacBook Air / MacBook Pro)
            activeRouteIcon = "macbook"
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
