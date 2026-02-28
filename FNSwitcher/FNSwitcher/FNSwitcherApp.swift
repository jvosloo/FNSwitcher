import SwiftUI
import ServiceManagement

@main
struct FNSwitcherApp: App {
    @State private var configStore = ConfigStore()
    @State private var appMonitor: AppMonitor?

    var body: some Scene {
        MenuBarExtra("FNSwitcher", systemImage: configStore.isEnabled ? "keyboard.fill" : "keyboard") {
            MenuBarView(configStore: configStore)
                .onAppear {
                    if appMonitor == nil {
                        let monitor = AppMonitor(configStore: configStore)
                        monitor.start()
                        appMonitor = monitor
                    }
                }
        }
    }
}

struct RunningAppInfo: Identifiable, Sendable {
    let name: String
    let bundleId: String
    var id: String { bundleId }
}

struct MenuBarView: View {
    @Bindable var configStore: ConfigStore
    @State private var runningApps: [RunningAppInfo] = []

    var body: some View {
        Toggle("Enabled", isOn: $configStore.isEnabled)

        Divider()

        Text("Function Key Apps:").font(.headline)

        ForEach(configStore.entries, id: \.bundleId) { entry in
            Text(entry.name)
        }

        if configStore.entries.isEmpty {
            Text("None — use Add App to configure").foregroundStyle(.secondary)
        }

        Menu("Add App...") {
            ForEach(runningApps) { app in
                Button(app.name) {
                    configStore.addApp(name: app.name, bundleId: app.bundleId)
                }
            }
            if runningApps.isEmpty {
                Text("No apps detected")
            }
        }
        .onAppear { refreshRunningApps() }

        if !configStore.entries.isEmpty {
            Menu("Remove App...") {
                ForEach(configStore.entries, id: \.bundleId) { entry in
                    Button(entry.name) {
                        configStore.removeApp(bundleId: entry.bundleId)
                    }
                }
            }
        }

        Divider()

        Toggle("Launch at Login", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to toggle launch at login: \(error)")
                }
            }
        ))

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func refreshRunningApps() {
        let configuredBundleIds = Set(configStore.entries.map(\.bundleId))
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName,
                      let bundleId = app.bundleIdentifier,
                      !configuredBundleIds.contains(bundleId) else {
                    return nil
                }
                return RunningAppInfo(name: name, bundleId: bundleId)
            }
            .sorted { $0.name < $1.name }
    }
}
