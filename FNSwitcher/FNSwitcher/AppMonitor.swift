import AppKit
import os

@MainActor
final class AppMonitor {
    private let configStore: ConfigStore
    private let logger = Logger(subsystem: "com.fnswitcher", category: "AppMonitor")
    private var originalMode: FnKeyMode?
    private var workspaceObserver: (any NSObjectProtocol)?
    private var terminationObserver: (any NSObjectProtocol)?

    init(configStore: ConfigStore) {
        self.configStore = configStore
    }

    func start() {
        // Save the original mode so we can restore on quit
        do {
            originalMode = try FnToggler.currentMode()
            logger.info("Saved original fn key mode: \(self.originalMode!.rawValue)")
        } catch {
            logger.error("Failed to read initial fn key mode: \(error.localizedDescription)")
        }

        // Listen for app switches
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else {
                return
            }
            MainActor.assumeIsolated {
                self.handleAppSwitch(bundleId: bundleId)
            }
        }

        // Register for app termination to restore original mode
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.restoreOriginalMode()
            }
        }

        // Also set the correct mode for the current frontmost app right now
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier {
            handleAppSwitch(bundleId: bundleId)
        }
    }

    func stop() {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
            self.terminationObserver = nil
        }
        restoreOriginalMode()
    }

    private func restoreOriginalMode() {
        if let originalMode {
            do {
                try FnToggler.setMode(originalMode)
                logger.info("Restored original fn key mode: \(originalMode.rawValue)")
            } catch {
                logger.error("Failed to restore fn key mode: \(error.localizedDescription)")
            }
        }
    }

    private func handleAppSwitch(bundleId: String) {
        guard configStore.isEnabled else { return }

        let desiredMode: FnKeyMode = configStore.matches(bundleId: bundleId) ? .functionKeys : .mediaKeys

        do {
            let currentMode = try FnToggler.currentMode()
            if currentMode != desiredMode {
                try FnToggler.setMode(desiredMode)
                logger.info("Switched to \(desiredMode == .functionKeys ? "function keys" : "media keys") for \(bundleId)")
            }
        } catch {
            logger.error("Failed to toggle fn key mode for \(bundleId): \(error.localizedDescription)")
        }
    }
}
