//
//  CarrierNameManager.swift
//  lara
//

import Foundation

class CarrierNameManager {
    static let overlayDir = "/var/mobile/Library/Carrier Bundles/Overlay/"

    static func getCurrentName() -> String? {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: overlayDir),
            includingPropertiesForKeys: nil
        ) else { return nil }

        for url in urls {
            guard let plistData = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(
                      from: plistData, format: nil) as? [String: Any],
                  let images = plist["StatusBarImages"] as? [[String: Any]],
                  let name = images.first?["StatusBarCarrierName"] as? String
            else { continue }
            return name
        }
        return nil
    }

    static func setCarrierName(_ newName: String) throws {
        var succeededOnce = false

        for url in try FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: overlayDir),
            includingPropertiesForKeys: nil
        ) {
            guard let plistData = try? Data(contentsOf: url),
                  var plist = try? PropertyListSerialization.propertyList(
                      from: plistData, format: nil) as? [String: Any]
            else { continue }

            let originalSize = plistData.count

            if var images = plist["StatusBarImages"] as? [[String: Any]] {
                for i in images.indices {
                    images[i]["StatusBarCarrierName"] = newName
                }
                plist["StatusBarImages"] = images
            }

            ["CarrierName", "CarrierBookmarks", "StockSymboli",
             "MyAccountURL", "HomeBundleIdentifier", "MyAccountURLTitle"]
                .forEach { plist.removeValue(forKey: $0) }

            // vfs_overwritefile は末尾をゼロ埋めするため、
            // バイナリ plist のパーサーが壊れたファイルと判断しないよう
            // Cowabunga と同様に addEmptyData でぴったりサイズに合わせる
            guard let newData = try? addEmptyData(matchingSize: originalSize, to: plist),
                  newData.count == originalSize
            else { continue }

            let result = laramgr.shared.lara_overwritefile(target: url.path, data: newData)
            if result.ok { succeededOnce = true }
        }

        guard succeededOnce else {
            throw "No carrier bundle found or all writes failed"
        }
    }

    static func reset() throws {
        try setCarrierName("")
    }
}
