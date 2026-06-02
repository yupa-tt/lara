//
//  StatusBarSetup.swift
//  lara
//

import Foundation

private let kOverridesPath = "/var/mobile/Library/SpringBoard/statusBarOverrides"

func setupStatusBar() {
    laramgr.shared.logmsg("setupStatusBar: sbxready=\(laramgr.shared.sbxready) vfsready=\(laramgr.shared.vfsready)")

    StatusSetter17.setWrite({ ptr, len in
        guard let ptr = ptr else { return false }
        let data = Data(bytes: ptr, count: Int(len))
        laramgr.shared.logmsg("statusbar write: \(Int(len)) bytes -> \(kOverridesPath)")
        let result = laramgr.shared.lara_overwritefile(target: kOverridesPath, data: data)
        laramgr.shared.logmsg("statusbar write result: \(result.ok) \(result.message)")
        return result.ok

    }, read: { ptr, len in
        guard let ptr = ptr else { return false }
        guard let data = laramgr.shared.vfsread(path: kOverridesPath, maxSize: Int(len)) else { return false }
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
