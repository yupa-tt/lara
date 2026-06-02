//
//  AppClipView.swift
//  lara
//

import SwiftUI

struct AppClipView: View {
    @ObservedObject var mgr: laramgr
    @State private var isEnabled: Bool = false
    @State private var isWorking: Bool = false
    @State private var result: String? = nil

    var body: some View {
        List {
            Section(
                header: HeaderLabel(text: "App Clip", icon: "app.badge"),
                footer: Text("Sets IsAppClip = true on all WebClips entries, causing shortcuts to appear as App Clips on the home screen. Respring to apply.")
            ) {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(isEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(isEnabled ? .green : .secondary)
                        .monospaced()
                }
            }

            Section {
                Button {
                    setAppClip(true)
                } label: {
                    if isWorking && !isEnabled {
                        HStack { Text("Enabling…"); Spacer(); ProgressView() }
                    } else {
                        Text("Enable App Clip")
                    }
                }
                .disabled(isWorking || isEnabled)

                Button {
                    setAppClip(false)
                } label: {
                    if isWorking && isEnabled {
                        HStack { Text("Disabling…"); Spacer(); ProgressView() }
                    } else {
                        Text("Disable App Clip")
                    }
                }
                .disabled(isWorking || !isEnabled)
                .foregroundColor(.red)

                Button("Respring") {
                    mgr.respring()
                }
                .disabled(isWorking)
            }
        }
        .navigationTitle("App Clip")
        .onAppear {
            isEnabled = ShortcutManager.isAppClipEnabled()
        }
        .alert("Result", isPresented: .constant(result != nil)) {
            Button("OK") { result = nil }
        } message: {
            Text(result ?? "")
        }
    }

    private func setAppClip(_ enabled: Bool) {
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try ShortcutManager.setAppClip(enabled)
                DispatchQueue.main.async {
                    isWorking = false
                    isEnabled = enabled
                    result = "Applied. Respring to see changes."
                }
            } catch {
                DispatchQueue.main.async {
                    isWorking = false
                    result = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
