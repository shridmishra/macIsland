# Mac Island 🏝️

**Mac Island** is a native macOS Dynamic Island utility built with **Swift**, **SwiftUI**, and **AppKit**. It rests unobtrusively at the top of your Mac screen (seamlessly integrating with the camera notch on modern MacBooks or floating on external displays) and smoothly expands on hover or tap to reveal live media playback information and playback controls.

---

## Architecture for Web / TypeScript Developers

If you are coming from **React**, **Next.js**, and **TypeScript**, here is how the native macOS architecture maps directly to concepts you already know:

| macOS / Swift Concept | Web / TypeScript / React Equivalent | Purpose in Mac Island |
|---|---|---|
| `struct MediaItem` | `interface MediaItem` | Immutable data model representing track title, artist, album art, progress, and app name. |
| `class MediaManager: ObservableObject` | Zustand Store / React Context Hook | Holds `@Published` reactive state, dispatches playback actions, and runs timers. |
| `class WindowManager: ObservableObject` | Window State Store | Coordinates collapsed/expanded dimensions, hover debounce timer (hysteresis), and screen frames. |
| `protocol NowPlayingProvider` | TypeScript `interface NowPlayingProvider` | Abstract interface decoupling the UI from system-level media detection APIs. |
| `MediaRemoteProvider` | Service Implementation | Dynamically loads `MediaRemote.framework` via POSIX `dlopen` to detect system audio without permissions. |
| `IslandPanel: NSPanel` | Transparent Browser Window / Overlay | Borderless, non-activating floating window that stays on top across all Spaces and Fullscreen apps. |
| `IslandHostingView: NSHostingView` | React Root Container (`createRoot`) | Bridges SwiftUI views into AppKit and manages always-active cursor tracking (`NSTrackingArea`). |
| `Color.islandSurface`, etc. | CSS Variables / Design Tokens | Semantic tokens defined in `Color+Tokens.swift` to avoid hardcoding arbitrary colors in views. |

---

## Project Structure

```
macIsland/
├── Package.swift                             # Swift Package Manager manifest
├── scripts/
│   ├── run.sh                                # Development runner (swift build & launch)
│   └── build_app.sh                          # Packages and signs standalone MacIsland.app
├── MacIsland.app/                            # Compiled native macOS application bundle
└── Sources/
    └── MacIsland/
        ├── App/
        │   ├── MacIslandApp.swift            # @main SwiftUI app entry point
        │   ├── AppDelegate.swift             # NSApplicationDelegate, accessory policy, menu bar icon
        │   ├── IslandPanel.swift             # Borderless, transparent, non-activating NSPanel
        │   ├── IslandHostingView.swift       # NSHostingView subclass with NSTrackingArea & click-through
        │   └── IslandWindowController.swift  # Coordinates window frames, animation, and multi-monitor events
        ├── Models/
        │   ├── MediaItem.swift               # Media state model with time formatting & progress interpolation
        │   ├── IslandState.swift             # Enum: collapsed, expanded, hidden
        │   └── PlaybackState.swift           # Enum: playing, paused, stopped
        ├── Services/
        │   ├── NowPlayingProvider.swift      # Abstract protocol for media providers
        │   ├── MediaRemoteBridge.swift       # Dynamic loader for MediaRemote functions & commands
        │   └── MediaRemoteProvider.swift     # System-wide Now Playing provider
        ├── Managers/
        │   ├── MediaManager.swift            # Observable media coordinator and ticker
        │   └── WindowManager.swift           # Observable window geometry and hover debouncer
        ├── Views/
        │   ├── IslandContainerView.swift     # Root container with spring animations and blur material
        │   ├── CollapsedIslandView.swift     # Compact pill with mini artwork & animated waveform bars
        │   └── ExpandedIslandView.swift      # Interactive media card with artwork, progress & controls
        ├── Components/
        │   ├── ArtworkImageView.swift        # Rounded album artwork with graceful fallback
        │   ├── AudioWaveformIndicator.swift  # Animated equalizer bars for active playback
        │   ├── PlaybackProgressSlider.swift  # Horizontal progress line with timestamps
        │   └── MediaControlButtons.swift     # Previous, Play/Pause, Next controls
        ├── Extensions/
        │   ├── NSScreen+Notch.swift          # Hardware camera notch and safe-area calculation
        │   └── Color+Tokens.swift            # Semantic design tokens and dark translucent glass materials
        └── Resources/
            └── Info.plist                    # Bundle metadata (LSUIElement = true)
```

---

## macOS Native Engineering Highlights

### 1. Zero Permissions Universal Media Detection (`MediaRemote.framework`)
- Standard AppleScript queries require per-app Automation alerts ("Mac Island wants to control Music") and only support Apple Music and Spotify.
- Mac Island binds to `MediaRemote.framework` dynamically at runtime. It automatically detects playback from **Apple Music**, **Spotify**, **Safari**, **Brave**, **Google Chrome**, **Podcasts**, and any app that plays audio on macOS.
- **No Accessibility permissions** and **no Automation permissions** are needed!

### 2. High-Performance Windowing Architecture (`NSPanel`)
- Uses an `NSPanel` with `.nonactivatingPanel`: Clicking buttons on Mac Island does **not** steal focus or interrupt your typing in Xcode, VS Code, or terminal.
- Level set to `.statusBar` (Layer 25): Floats seamlessly at the menu bar/notch altitude.
- Collection behavior `[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`: Follows you smoothly across virtual desktops and works on top of full-screen applications.
- Hit testing: Transparent areas allow clicks to pass directly through to whatever window is behind the island.

### 3. Notch Adaptation & Multi-Display Support
- Modern MacBook Pros (14" and 16") feature a physical hardware camera notch.
- `NSScreen+Notch.swift` inspects `safeAreaInsets.top` and auxiliary menu bar dimensions:
  - On **notched screens**, the collapsed island snugly hugs the notch boundaries.
  - On **external monitors** and non-notched Macs, it rests as an elegant floating capsule.
- Listens to `NSApplication.didChangeScreenParametersNotification` to dynamically re-center if an external display is connected or disconnected.

### 4. Natural Hover Hysteresis (Debounce)
- Moving your cursor over the top pill triggers an instant, fluid macOS spring expansion (`Animation.spring(response: 0.36, dampingFraction: 0.82)`).
- When moving your cursor away, a **450ms debounce timer** prevents the island from accidentally snapping shut while your mouse is transitioning to or from the controls.
- You can also tap the collapsed island to expand it, or click the subtle chevron `^` to collapse it instantly.

---

## How to Run & Build

### Development Mode
To build and run directly in debug mode:
```bash
./scripts/run.sh
```

### Standalone Release App
To build and package into a self-contained `MacIsland.app`:
```bash
./scripts/build_app.sh
open MacIsland.app
```

### Quitting or Toggling via Menu Bar
Because Mac Island runs as an accessory utility (`LSUIElement = true`), it features a subtle status icon in the macOS menu bar. Click it to:
- Expand / Collapse Island (`Cmd + E`)
- Quit Mac Island (`Cmd + Q`)
