import Testing
@testable import FNSwitcher

@Suite("FnToggler Tests")
struct FnTogglerTests {
    @Test func canReadCurrentMode() throws {
        let mode = try FnToggler.currentMode()
        #expect(mode == .mediaKeys || mode == .functionKeys)
    }

    @Test func canToggleMode() throws {
        let original = try FnToggler.currentMode()
        let target: FnKeyMode = (original == .mediaKeys) ? .functionKeys : .mediaKeys

        try FnToggler.setMode(target)
        let changed = try FnToggler.currentMode()
        #expect(changed == target)

        // Restore original
        try FnToggler.setMode(original)
        let restored = try FnToggler.currentMode()
        #expect(restored == original)
    }
}
