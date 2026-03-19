import Foundation
import Darwin

extension ProcessInfo {
    @objc(isBeingDebugged)
    func isBeingDebuggedCompat() -> Bool {
        #if DEBUG
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(processIdentifier)]
        let mibCount = u_int(mib.count)
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size

        info.kp_proc.p_flag = 0

        let result = mib.withUnsafeMutableBufferPointer { mibPtr in
            sysctl(mibPtr.baseAddress, mibCount, &info, &size, nil, 0)
        }

        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
        #else
        return false
        #endif
    }
}
