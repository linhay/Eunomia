import Foundation
import ServiceManagement

// Ensures the target is configured for Swift compilation during migration.
enum SwiftMigrationMarker {}

final class NJLoginItemService: NSObject {
    class func isSMAppServiceAvailable() -> Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    class func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    class func registerLoginItem(_ error: NSErrorPointer) -> Bool {
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

    class func unregisterLoginItem(_ error: NSErrorPointer) -> Bool {
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

let NJEventMappingChanged = "com.yukkurigames.Eunomia.MappingChanged"
let NJEventMappingListChanged = "com.yukkurigames.Eunomia.MappingListChanged"
let NJEventSimulationStarted = "com.yukkurigames.Eunomia.EventSimulationStarted"
let NJEventSimulationStopped = "com.yukkurigames.Eunomia.EventSimulationStopped"

let NJMappingKey = "com.yukkurigames.Eunomia.Mapping"
let NJMappingIndexKey = "com.yukkurigames.Eunomia.MappingIndex"
let NJMappingListKey = "com.yukkurigames.Eunomia.MappingList"
