import Foundation
import ServiceManagement

// Ensures the target is configured for Swift compilation during migration.
enum SwiftMigrationMarker {}

@objcMembers
final class NJLoginItemService: NSObject {
    @objc class func isSMAppServiceAvailable() -> Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    @objc class func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @objc class func registerLoginItem(_ error: NSErrorPointer) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                return true
            } catch let err as NSError {
                error?.pointee = err
                return false
            }
        }
        return false
    }

    @objc class func unregisterLoginItem(_ error: NSErrorPointer) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                return true
            } catch let err as NSError {
                error?.pointee = err
                return false
            }
        }
        return false
    }
}

let NJEventMappingChanged = "com.yukkurigames.Enjoyable.MappingChanged"
let NJEventMappingListChanged = "com.yukkurigames.Enjoyable.MappingListChanged"
let NJEventSimulationStarted = "com.yukkurigames.Enjoyable.EventSimulationStarted"
let NJEventSimulationStopped = "com.yukkurigames.Enjoyable.EventSimulationStopped"

let NJMappingKey = "com.yukkurigames.Enjoyable.Mapping"
let NJMappingIndexKey = "com.yukkurigames.Enjoyable.MappingIndex"
let NJMappingListKey = "com.yukkurigames.Enjoyable.MappingList"
