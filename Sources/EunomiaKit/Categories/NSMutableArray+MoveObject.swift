import Foundation

extension NSMutableArray {
    func moveObject(atIndex src: UInt, toIndex dst: UInt) {
        let srcIndex = Int(src)
        let dstIndex = Int(dst)
        let obj = self[srcIndex]
        removeObject(at: srcIndex)
        insert(obj, at: dstIndex)
    }
    func moveFirstwards(_ object: Any, upTo minIndex: UInt) -> Bool {
        let idx = index(of: object)
        if idx != NSNotFound && idx > Int(minIndex) {
            exchangeObject(at: idx, withObjectAt: idx - 1)
            return true
        }
        return false
    }
    func moveLastwards(_ object: Any, upTo maxIndex: UInt) -> Bool {
        let cappedMax = Swift.min(Swift.max(count - 1, 0), Int(maxIndex))
        let idx = index(of: object)
        if idx != NSNotFound && idx < cappedMax {
            exchangeObject(at: idx, withObjectAt: idx + 1)
            return true
        }
        return false
    }
    func moveFirstwards(_ object: Any) -> Bool {
        moveFirstwards(object, upTo: 0)
    }
    func moveLastwards(_ object: Any) -> Bool {
        moveLastwards(object, upTo: UInt(NSNotFound))
    }
}
