//
//  CarrierView.swift
//  lara
//

import SwiftUI

struct CarrierView: View {
    @ObservedObject var mgr: laramgr
    @State private var carrierName: String = ""
    @State private var isWorking: Bool = false
    @State private var result: String? = nil

    var body: some View {
        List {
            Section(
                header: HeaderLabel(text: "Carrier Name", icon: "antenna.radiowaves.left.and.right"),
                footer: Text("Overrides the carrier name shown in the status bar. Respring to apply.")
            ) {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("e.g. lara", text: $carrierName)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button {
                    apply()
                } label: {
                    if isWorking {
                        HStack {
                            Text("Applying…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Apply")
                    }
                }
                .disabled(isWorking || carrierName.isEmpty)

                Button("Reset") {
                    carrierName = ""
                    apply()
                }
                .disabled(isWorking)
                .foregroundColor(.red)

                Button("Respring") {
                    mgr.respring()
                }
                .disabled(isWorking)
            }
        }
        .navigationTitle("Carrier Name")
        .onAppear {
            carrierName = CarrierNameManager.getCurrentName() ?? ""
        }
        .alert("Result", isPresented: .constant(result != nil)) {
            Button("OK") { result = nil }
        } message: {
            Text(result ?? "")
        }
    }

    private func apply() {
        isWorking = true
        let name = carrierName
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try CarrierNameManager.setCarrierName(name)
                DispatchQueue.main.async {
                    isWorking = false
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
