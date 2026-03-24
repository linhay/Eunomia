import AppKit
import Darwin
import ServiceManagement

extension NSRunningApplication {
    private static let processInformationCopyDictionary: (@convention(c) (UnsafePointer<ProcessSerialNumber>?, UInt32) -> Unmanaged<CFDictionary>?)? = {
        guard let symbol = dlsym(nil, "ProcessInformationCopyDictionary") else {
            return nil
        }
        return unsafeBitCast(
            symbol,
            to: (@convention(c) (UnsafePointer<ProcessSerialNumber>?, UInt32) -> Unmanaged<CFDictionary>?).self
        )
    }()
    func isLoginItem() -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }
    func addToLoginItems() {
        guard #available(macOS 13.0, *) else { return }
        if SMAppService.mainApp.status == .enabled { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
        }
    }
    func removeFromLoginItems() {
        guard #available(macOS 13.0, *) else { return }
        if SMAppService.mainApp.status != .enabled { return }
        do {
            try SMAppService.mainApp.unregister()
        } catch {
        }
    }
    func wasLaunchedAsLoginItemOrResume() -> Bool {
        guard let processInfoFn = Self.processInformationCopyDictionary else {
            return false
        }

        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        guard let processInfo = processInfoFn(&psn, UInt32(kProcessDictionaryIncludeAllInformationMask))?.takeRetainedValue() as? [String: Any],
              let parent = (processInfo["ParentPSN"] as? NSNumber)?.int64Value else {
            return false
        }

        var parentPsn = ProcessSerialNumber(
            highLongOfPSN: UInt32((parent >> 32) & 0x00000000FFFFFFFF),
            lowLongOfPSN: UInt32(parent & 0x00000000FFFFFFFF)
        )

        guard let parentInfo = processInfoFn(&parentPsn, UInt32(kProcessDictionaryIncludeAllInformationMask))?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        return (parentInfo["FileCreator"] as? String) == "lgnw"
    }
}
