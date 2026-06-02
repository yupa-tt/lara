//
//  StatusBarView.swift
//  lara
//
//  Ported from Cowabunga (MIT License)
//  Changes:
//    - isMDCMode() チェックを削除（lara は常に UIStatusBarServer 直接呼び出し）
//    - MDCモード用 Apply ボタン・statusBarOverridesEditing ファイル操作を削除
//    - restartFrontboard() を mgr.respring() に置き換え
//    - UIApplication.shared.alert を lara の alert パターンに置き換え
//    - Cowabunga と同じ onChange ごとに即時反映する仕組みをそのまま維持
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var mgr: laramgr

    let fm = FileManager.default

    @State private var cellularServiceEnabled: Bool = StatusManager.sharedInstance().isCellularServiceOverridden()
    @State private var cellularServiceValue: Bool = StatusManager.sharedInstance().getCellularServiceOverride()

    @State private var carrierText: String = StatusManager.sharedInstance().getCarrierOverride()
    @State private var carrierTextEnabled: Bool = StatusManager.sharedInstance().isCarrierOverridden()

    @State private var primaryServiceBadgeText: String = StatusManager.sharedInstance().getPrimaryServiceBadgeOverride()
    @State private var primaryServiceBadgeTextEnabled: Bool = StatusManager.sharedInstance().isPrimaryServiceBadgeOverridden()

    @State private var secondCellularServiceEnabled: Bool = StatusManager.sharedInstance().isSecondaryCellularServiceOverridden()
    @State private var secondaryCellularServiceValue: Bool = StatusManager.sharedInstance().getSecondaryCellularServiceOverride()

    @State private var secondaryCarrierText: String = StatusManager.sharedInstance().getSecondaryCarrierOverride()
    @State private var secondaryCarrierTextEnabled: Bool = StatusManager.sharedInstance().isSecondaryCarrierOverridden()

    @State private var secondaryServiceBadgeText: String = StatusManager.sharedInstance().getSecondaryServiceBadgeOverride()
    @State private var secondaryServiceBadgeTextEnabled: Bool = StatusManager.sharedInstance().isSecondaryServiceBadgeOverridden()

    @State private var dateText: String = StatusManager.sharedInstance().getDateOverride()
    @State private var dateTextEnabled: Bool = StatusManager.sharedInstance().isDateOverridden()

    @State private var timeText: String = StatusManager.sharedInstance().getTimeOverride()
    @State private var timeTextEnabled: Bool = StatusManager.sharedInstance().isTimeOverridden()

    @State private var batteryDetailText: String = StatusManager.sharedInstance().getBatteryDetailOverride()
    @State private var batteryDetailEnabled: Bool = StatusManager.sharedInstance().isBatteryDetailOverridden()

    @State private var crumbText: String = StatusManager.sharedInstance().getCrumbOverride()
    @State private var crumbTextEnabled: Bool = StatusManager.sharedInstance().isCrumbOverridden()

    @State private var dataNetworkType: Int = Int(StatusManager.sharedInstance().getDataNetworkTypeOverride())
    @State private var dataNetworkTypeEnabled: Bool = StatusManager.sharedInstance().isDataNetworkTypeOverridden()

    @State private var secondaryDataNetworkType: Int = Int(StatusManager.sharedInstance().getSecondaryDataNetworkTypeOverride())
    @State private var secondaryDataNetworkTypeEnabled: Bool = StatusManager.sharedInstance().isSecondaryDataNetworkTypeOverridden()

    @State private var batteryCapacity: Double = Double(StatusManager.sharedInstance().getBatteryCapacityOverride())
    @State private var batteryCapacityEnabled: Bool = StatusManager.sharedInstance().isBatteryCapacityOverridden()

    @State private var wiFiStrengthBars: Double = Double(StatusManager.sharedInstance().getWiFiSignalStrengthBarsOverride())
    @State private var wiFiStrengthBarsEnabled: Bool = StatusManager.sharedInstance().isWiFiSignalStrengthBarsOverridden()

    @State private var gsmStrengthBars: Double = Double(StatusManager.sharedInstance().getGsmSignalStrengthBarsOverride())
    @State private var gsmStrengthBarsEnabled: Bool = StatusManager.sharedInstance().isGsmSignalStrengthBarsOverridden()

    @State private var secondaryGsmStrengthBars: Double = Double(StatusManager.sharedInstance().getSecondaryGsmSignalStrengthBarsOverride())
    @State private var secondaryGsmStrengthBarsEnabled: Bool = StatusManager.sharedInstance().isSecondaryGsmSignalStrengthBarsOverridden()

    @State private var displayingRawWiFiStrength: Bool = StatusManager.sharedInstance().isDisplayingRawWiFiSignal()
    @State private var displayingRawGSMStrength: Bool = StatusManager.sharedInstance().isDisplayingRawGSMSignal()

    @State private var clockHidden: Bool = StatusManager.sharedInstance().isClockHidden()
    @State private var DNDHidden: Bool = StatusManager.sharedInstance().isDNDHidden()
    @State private var airplaneHidden: Bool = StatusManager.sharedInstance().isAirplaneHidden()
    @State private var cellHidden: Bool = StatusManager.sharedInstance().isCellHidden()
    @State private var wiFiHidden: Bool = StatusManager.sharedInstance().isWiFiHidden()
    @State private var batteryHidden: Bool = StatusManager.sharedInstance().isBatteryHidden()
    @State private var bluetoothHidden: Bool = StatusManager.sharedInstance().isBluetoothHidden()
    @State private var alarmHidden: Bool = StatusManager.sharedInstance().isAlarmHidden()
    @State private var locationHidden: Bool = StatusManager.sharedInstance().isLocationHidden()
    @State private var rotationHidden: Bool = StatusManager.sharedInstance().isRotationHidden()
    @State private var airPlayHidden: Bool = StatusManager.sharedInstance().isAirPlayHidden()
    @State private var carPlayHidden: Bool = StatusManager.sharedInstance().isCarPlayHidden()
    @State private var VPNHidden: Bool = StatusManager.sharedInstance().isVPNHidden()

    private var NetworkTypes: [String] = [
        "GPRS",   // 0
        "EDGE",   // 1
        "3G",     // 2
        "4G",     // 3
        "LTE",    // 4
        "WiFi",   // 5
        "Personal Hotspot", // 6
        "1x",     // 7
        "5Ge",    // 8
        "LTE-A",  // 9
        "LTE+",   // 10
        "5G",     // 11
        "5G+",    // 12
        "5GUW",   // 13
        "5GUC",   // 14
    ]

    var body: some View {
        List {
            Section(footer: Text("Changes apply immediately. Respring to reset.")) {
                Button("Respring") {
                    mgr.respring()
                }
            }

            // MARK: - Breadcrumb / Battery Detail / Time / Date
            Section(footer: Text("When set to blank on notched devices, this will display the carrier name.")) {
                Toggle("Change Breadcrumb Text", isOn: $crumbTextEnabled).onChange(of: crumbTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setCrumb(crumbText) }
                    else  { StatusManager.sharedInstance().unsetCrumb() }
                }
                TextField("Breadcrumb Text", text: $crumbText).onChange(of: crumbText) { nv in
                    var safeNv = nv
                    while (safeNv + " >").utf8CString.count > 256 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    crumbText = safeNv
                    if crumbTextEnabled { StatusManager.sharedInstance().setCrumb(safeNv) }
                }

                Toggle("Change Battery Detail Text", isOn: $batteryDetailEnabled).onChange(of: batteryDetailEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setBatteryDetail(batteryDetailText) }
                    else  { StatusManager.sharedInstance().unsetBatteryDetail() }
                }
                TextField("Battery Detail Text", text: $batteryDetailText).onChange(of: batteryDetailText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 150 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    batteryDetailText = safeNv
                    if batteryDetailEnabled { StatusManager.sharedInstance().setBatteryDetail(safeNv) }
                }

                if UIDevice.current.userInterfaceIdiom == .pad {
                    Toggle("Change Status Bar Date Text", isOn: $dateTextEnabled).onChange(of: dateTextEnabled) { nv in
                        if nv { StatusManager.sharedInstance().setDate(dateText) }
                        else  { StatusManager.sharedInstance().unsetDate() }
                    }
                    TextField("Status Bar Date Text", text: $dateText).onChange(of: dateText) { nv in
                        var safeNv = nv
                        while safeNv.utf8CString.count > 256 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                        dateText = safeNv
                        if dateTextEnabled { StatusManager.sharedInstance().setDate(safeNv) }
                    }
                }

                Toggle("Change Status Bar Time Text", isOn: $timeTextEnabled).onChange(of: timeTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setTime(timeText) }
                    else  { StatusManager.sharedInstance().unsetTime() }
                }
                TextField("Status Bar Time Text", text: $timeText).onChange(of: timeText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 64 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    timeText = safeNv
                    if timeTextEnabled { StatusManager.sharedInstance().setTime(safeNv) }
                }
            }

            // MARK: - Primary Carrier
            Section(header: Text("Primary Carrier")) {
                Toggle("Change Service Status", isOn: $cellularServiceEnabled).onChange(of: cellularServiceEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setCellularService(cellularServiceValue) }
                    else  { StatusManager.sharedInstance().unsetCellularService() }
                }
                if cellularServiceEnabled {
                    Toggle("Cellular Service Enabled", isOn: $cellularServiceValue).onChange(of: cellularServiceValue) { nv in
                        if cellularServiceEnabled { StatusManager.sharedInstance().setCellularService(nv) }
                    }
                }

                Toggle("Change Primary Carrier Text", isOn: $carrierTextEnabled).onChange(of: carrierTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setCarrier(carrierText) }
                    else  { StatusManager.sharedInstance().unsetCarrier() }
                }
                TextField("Primary Carrier Text", text: $carrierText).onChange(of: carrierText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 100 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    carrierText = safeNv
                    if carrierTextEnabled { StatusManager.sharedInstance().setCarrier(safeNv) }
                }

                Toggle("Change Primary Service Badge Text", isOn: $primaryServiceBadgeTextEnabled).onChange(of: primaryServiceBadgeTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setPrimaryServiceBadge(primaryServiceBadgeText) }
                    else  { StatusManager.sharedInstance().unsetPrimaryServiceBadge() }
                }
                TextField("Primary Service Badge Text", text: $primaryServiceBadgeText).onChange(of: primaryServiceBadgeText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 100 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    primaryServiceBadgeText = safeNv
                    if primaryServiceBadgeTextEnabled { StatusManager.sharedInstance().setPrimaryServiceBadge(safeNv) }
                }

                Toggle("Change Data Network Type", isOn: $dataNetworkTypeEnabled).onChange(of: dataNetworkTypeEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setDataNetworkType(Int32(dataNetworkType)) }
                    else  { StatusManager.sharedInstance().unsetDataNetworkType() }
                }
                HStack {
                    Text("Data Network Type")
                    Spacer()
                    Menu {
                        ForEach(Array(NetworkTypes.enumerated()), id: \.offset) { i, net in
                            Button(action: {
                                dataNetworkType = i
                                if dataNetworkTypeEnabled { StatusManager.sharedInstance().setDataNetworkType(Int32(i)) }
                            }) { Text(net) }
                        }
                    } label: {
                        Text(NetworkTypes[dataNetworkType])
                    }
                }
            }

            // MARK: - Secondary Carrier
            Section(header: Text("Secondary Carrier")) {
                Toggle("Change Secondary Service Status", isOn: $secondCellularServiceEnabled).onChange(of: secondCellularServiceEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setSecondaryCellularService(secondaryCellularServiceValue) }
                    else  { StatusManager.sharedInstance().unsetSecondaryCellularService() }
                }
                if secondCellularServiceEnabled {
                    Toggle("Secondary Cellular Service Enabled", isOn: $secondaryCellularServiceValue).onChange(of: secondaryCellularServiceValue) { nv in
                        if secondCellularServiceEnabled { StatusManager.sharedInstance().setSecondaryCellularService(nv) }
                    }
                }

                Toggle("Change Secondary Carrier Text", isOn: $secondaryCarrierTextEnabled).onChange(of: secondaryCarrierTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setSecondaryCarrier(secondaryCarrierText) }
                    else  { StatusManager.sharedInstance().unsetSecondaryCarrier() }
                }
                TextField("Secondary Carrier Text", text: $secondaryCarrierText).onChange(of: secondaryCarrierText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 100 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    secondaryCarrierText = safeNv
                    if secondaryCarrierTextEnabled { StatusManager.sharedInstance().setSecondaryCarrier(safeNv) }
                }

                Toggle("Change Secondary Service Badge Text", isOn: $secondaryServiceBadgeTextEnabled).onChange(of: secondaryServiceBadgeTextEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setSecondaryServiceBadge(secondaryServiceBadgeText) }
                    else  { StatusManager.sharedInstance().unsetSecondaryServiceBadge() }
                }
                TextField("Secondary Service Badge Text", text: $secondaryServiceBadgeText).onChange(of: secondaryServiceBadgeText) { nv in
                    var safeNv = nv
                    while safeNv.utf8CString.count > 100 { safeNv = String(safeNv.prefix(safeNv.count - 1)) }
                    secondaryServiceBadgeText = safeNv
                    if secondaryServiceBadgeTextEnabled { StatusManager.sharedInstance().setSecondaryServiceBadge(safeNv) }
                }

                Toggle("Change Secondary Data Network Type", isOn: $secondaryDataNetworkTypeEnabled).onChange(of: secondaryDataNetworkTypeEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setSecondaryDataNetworkType(Int32(secondaryDataNetworkType)) }
                    else  { StatusManager.sharedInstance().unsetSecondaryDataNetworkType() }
                }
                HStack {
                    Text("Secondary Data Network Type")
                    Spacer()
                    Menu {
                        ForEach(Array(NetworkTypes.enumerated()), id: \.offset) { i, net in
                            Button(action: {
                                secondaryDataNetworkType = i
                                if secondaryDataNetworkTypeEnabled { StatusManager.sharedInstance().setSecondaryDataNetworkType(Int32(i)) }
                            }) { Text(net) }
                        }
                    } label: {
                        Text(NetworkTypes[secondaryDataNetworkType])
                    }
                }
            }

            // MARK: - Battery / Signal
            Section {
                Toggle("Change Battery Icon Capacity", isOn: $batteryCapacityEnabled).onChange(of: batteryCapacityEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setBatteryCapacity(Int32(batteryCapacity)) }
                    else  { StatusManager.sharedInstance().unsetBatteryCapacity() }
                }
                HStack {
                    Text("\(Int(batteryCapacity))%").frame(width: 50)
                    Slider(value: $batteryCapacity, in: 0...100, step: 1.0).onChange(of: batteryCapacity) { nv in
                        StatusManager.sharedInstance().setBatteryCapacity(Int32(nv))
                    }
                }

                Toggle("Change WiFi Signal Strength Bars", isOn: $wiFiStrengthBarsEnabled).onChange(of: wiFiStrengthBarsEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setWiFiSignalStrengthBars(Int32(wiFiStrengthBars)) }
                    else  { StatusManager.sharedInstance().unsetWiFiSignalStrengthBars() }
                }
                HStack {
                    Text("\(Int(wiFiStrengthBars))").frame(width: 50)
                    Slider(value: $wiFiStrengthBars, in: 0...3, step: 1.0).onChange(of: wiFiStrengthBars) { nv in
                        StatusManager.sharedInstance().setWiFiSignalStrengthBars(Int32(nv))
                    }
                }

                Toggle("Change Primary GSM Signal Strength Bars", isOn: $gsmStrengthBarsEnabled).onChange(of: gsmStrengthBarsEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setGsmSignalStrengthBars(Int32(gsmStrengthBars)) }
                    else  { StatusManager.sharedInstance().unsetGsmSignalStrengthBars() }
                }
                HStack {
                    Text("\(Int(gsmStrengthBars))").frame(width: 50)
                    Slider(value: $gsmStrengthBars, in: 0...4, step: 1.0).onChange(of: gsmStrengthBars) { nv in
                        StatusManager.sharedInstance().setGsmSignalStrengthBars(Int32(nv))
                    }
                }

                Toggle("Change Secondary GSM Signal Strength Bars", isOn: $secondaryGsmStrengthBarsEnabled).onChange(of: secondaryGsmStrengthBarsEnabled) { nv in
                    if nv { StatusManager.sharedInstance().setSecondaryGsmSignalStrengthBars(Int32(secondaryGsmStrengthBars)) }
                    else  { StatusManager.sharedInstance().unsetSecondaryGsmSignalStrengthBars() }
                }
                HStack {
                    Text("\(Int(secondaryGsmStrengthBars))").frame(width: 50)
                    Slider(value: $secondaryGsmStrengthBars, in: 0...4, step: 1.0).onChange(of: secondaryGsmStrengthBars) { nv in
                        StatusManager.sharedInstance().setSecondaryGsmSignalStrengthBars(Int32(nv))
                    }
                }
            }

            // MARK: - Raw Signal
            Section {
                Toggle("Show Numeric WiFi Strength", isOn: $displayingRawWiFiStrength).onChange(of: displayingRawWiFiStrength) { nv in
                    StatusManager.sharedInstance().displayRawWifiSignal(nv)
                }
                Toggle("Show Numeric Cellular Strength", isOn: $displayingRawGSMStrength).onChange(of: displayingRawGSMStrength) { nv in
                    StatusManager.sharedInstance().displayRawGSMSignal(nv)
                }
            }

            // MARK: - Hide Items
            Section(footer: Text("*Will also hide carrier name\n**Will also hide cellular data indicator")) {
                Group {
                    Toggle("Hide Status Bar Time", isOn: $clockHidden).onChange(of: clockHidden) { nv in StatusManager.sharedInstance().hideClock(nv) }
                    Toggle("Hide Do Not Disturb", isOn: $DNDHidden).onChange(of: DNDHidden) { nv in StatusManager.sharedInstance().hideDND(nv) }
                    Toggle("Hide Airplane Mode", isOn: $airplaneHidden).onChange(of: airplaneHidden) { nv in StatusManager.sharedInstance().hideAirplane(nv) }
                    Toggle("Hide Cellular*", isOn: $cellHidden).onChange(of: cellHidden) { nv in StatusManager.sharedInstance().hideCell(nv) }
                    Toggle("Hide Wi-Fi**", isOn: $wiFiHidden).onChange(of: wiFiHidden) { nv in StatusManager.sharedInstance().hideWiFi(nv) }
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        Toggle("Hide Battery", isOn: $batteryHidden).onChange(of: batteryHidden) { nv in StatusManager.sharedInstance().hideBattery(nv) }
                    }
                    Toggle("Hide Bluetooth", isOn: $bluetoothHidden).onChange(of: bluetoothHidden) { nv in StatusManager.sharedInstance().hideBluetooth(nv) }
                    Toggle("Hide Alarm", isOn: $alarmHidden).onChange(of: alarmHidden) { nv in StatusManager.sharedInstance().hideAlarm(nv) }
                    Toggle("Hide Location", isOn: $locationHidden).onChange(of: locationHidden) { nv in StatusManager.sharedInstance().hideLocation(nv) }
                    Toggle("Hide Rotation Lock", isOn: $rotationHidden).onChange(of: rotationHidden) { nv in StatusManager.sharedInstance().hideRotation(nv) }
                }
                Toggle("Hide AirPlay", isOn: $airPlayHidden).onChange(of: airPlayHidden) { nv in StatusManager.sharedInstance().hideAirPlay(nv) }
                Toggle("Hide CarPlay", isOn: $carPlayHidden).onChange(of: carPlayHidden) { nv in StatusManager.sharedInstance().hideCarPlay(nv) }
                Toggle("Hide VPN", isOn: $VPNHidden).onChange(of: VPNHidden) { nv in StatusManager.sharedInstance().hideVPN(nv) }
            }

            // MARK: - Reset
            Section(footer: Text("Your device will respring.")) {
                Button("Reset All") {
                    if fm.fileExists(atPath: "/var/mobile/Library/SpringBoard/statusBarOverrides") {
                        try? fm.removeItem(at: URL(fileURLWithPath: "/var/mobile/Library/SpringBoard/statusBarOverrides"))
                    }
                    mgr.respring()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Status Bar")
    }
}
