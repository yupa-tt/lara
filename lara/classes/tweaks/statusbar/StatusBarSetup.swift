//
//  StatusBarSetup.swift
//  lara
//
//  StatusSetter17 が使うファイルI/O関数ポインタを
//  laramgr の sbxoverwrite / vfsread 経由で注入する。
//  アプリ起動後、sbxready になったタイミングで呼ぶ。
//

import Foundation

private let kOverridesPath = "/var/mobile/Library/SpringBoard/statusBarOverrides"

func setupStatusBar() {
    // 書き込み: laramgr.shared.lara_overwritefile (sbx -> vfs fallback)
    let writeFunc: StatusBarWriteFunc = { ptr, len in
        guard let ptr = ptr else { return false }
        let data = Data(bytes: ptr, count: len)
        let result = laramgr.shared.lara_overwritefile(target: kOverridesPath, data: data)
        return result.ok
    }

    // 読み込み: vfsread
    let readFunc: StatusBarReadFunc = { ptr, len in
        guard let ptr = ptr else { return false }
        guard let data = laramgr.shared.vfsread(path: kOverridesPath, maxSize: len) else { return false }
        let copyLen = min(data.count, len)
        data.withUnsafeBytes { src in
            memcpy(ptr, src.baseAddress, copyLen)
        }
        return true
    }

    // 存在確認
    let existsFunc: StatusBarExistsFunc = {
        return FileManager.default.fileExists(atPath: kOverridesPath)
    }

    StatusSetter17.setWriteFunc(writeFunc, readFunc: readFunc, existsFunc: existsFunc)
}
