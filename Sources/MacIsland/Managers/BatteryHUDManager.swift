import Foundation
import IOKit.ps
import SwiftUI

// MARK: - BatteryHUDState
public enum BatteryHUDState: Equatable, Sendable {
    case charging
    case charged
    case disconnected
    case lowBattery
    case criticalBattery
}

// MARK: - BatteryHUDManager
// Monitors real-time macOS power source status via IOKit Power Source APIs.
// Emits Dynamic Island style battery HUD notifications on:
// 1. Charger connected / charging -> Shows battery bolt icon + "80% · Charging" (Green)
// 2. Charged / Optimized 80% limit reached -> Shows battery full icon + "80% · Charged" (Emerald Green)
// 3. Charger disconnected -> Shows plug / battery icon + "80% · Disconnected" (Subtle White)
// 4. Low battery threshold (<= 20%) -> Shows low battery icon + "20% · Low Battery" (Orange)
// 5. Critical battery threshold (<= 10%) -> Shows critical battery icon + "10% · Very Low Battery" (Red)
@MainActor
public final class BatteryHUDManager: ObservableObject {
    public static let shared = BatteryHUDManager()
    
    @Published public private(set) var currentPercentage: Int = 100
    @Published public private(set) var isConnectedToAC: Bool = false
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isCharged: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    private var isInitialized = false
    
    // State tracking for edge detection
    private var previousConnectedToAC: Bool?
    private var previousIsCharging: Bool?
    private var previousIsCharged: Bool?
    private var previousPercentage: Int?
    private var warnedLowBattery = false
    private var warnedCriticalBattery = false
    
    // Polling safety timer (checks every 2 seconds as fallback to IOKit notifications)
    private var pollingTimer: Timer?
    
    public init() {
        startMonitoring()
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        pollingTimer?.invalidate()
    }
    
    // MARK: - IOKit Power Source Monitoring
    public func startMonitoring() {
        // Read initial state without firing notification
        updatePowerSourceState(triggerNotification: false)
        isInitialized = true
        
        // Register IOKit notification run loop source
        let context = Unmanaged.passUnretained(self).toOpaque()
        let source = IOPSNotificationCreateRunLoopSource({ info in
            guard let info = info else { return }
            let manager = Unmanaged<BatteryHUDManager>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in
                manager.updatePowerSourceState(triggerNotification: true)
            }
        }, context)?.takeRetainedValue()
        
        if let source = source {
            self.runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        // Background polling fallback every 2 seconds
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePowerSourceState(triggerNotification: true)
            }
        }
    }
    
    // MARK: - State Updates & Edge Detection
    public func updatePowerSourceState(triggerNotification: Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            // Only examine internal laptop batteries
            let type = desc[kIOPSTypeKey] as? String
            if type != kIOPSInternalBatteryType {
                continue
            }
            
            let currentCap = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
            let maxCap = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let percentage = maxCap > 0 ? Int((Double(currentCap) / Double(maxCap)) * 100.0) : currentCap
            
            let powerSourceState = desc[kIOPSPowerSourceStateKey] as? String
            let isAC = (powerSourceState == kIOPSACPowerValue)
            
            // Robust boolean parsing for CoreFoundation / IOKit dictionary values
            let isChargingNow = (desc[kIOPSIsChargingKey] as? NSNumber)?.boolValue
                ?? (desc[kIOPSIsChargingKey] as? Bool)
                ?? false
            let isChargedNow = (desc[kIOPSIsChargedKey] as? NSNumber)?.boolValue
                ?? (desc[kIOPSIsChargedKey] as? Bool)
                ?? false
            
            // Detect when on AC power and either charged full OR stopped at charging limit (e.g. 80% optimized limit)
            let isAtChargeLimit = isAC && !isChargingNow && (isChargedNow || percentage >= 80)
            
            self.currentPercentage = percentage
            self.isConnectedToAC = isAC
            self.isCharging = isChargingNow
            self.isCharged = isChargedNow || isAtChargeLimit
            
            if triggerNotification && isInitialized {
                evaluateTransitions(
                    percentage: percentage,
                    isAC: isAC,
                    isChargingNow: isChargingNow,
                    isAtChargeLimit: isAtChargeLimit
                )
            }
            
            // Update historical tracking
            self.previousConnectedToAC = isAC
            self.previousIsCharging = isChargingNow
            self.previousIsCharged = isAtChargeLimit
            self.previousPercentage = percentage
            
            // If battery charged back above 25%, reset low-battery warnings
            if percentage > 25 {
                self.warnedLowBattery = false
                self.warnedCriticalBattery = false
            } else if percentage > 15 {
                self.warnedCriticalBattery = false
            }
            
            break
        }
    }
    
    // MARK: - Transition Evaluation
    private func evaluateTransitions(
        percentage: Int,
        isAC: Bool,
        isChargingNow: Bool,
        isAtChargeLimit: Bool
    ) {
        guard let prevAC = previousConnectedToAC else { return }
        
        // 1. Plugged into AC Power
        if !prevAC && isAC {
            if isAtChargeLimit {
                showHUD(state: .charged, percentage: percentage)
            } else {
                showHUD(state: .charging, percentage: percentage)
            }
            return
        }
        
        // 2. Unplugged / Disconnected from AC Power
        if prevAC && !isAC {
            showHUD(state: .disconnected, percentage: percentage)
            return
        }
        
        // 3. While plugged in, transition from charging -> charged/limit reached
        if isAC {
            let prevCharging = previousIsCharging ?? true
            let prevLimit = previousIsCharged ?? false
            
            if prevCharging && !isChargingNow && isAtChargeLimit && !prevLimit {
                showHUD(state: .charged, percentage: percentage)
                return
            }
        }
        
        // 4. While discharging, low battery alerts
        if !isAC {
            if percentage <= 10 && !warnedCriticalBattery {
                warnedCriticalBattery = true
                warnedLowBattery = true
                showHUD(state: .criticalBattery, percentage: percentage)
                return
            } else if percentage <= 20 && !warnedLowBattery {
                warnedLowBattery = true
                showHUD(state: .lowBattery, percentage: percentage)
                return
            }
        }
    }
    
    // MARK: - HUD Display Formatting
    public func showHUD(state: BatteryHUDState, percentage: Int) {
        let icon: String
        let text: String
        let color: Color
        
        switch state {
        case .charging:
            icon = batteryIcon(for: percentage, isCharging: true)
            text = "Charging"
            color = Color.islandBatteryCharging
            
        case .charged:
            icon = batteryIcon(for: percentage, isCharging: false)
            text = (percentage >= 100) ? "Fully Charged" : "Charged"
            color = Color.islandBatteryFull
            
        case .disconnected:
            icon = "powerplug"
            text = "Disconnected"
            color = Color.islandBatteryDisconnected
            
        case .lowBattery:
            icon = "battery.25percent"
            text = "Low Battery"
            color = Color.islandBatteryLow
            
        case .criticalBattery:
            icon = "battery.0percent"
            text = "Very Low Battery"
            color = Color.islandBatteryCritical
        }
        
        SystemHUDManager.shared.triggerBatteryHUD(
            icon: icon,
            text: text,
            color: color,
            percentage: percentage,
            duration: 2.8
        )
    }
    
    /// Returns the standard SF Symbol for a given percentage and charging state
    public func batteryIcon(for percentage: Int, isCharging: Bool) -> String {
        if isCharging {
            if percentage >= 90 {
                return "battery.100percent.bolt"
            } else if percentage >= 65 {
                return "battery.75percent.bolt"
            } else if percentage >= 40 {
                return "battery.50percent.bolt"
            } else {
                return "battery.25percent.bolt"
            }
        } else {
            if percentage >= 90 {
                return "battery.100percent"
            } else if percentage >= 65 {
                return "battery.75percent"
            } else if percentage >= 40 {
                return "battery.50percent"
            } else if percentage >= 15 {
                return "battery.25percent"
            } else {
                return "battery.0percent"
            }
        }
    }
}
