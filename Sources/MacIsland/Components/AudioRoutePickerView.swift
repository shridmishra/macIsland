import SwiftUI
import AppKit

// MARK: - AudioRoutePickerView
// Minimal, frameless Audio Output Destination & Route Picker matching the Dynamic Island Now Playing aesthetic:
// - Zero unnecessary text: Pure minimal back chevron
// - Hyper-restrained color: Pure monochrome Apple aesthetic with waveform connectivity indicator
// - Physical cursor feedback: Pointing hand cursor (NSCursor.pointingHand) on all interactive elements
// - Subtle hover animations: Fluid micro-scaling and soft background transitions
// - 1-Click switching between MacBook speakers, AirPods, and Wired AUX
// - Apple Control Center-inspired AirPods Noise Control segmented pill
// - Clean Bluetooth audio connectivity with waveform indicators
@MainActor
public struct AudioRoutePickerView: View {
    @ObservedObject private var routeManager = AudioRouteManager.shared
    @ObservedObject private var windowManager = WindowManager.shared
    @ObservedObject private var mediaManager = MediaManager.shared
    
    @State private var hoveredBack = false
    @State private var hoveredMode: AirPodsListeningMode? = nil
    @State private var hoveredDeviceID: String? = nil
    @State private var hoveredBluetoothID: String? = nil
    @State private var hoveredConnectID: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // 1. Header Bar: [ < Back Icon ] [ Spacer ] [ Active Route Icon ]
            headerBar
            
            // 2. Connected Audio Output Destinations
            VStack(spacing: 2) {
                let devices = routeManager.availableDevices
                if devices.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.islandTextTertiary)
                        
                        Text("Searching audio devices...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.islandTextTertiary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                } else {
                    ForEach(devices) { device in
                        deviceRow(device: device)
                    }
                }
            }
            
            // 3. AirPods Noise Control (when AirPods are active)
            if routeManager.hasAirPodsActive {
                airPodsNoiseControlBar
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
            
            // 4. Bluetooth Audio Section ("Only Bluetooth connectivity that thing")
            if !routeManager.pairedBluetoothDevices.isEmpty {
                bluetoothSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(IslandAnimation.notchSpring, value: routeManager.currentDeviceID)
        .animation(IslandAnimation.notchSpring, value: routeManager.currentListeningMode)
        .animation(IslandAnimation.notchSpring, value: routeManager.hasAirPodsActive)
    }
    
    // MARK: - Header Bar (Minimal, Icon-Only, Zero Unnecessary Text)
    
    private var headerBar: some View {
        HStack(alignment: .center) {
            // Back Button (Icon Only with subtle hover glow & pointer cursor)
            Button {
                windowManager.closeAudioRoutePicker()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(hoveredBack ? 1.0 : 0.55))
                    .scaleEffect(hoveredBack ? 1.12 : 1.0)
                    .frame(width: 28, height: 22, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredBack = isHovered
                }
                if isHovered {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            
            Spacer()
        }
        .frame(height: 22)
    }
    
    // MARK: - Device Row (Pure Frameless, Subtle Hover Animation & Pointer Cursor)
    
    private func deviceRow(device: AudioOutputDevice) -> some View {
        let isHovered = (hoveredDeviceID == device.id)
        
        return Button {
            routeManager.selectOutputDevice(device)
        } label: {
            HStack(spacing: 12) {
                // Device Icon directly rendered (Neutral monochrome, matching Bluetooth row)
                Image(systemName: device.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(device.isDefault ? Color.islandTextPrimary : Color.white.opacity(0.65))
                    .frame(width: 22, height: 22)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                
                // Device Name (Consistent 12pt semibold across all rows, no "Active Output" text)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                        .lineLimit(1)
                    
                    if !device.subtitle.isEmpty && device.subtitle != "Active Output" && device.subtitle != "Built-in Speaker" && device.subtitle != "Ready" {
                        Text(device.subtitle)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.white.opacity(device.isDefault ? 0.65 : 0.45))
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Active Connectivity Indicator (Apple Dynamic Waveform / Equalizer instead of tick)
                if device.isDefault {
                    connectivityIndicator
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.07 : 0.0))
            )
            .scaleEffect(isHovered ? 1.012 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered in
            hoveredDeviceID = isHovered ? device.id : nil
            if isHovered {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
    
    // MARK: - AirPods Noise Control Bar (Sleek Apple Segmented Pill)
    
    private var airPodsNoiseControlBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Noise Control")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.islandTextSecondary)
                .padding(.leading, 8)
            
            HStack(spacing: 3) {
                ForEach(AirPodsListeningMode.allCases) { mode in
                    let isSelected = (routeManager.currentListeningMode == mode)
                    let isHovered = (hoveredMode == mode)
                    
                    Button {
                        routeManager.setListeningMode(mode)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            
                            Text(mode.title)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(isSelected ? Color.black : (isHovered ? Color.islandTextPrimary : Color.islandTextSecondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white : (isHovered ? Color.white.opacity(0.12) : Color.clear))
                        )
                        .scaleEffect(isHovered ? 1.03 : 1.0)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
                    .onHover { isHovered in
                        hoveredMode = isHovered ? mode : nil
                        if isHovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
    
    // MARK: - Bluetooth Section (Clean List with Zero Carding)
    
    private var bluetoothSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bluetooth")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.islandTextSecondary)
                .padding(.leading, 8)
                .padding(.top, 2)
            
            VStack(spacing: 2) {
                let paired = routeManager.pairedBluetoothDevices.prefix(2)
                ForEach(paired) { dev in
                    bluetoothRow(device: dev)
                }
            }
        }
    }
    
    private func bluetoothRow(device: BluetoothAudioDevice) -> some View {
        let isHovered = (hoveredBluetoothID == device.id)
        let isConnectHovered = (hoveredConnectID == device.id)
        
        return HStack(spacing: 12) {
            // Icon (Neutral monochrome)
            Image(systemName: device.iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(device.isConnected ? 0.90 : 0.55))
                .frame(width: 22, height: 22)
            
            // Name & Status (Neutral monochrome)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.islandTextPrimary)
                    .lineLimit(1)
                
                if device.isConnected {
                    let batteryText = device.batteryLevel != nil ? " • \(device.batteryLevel!)%" : ""
                    Text("Connected\(batteryText)")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.70))
                } else if device.isConnecting {
                    Text("Connecting...")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.islandTextSecondary)
                } else {
                    Text("Paired")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.islandTextSecondary)
                }
            }
            
            Spacer()
            
            // Action
            if device.isConnected {
                connectivityIndicator
                    .padding(.trailing, 4)
            } else if device.isConnecting {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            } else {
                Button {
                    routeManager.connectBluetoothDevice(device)
                } label: {
                    Text("Connect")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.islandTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(isConnectHovered ? 0.20 : 0.12))
                        )
                        .scaleEffect(isConnectHovered ? 1.04 : 1.0)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.12), value: isConnectHovered)
                .onHover { isHovered in
                    hoveredConnectID = isHovered ? device.id : nil
                    if isHovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.06 : 0.0))
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            hoveredBluetoothID = hovering ? device.id : nil
        }
    }
    
    // MARK: - Connectivity Indicator (Apple Dynamic Waveform / Equalizer)
    
    @ViewBuilder
    private var connectivityIndicator: some View {
        if mediaManager.playbackState.isPlaying {
            AudioWaveformIndicator(
                isPlaying: true,
                colors: [Color.islandTextPrimary, Color.islandTextPrimary],
                barCount: 4
            )
            .frame(height: 12)
        } else {
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.islandTextPrimary.opacity(0.85))
        }
    }
}
