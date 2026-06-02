//
//  StatusBarSetup.swift
//  lara
//

import Foundation

private let kOverridesPath = "/var/mobile/Library/SpringBoard/statusBarOverrides"

func setupStatusBar() {
    StatusSetter17.setWriteBlock({ ptr, len in
        guard let ptr = ptr else { return false }
        let data = Data(bytes: ptr, count: len)
        let result = laramgr.shared.lara_overwritefile(target: kOverridesPath, data: data)
        return result.ok

    }, readBlock: { ptr, len in
        guard let ptr = ptr else { return false }
        guard let data = laramgr.shared.vfsread(path: kOverridesPath, maxSize: len) else { return false }
        let copyLen = min(data.count, len)
        data.withUnsafeBytes { src in
            guard let base = src.baseAddress else { return }
            memcpy(ptr, base, copyLen)
        }
        return true

    }, existsBlock: {
        return FileManager.default.fileExists(atPath: kOverridesPath)
    })
}
