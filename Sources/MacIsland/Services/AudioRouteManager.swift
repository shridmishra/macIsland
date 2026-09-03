import Foundation
import CoreAudio
import Combine

// MARK: - AudioRouteManager
// Detects the active macOS audio output device using native CoreAudio APIs.
// Matches Apple Dynamic Island:
// - Built-in speakers -> No icon shown (nil)
// - AirPods -> "airpodspro"
// - Bluetooth headphones -> "headphones"
// - AirPlay -> "airplayaudio"
@MainActor
public final class AudioRouteManager: ObservableObject {
    public static let shared = AudioRouteManager()
    
    @Published public private(set) var activeRouteIcon: String? = nil
    @Published public private(set) var deviceName: String = "Built-in"
    
    private var timer: Timer?
    
    public init() {
        updateRoute()
        // Check for audio route changes periodically
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
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
            activeRouteIcon = nil
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
        let name = (nameStatus == noErr && nameCF != nil) ? (nameCF!.takeRetainedValue() as String) : "Built-in"
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
        if lowerName.contains("airpods") {
            activeRouteIcon = "airpodspro"
        } else if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE || lowerName.contains("headphone") || lowerName.contains("buds") {
            activeRouteIcon = "headphones"
        } else if transport == kAudioDeviceTransportTypeAirPlay {
            activeRouteIcon = "airplayaudio"
        } else {
            // Built-in speakers (MacBook Air Speakers): No icon, clean centered controls!
            activeRouteIcon = nil
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
