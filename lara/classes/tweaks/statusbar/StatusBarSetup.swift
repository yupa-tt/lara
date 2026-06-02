//
//  StatusBarSetup.swift
//  lara
//

import Foundation

private let kOverridesPath = "/var/mobile/Library/SpringBoard/statusBarOverrides"

func setupStatusBar() {
    laramgr.shared.logmsg("[statusbar] setupStatusBar called. sbxready=\(laramgr.shared.sbxready)")

    StatusSetter17.setWrite({ ptr, len in
        guard let ptr = ptr else {
            laramgr.shared.logmsg("[statusbar] write: ptr is nil")
            return false
        }
        let data = Data(bytes: ptr, count: Int(len))
        laramgr.shared.logmsg("[statusbar] write: \(Int(len)) bytes to \(kOverridesPath)")
        do {
            try data.write(to: URL(fileURLWithPath: kOverridesPath), options: .atomic)
            laramgr.shared.logmsg("[statusbar] write: success")
            return true
        } catch {
            laramgr.shared.logmsg("[statusbar] write: failed - \(error)")
            return false
        }

    }, read: { ptr, len in
        guard let ptr = ptr else { return false }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: kOverridesPath)) else {
            laramgr.shared.logmsg("[statusbar] read: file not found")
            return false
        }
        let copyLen = min(data.count, Int(len))
        data.withUnsafeBytes { src in
            guard let base = src.baseAddress else { return }
            memcpy(ptr, base, copyLen)
        }
        return true

    }, existsBlock: {
        return FileManager.default.fileExists(atPath: kOverridesPath)
    })
}
