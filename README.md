# FNSwitcher

A lightweight macOS menu bar app that automatically switches between function keys and media keys based on the active application.

When a configured app (e.g., IntelliJ IDEA) is in the foreground, F1–F12 act as standard function keys. Switch to any other app and they revert to media keys (brightness, volume, etc.).

## Compatibility

- **Tested on:** macOS 26 Tahoe (Apple Silicon M4 Pro)
- **Deployment target:** macOS 14 Sonoma
- **Built with:** Swift 6, SwiftUI

The IOKit `HIDFKeyMode` API used for toggling has been available since at least macOS 10.x and is confirmed working on Tahoe. It should work on Sonoma (14) and Sequoia (15) as well, but these have not been tested. If Apple removes this IOKit interface in a future release, the app will need updating.

## Install

Download `FNSwitcher.zip` from the [latest release](https://github.com/jvosloo/FNSwitcher/releases), unzip, and drag `FNSwitcher.app` to `/Applications`.

On first launch, right-click the app → **Open** to bypass the Gatekeeper warning (the app is not notarized).

## Build from Source

Requires macOS 14+ and Xcode.

```bash
# Build and create .app bundle
./scripts/build-app.sh

# Or build and run directly
cd FNSwitcher
swift build -c release
.build/release/FNSwitcher
```

The app runs in the menu bar — no dock icon.

## Usage

1. Click the keyboard icon in the menu bar
2. Use **Add App...** to select which apps should use function keys
3. Switch between apps — fn key mode toggles automatically
4. **Launch at Login** keeps it running across restarts

## How It Works

FNSwitcher uses IOKit to toggle `HIDFKeyMode` on the IOHIDSystem, the same low-level mechanism macOS uses internally. This provides instant switching with no restart required and no special permissions (no Accessibility, no Input Monitoring).

App switches are detected via `NSWorkspace.didActivateApplicationNotification`. When the app quits, the original fn key mode is restored.

## License

MIT
