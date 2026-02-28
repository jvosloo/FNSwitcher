import Foundation
import Observation

struct AppEntry: Codable, Equatable, Sendable {
    let name: String
    let bundleId: String
}

@Observable
@MainActor
final class ConfigStore {
    private let defaults: UserDefaults
    private static let entriesKey = "fnSwitcherEntries"
    private static let enabledKey = "fnSwitcherEnabled"

    var entries: [AppEntry] {
        didSet { saveEntries() }
    }

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    init(suiteName: String? = nil) {
        let defaults: UserDefaults
        if let suiteName {
            defaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            defaults = .standard
        }
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.entriesKey),
           let saved = try? JSONDecoder().decode([AppEntry].self, from: data) {
            self.entries = saved
        } else {
            self.entries = []
        }

        if defaults.object(forKey: Self.enabledKey) != nil {
            self.isEnabled = defaults.bool(forKey: Self.enabledKey)
        } else {
            self.isEnabled = true
        }
    }

    func addApp(name: String, bundleId: String) {
        guard !entries.contains(where: { $0.bundleId == bundleId }) else { return }
        entries.append(AppEntry(name: name, bundleId: bundleId))
    }

    func removeApp(bundleId: String) {
        entries.removeAll { $0.bundleId == bundleId }
    }

    func matches(bundleId: String) -> Bool {
        entries.contains { $0.bundleId == bundleId }
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.entriesKey)
        }
    }
}
