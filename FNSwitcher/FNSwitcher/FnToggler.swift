import IOKit
import IOKit.hid
import Foundation

enum FnKeyMode: Int {
    case mediaKeys = 0
    case functionKeys = 1
}

enum FnTogglerError: Error, LocalizedError {
    case cannotOpenHIDSystem
    case cannotConnect
    case cannotReadMode
    case cannotSetMode

    var errorDescription: String? {
        switch self {
        case .cannotOpenHIDSystem: "Cannot open IOHIDSystem"
        case .cannotConnect: "Cannot connect to IOHIDSystem"
        case .cannotReadMode: "Cannot read current fn key mode"
        case .cannotSetMode: "Cannot set fn key mode"
        }
    }
}

struct FnToggler {
    private static let hidSystemPath = "IOService:/IOResources/IOHIDSystem"

    static func currentMode() throws -> FnKeyMode {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, hidSystemPath)
        guard entry != MACH_PORT_NULL else {
            throw FnTogglerError.cannotOpenHIDSystem
        }
        defer { IOObjectRelease(entry) }

        guard let params = IORegistryEntryCreateCFProperty(
            entry,
            "HIDParameters" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? [String: Any],
              let modeValue = params["HIDFKeyMode"] as? Int else {
            throw FnTogglerError.cannotReadMode
        }

        return FnKeyMode(rawValue: modeValue) ?? .mediaKeys
    }

    static func setMode(_ mode: FnKeyMode) throws {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, hidSystemPath)
        guard entry != MACH_PORT_NULL else {
            throw FnTogglerError.cannotOpenHIDSystem
        }
        defer { IOObjectRelease(entry) }

        var connect: io_connect_t = 0
        let openResult = IOServiceOpen(entry, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        guard openResult == KERN_SUCCESS else {
            throw FnTogglerError.cannotConnect
        }
        defer { IOServiceClose(connect) }

        let value = mode.rawValue as CFNumber
        let setResult = IOHIDSetCFTypeParameter(connect, "HIDFKeyMode" as CFString, value)
        guard setResult == KERN_SUCCESS else {
            throw FnTogglerError.cannotSetMode
        }

        // Sync the system preference so System Settings stays consistent
        CFPreferencesSetValue(
            "fnState" as CFString,
            (mode == .functionKeys) as CFBoolean,
            "com.apple.keyboard" as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesCurrentHost
        )
        CFPreferencesAppSynchronize("com.apple.keyboard" as CFString)

        // Notify the system that fn state changed
        let center = CFNotificationCenterGetDistributedCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("com.apple.keyboard.fnstatedidchange" as CFString),
            nil,
            nil,
            true
        )
    }
}
