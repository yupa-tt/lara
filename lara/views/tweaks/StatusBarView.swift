//
//  StatusBarView.swift
//  lara
//
//  Ported from Cowabunga (MIT License)
//  Changes:
//    - MDCモード / statusBarOverridesEditing / Apply ボタンを削除
//    - UIStatusBarServer 直接呼び出しのみ（即時反映）
//    - lara の PartyUI デザインシステムに合わせて再実装
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var mgr: laramgr

    // MARK: - Carrier
    @State private var carrierText: String         = StatusManager.sharedInstance().getCarrierOverride()
    @State private var carrierEnabled: Bool        = StatusManager.sharedInstance().isCarrierOverridden()

    // MARK: - Time / Date
    @State private var timeText: String            = StatusManager.sharedInstance().getTimeOverride()
    @State private var timeEnabled: Bool           = StatusManager.sharedInstance().isTimeOverridden()
    @State private var dateText: String            = StatusManager.sharedInstance().getDateOverride()
    @State private var dateEnabled: Bool           = StatusManager.sharedInstance().isDateOverridden()

    // MARK: - Battery
    @State private var batteryCapacity: Double     = Double(StatusManager.sharedInstance().getBatteryCapacityOverride())
    @State private var batteryCapacityEnabled: Bool = StatusManager.sharedInstance().isBatteryCapacityOverridden()
    @State private var batteryDetailText: String   = StatusManager.sharedInstance().getBatteryDetailOverride()
    @State private var batteryDetailEnabled: Bool  = StatusManager.sharedInstance().isBatteryDetailOverridden()

    // MARK: - Signal
    @State private var wifiStrength: Double        = Double(StatusManager.sharedInstance().getWiFiSignalStrengthBarsOverride())
    @State private var wifiStrengthEnabled: Bool   = StatusManager.sharedInstance().isWiFiSignalStrengthBarsOverridden()
    @State private var gsmStrength: Double         = Double(StatusManager.sharedInstance().getGsmSignalStrengthBarsOverride())
    @State private var gsmStrengthEnabled: Bool    = StatusManager.sharedInstance().isGsmSignalStrengthBarsOverridden()

    // MARK: - Network type
    private let networkTypes: [(label: String, value: Int)] = [
        ("Default", -1), ("GPRS", 0), ("EDGE", 1), ("3G", 2), ("4G", 3),
        ("LTE", 4), ("WiFi", 5), ("Hotspot", 6), ("5Gₑ", 8), ("LTE+", 10),
        ("5G", 11), ("5G+", 12), ("5GUW", 13), ("5GUC", 14),
    ]
    @State private var dataNetworkType: Int        = Int(StatusManager.sharedInstance().getDataNetworkTypeOverride())
    @State private var dataNetworkTypeEnabled: Bool = StatusManager.sharedInstance().isDataNetworkTypeOverridden()

    // MARK: - Hide items
    @State private var clockHidden: Bool       = StatusManager.sharedInstance().isClockHidden()
    @State private var dndHidden: Bool         = StatusManager.sharedInstance().isDNDHidden()
    @State private var airplaneHidden: Bool    = StatusManager.sharedInstance().isAirplaneHidden()
    @State private var cellHidden: Bool        = StatusManager.sharedInstance().isCellHidden()
    @State private var wifiHidden: Bool        = StatusManager.sharedInstance().isWiFiHidden()
    @State private var batteryHidden: Bool     = StatusManager.sharedInstance().isBatteryHidden()
    @State private var bluetoothHidden: Bool   = StatusManager.sharedInstance().isBluetoothHidden()
    @State private var alarmHidden: Bool       = StatusManager.sharedInstance().isAlarmHidden()
    @State private var locationHidden: Bool    = StatusManager.sharedInstance().isLocationHidden()
    @State private var rotationHidden: Bool    = StatusManager.sharedInstance().isRotationHidden()
    @State private var airPlayHidden: Bool     = StatusManager.sharedInstance().isAirPlayHidden()
    @State private var carPlayHidden: Bool     = StatusManager.sharedInstance().isCarPlayHidden()
    @State private var vpnHidden: Bool         = StatusManager.sharedInstance().isVPNHidden()
    @State private var micHidden: Bool         = StatusManager.sharedInstance().isMicrophoneUseHidden()
    @State private var cameraHidden: Bool      = StatusManager.sharedInstance().isCameraUseHidden()

    var body: some View {
        List {
            // MARK: Carrier
            Section(header: HeaderLabel(text: "Carrier", icon: "antenna.radiowaves.left.and.right")) {
                overrideRow(
                    label: "Carrier Text",
                    enabled: $carrierEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setCarrier(carrierText)
                          : StatusManager.sharedInstance().unsetCarrier()
                    }
                ) {
                    TextField("Carrier", text: $carrierText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: carrierText) { _ in
                            if carrierEnabled {
                                StatusManager.sharedInstance().setCarrier(carrierText)
                            }
                        }
                }
            }

            // MARK: Time / Date
            Section(header: HeaderLabel(text: "Time & Date", icon: "clock")) {
                overrideRow(
                    label: "Time",
                    enabled: $timeEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setTime(timeText)
                          : StatusManager.sharedInstance().unsetTime()
                    }
                ) {
                    TextField("e.g. 9:41", text: $timeText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: timeText) { _ in
                            if timeEnabled { StatusManager.sharedInstance().setTime(timeText) }
                        }
                }

                overrideRow(
                    label: "Date",
                    enabled: $dateEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setDate(dateText)
                          : StatusManager.sharedInstance().unsetDate()
                    }
                ) {
                    TextField("e.g. Mon Jan 1", text: $dateText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: dateText) { _ in
                            if dateEnabled { StatusManager.sharedInstance().setDate(dateText) }
                        }
                }
            }

            // MARK: Battery
            Section(header: HeaderLabel(text: "Battery", icon: "battery.100")) {
                overrideRow(
                    label: "Capacity: \(Int(batteryCapacity))%",
                    enabled: $batteryCapacityEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setBatteryCapacity(Int32(batteryCapacity))
                          : StatusManager.sharedInstance().unsetBatteryCapacity()
                    }
                ) {
                    Slider(value: $batteryCapacity, in: 0...100, step: 1)
                        .onChange(of: batteryCapacity) { _ in
                            if batteryCapacityEnabled {
                                StatusManager.sharedInstance().setBatteryCapacity(Int32(batteryCapacity))
                            }
                        }
                }
            }

            // MARK: Signal / Network
            Section(header: HeaderLabel(text: "Signal", icon: "chart.bar.fill")) {
                overrideRow(
                    label: "WiFi Bars: \(Int(wifiStrength))",
                    enabled: $wifiStrengthEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setWiFiSignalStrengthBars(Int32(wifiStrength))
                          : StatusManager.sharedInstance().unsetWiFiSignalStrengthBars()
                    }
                ) {
                    Slider(value: $wifiStrength, in: 0...3, step: 1)
                        .onChange(of: wifiStrength) { _ in
                            if wifiStrengthEnabled {
                                StatusManager.sharedInstance().setWiFiSignalStrengthBars(Int32(wifiStrength))
                            }
                        }
                }

                overrideRow(
                    label: "GSM Bars: \(Int(gsmStrength))",
                    enabled: $gsmStrengthEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setGsmSignalStrengthBars(Int32(gsmStrength))
                          : StatusManager.sharedInstance().unsetGsmSignalStrengthBars()
                    }
                ) {
                    Slider(value: $gsmStrength, in: 0...4, step: 1)
                        .onChange(of: gsmStrength) { _ in
                            if gsmStrengthEnabled {
                                StatusManager.sharedInstance().setGsmSignalStrengthBars(Int32(gsmStrength))
                            }
                        }
                }

                overrideRow(
                    label: "Network Type",
                    enabled: $dataNetworkTypeEnabled,
                    onToggle: { v in
                        v ? StatusManager.sharedInstance().setDataNetworkType(Int32(dataNetworkType))
                          : StatusManager.sharedInstance().unsetDataNetworkType()
                    }
                ) {
                    Picker("", selection: $dataNetworkType) {
                        ForEach(networkTypes, id: \.value) { item in
                            Text(item.label).tag(item.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: dataNetworkType) { _ in
                        if dataNetworkTypeEnabled {
                            StatusManager.sharedInstance().setDataNetworkType(Int32(dataNetworkType))
                        }
                    }
                }
            }

            // MARK: Hide Items
            Section(header: HeaderLabel(text: "Hide Items", icon: "eye.slash")) {
                hideToggleRow("Clock",      isOn: $clockHidden)     { StatusManager.sharedInstance().hideClock($0) }
                hideToggleRow("DND",        isOn: $dndHidden)       { StatusManager.sharedInstance().hideDND($0) }
                hideToggleRow("Airplane",   isOn: $airplaneHidden)  { StatusManager.sharedInstance().hideAirplane($0) }
                hideToggleRow("Cell",       isOn: $cellHidden)      { StatusManager.sharedInstance().hideCell($0) }
                hideToggleRow("WiFi",       isOn: $wifiHidden)      { StatusManager.sharedInstance().hideWiFi($0) }
                hideToggleRow("Battery",    isOn: $batteryHidden)   { StatusManager.sharedInstance().hideBattery($0) }
                hideToggleRow("Bluetooth",  isOn: $bluetoothHidden) { StatusManager.sharedInstance().hideBluetooth($0) }
                hideToggleRow("Alarm",      isOn: $alarmHidden)     { StatusManager.sharedInstance().hideAlarm($0) }
                hideToggleRow("Location",   isOn: $locationHidden)  { StatusManager.sharedInstance().hideLocation($0) }
                hideToggleRow("Rotation",   isOn: $rotationHidden)  { StatusManager.sharedInstance().hideRotation($0) }
                hideToggleRow("AirPlay",    isOn: $airPlayHidden)   { StatusManager.sharedInstance().hideAirPlay($0) }
                hideToggleRow("CarPlay",    isOn: $carPlayHidden)   { StatusManager.sharedInstance().hideCarPlay($0) }
                hideToggleRow("VPN",        isOn: $vpnHidden)       { StatusManager.sharedInstance().hideVPN($0) }
                hideToggleRow("Microphone", isOn: $micHidden)       { StatusManager.sharedInstance().hideMicrophoneUse($0) }
                hideToggleRow("Camera",     isOn: $cameraHidden)    { StatusManager.sharedInstance().hideCameraUse($0) }
            }
        }
        .navigationTitle("Status Bar")
    }

    // MARK: - Helper Views

    /// オーバーライドトグル付き行
    @ViewBuilder
    private func overrideRow<Content: View>(
        label: String,
        enabled: Binding<Bool>,
        onToggle: @escaping (Bool) -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { enabled.wrappedValue },
                    set: { v in enabled.wrappedValue = v; onToggle(v) }
                ))
                .labelsHidden()
            }
            if enabled.wrappedValue {
                content()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: enabled.wrappedValue)
    }

    /// 非表示トグル行（即時反映）
    @ViewBuilder
    private func hideToggleRow(
        _ label: String,
        isOn: Binding<Bool>,
        action: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(label, isOn: Binding(
            get: { isOn.wrappedValue },
            set: { v in isOn.wrappedValue = v; action(v) }
        ))
    }
}
