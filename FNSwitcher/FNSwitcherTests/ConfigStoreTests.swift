import Foundation
import Testing
@testable import FNSwitcher

@Suite("ConfigStore Tests")
struct ConfigStoreTests {
    @Test @MainActor func startsEmpty() {
        let store = ConfigStore(suiteName: "com.fnswitcher.test.\(UUID().uuidString)")
        #expect(store.entries.isEmpty)
    }

    @Test @MainActor func addAndRemoveApp() {
        let store = ConfigStore(suiteName: "com.fnswitcher.test.\(UUID().uuidString)")
        store.addApp(name: "Xcode", bundleId: "com.apple.dt.Xcode")
        #expect(store.entries.contains(where: { $0.bundleId == "com.apple.dt.Xcode" }))
        #expect(store.entries.first?.name == "Xcode")

        store.removeApp(bundleId: "com.apple.dt.Xcode")
        #expect(!store.entries.contains(where: { $0.bundleId == "com.apple.dt.Xcode" }))
    }

    @Test @MainActor func matchesBundleId() {
        let store = ConfigStore(suiteName: "com.fnswitcher.test.\(UUID().uuidString)")
        store.addApp(name: "IntelliJ IDEA", bundleId: "com.jetbrains.intellij")
        #expect(store.matches(bundleId: "com.jetbrains.intellij"))
        #expect(!store.matches(bundleId: "com.jetbrains.WebStorm"))
        #expect(!store.matches(bundleId: "com.apple.Safari"))
    }

    @Test @MainActor func noDuplicates() {
        let store = ConfigStore(suiteName: "com.fnswitcher.test.\(UUID().uuidString)")
        store.addApp(name: "IntelliJ IDEA", bundleId: "com.jetbrains.intellij")
        store.addApp(name: "IntelliJ IDEA", bundleId: "com.jetbrains.intellij")
        #expect(store.entries.count == 1)
    }

    @Test @MainActor func enabledFlag() {
        let store = ConfigStore(suiteName: "com.fnswitcher.test.\(UUID().uuidString)")
        #expect(store.isEnabled == true)
        store.isEnabled = false
        #expect(store.isEnabled == false)
    }
}
