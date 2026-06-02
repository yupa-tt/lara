//
//  StatusBarSetup.swift
//  lara
//

import Foundation

private let kOverridesPath = "/var/mobile/Library/SpringBoard/statusBarOverrides"

func setupStatusBar() {
    StatusSetter17.setWrite({ ptr, len in
        guard let ptr = ptr else { return false }
        let data = Data(bytes: ptr, count: Int(len))
        // sbxready なら通常の data.write で新規作成・上書きどちらも可能
        do {
            try data.write(to: URL(fileURLWithPath: kOverridesPath), options: .atomic)
            return true
        } catch {
            laramgr.shared.logmsg("statusbar write failed: \(error)")
            return false
        }

    }, read: { ptr, len in
        guard let ptr = ptr else { return false }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: kOverridesPath)) else { return false }
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
