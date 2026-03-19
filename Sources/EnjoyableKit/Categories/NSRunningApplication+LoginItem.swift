import AppKit
import CoreServices
import Darwin
import ServiceManagement

extension NSRunningApplication {
    private static let resolveFlags: UInt32 =
        UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)

    private static let processInformationCopyDictionary: (@convention(c) (UnsafePointer<ProcessSerialNumber>?, UInt32) -> Unmanaged<CFDictionary>?)? = {
        guard let symbol = dlsym(nil, "ProcessInformationCopyDictionary") else {
            return nil
        }
        return unsafeBitCast(
            symbol,
            to: (@convention(c) (UnsafePointer<ProcessSerialNumber>?, UInt32) -> Unmanaged<CFDictionary>?).self
        )
    }()

    @objc(isLoginItem)
    func isLoginItem() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        guard
            let myURL = bundleURL as NSURL?,
            let listType = Optional(kLSSharedFileListSessionLoginItems.takeUnretainedValue()),
            let loginItems = LSSharedFileListCreate(nil, listType, nil)?.takeRetainedValue()
        else {
            return false
        }
        var seed: UInt32 = 0
        guard let snapshot = LSSharedFileListCopySnapshot(loginItems, &seed)?.takeRetainedValue() as? [AnyObject] else {
            return false
        }

        for obj in snapshot {
            let item = unsafeBitCast(obj, to: LSSharedFileListItem.self)
            var itemURL: Unmanaged<CFURL>?
            if LSSharedFileListItemResolve(item, Self.resolveFlags, &itemURL, nil) == noErr,
               let resolved = itemURL?.takeRetainedValue(),
               CFEqual(resolved, myURL) {
                return true
            }
        }

        return false
    }

    @objc(addToLoginItems)
    func addToLoginItems() {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                return
            }

            do {
                try SMAppService.mainApp.register()
                return
            } catch {
            }
        }

        guard !isLoginItem() else {
            return
        }

        guard
            let myURL = bundleURL as NSURL?,
            let listType = Optional(kLSSharedFileListSessionLoginItems.takeUnretainedValue()),
            let loginItems = LSSharedFileListCreate(nil, listType, nil)?.takeRetainedValue()
        else {
            return
        }

        LSSharedFileListInsertItemURL(
            loginItems,
            kLSSharedFileListItemBeforeFirst.takeUnretainedValue(),
            nil,
            nil,
            myURL,
            nil,
            nil
        )
    }

    @objc(removeFromLoginItems)
    func removeFromLoginItems() {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status != .enabled {
                return
            }

            do {
                try SMAppService.mainApp.unregister()
                return
            } catch {
            }
        }

        guard
            let myURL = bundleURL as NSURL?,
            let listType = Optional(kLSSharedFileListSessionLoginItems.takeUnretainedValue()),
            let loginItems = LSSharedFileListCreate(nil, listType, nil)?.takeRetainedValue()
        else {
            return
        }
        var seed: UInt32 = 0
        guard let snapshot = LSSharedFileListCopySnapshot(loginItems, &seed)?.takeRetainedValue() as? [AnyObject] else {
            return
        }

        for obj in snapshot {
            let item = unsafeBitCast(obj, to: LSSharedFileListItem.self)
            var itemURL: Unmanaged<CFURL>?
            if LSSharedFileListItemResolve(item, Self.resolveFlags, &itemURL, nil) == noErr,
               let resolved = itemURL?.takeRetainedValue(),
               CFEqual(resolved, myURL) {
                LSSharedFileListItemRemove(loginItems, item)
            }
        }
    }

    @objc(wasLaunchedAsLoginItemOrResume)
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
