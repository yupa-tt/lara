//
//  ShortcutManager.swift
//  lara
//

import Foundation

class ShortcutManager {
    static let webClipsDir = "/var/mobile/Library/WebClips"

    static func isAppClipEnabled() -> Bool {
        guard let clips = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: webClipsDir),
            includingPropertiesForKeys: nil
        ) else { return false }

        for clipURL in clips {
            let plistURL = clipURL.appendingPathComponent("Info.plist")
            guard let plistData = try? Data(contentsOf: plistURL),
                  let plist = try? PropertyListSerialization.propertyList(
                      from: plistData, format: nil) as? [String: Any],
                  let value = plist["IsAppClip"] as? Bool
            else { continue }
            return value
        }
        return false
    }

    static func setAppClip(_ enabled: Bool) throws {
        var succeeded = true

        for clipURL in try FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: webClipsDir),
            includingPropertiesForKeys: nil
        ) {
            let plistURL = clipURL.appendingPathComponent("Info.plist")
            guard let plistData = try? Data(contentsOf: plistURL),
                  var plist = try? PropertyListSerialization.propertyList(
                      from: plistData, format: nil) as? [String: Any]
            else { continue }

            // IsAppClip は元 plist に必ず存在するキー（書き換えのみ・追加ではない）
            // XMLフォーマットでは <false/> と <true/> が同じ7バイトのためサイズ変化なし
            // addEmptyData 不要・サイズチェック不要
            plist["IsAppClip"] = enabled

            // 元ファイルが XML フォーマットなので XML で書き直す
            // バイナリに変換するとサイズが変化する可能性があるため XML を維持する
            guard let newData = try? PropertyListSerialization.data(
                fromPropertyList: plist, format: .xml, options: 0)
            else { succeeded = false; continue }

            let result = laramgr.shared.lara_overwritefile(target: plistURL.path, data: newData)
            if !result.ok { succeeded = false }
        }

        guard succeeded else {
            throw "One or more WebClip writes failed"
        }
    }
}
