//
//  LogViewerView.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 17/03/2026.
//

import SwiftUI

struct LogViewerView: View {
    @EnvironmentObject private var logController: LogController
    @StateObject private var prefsModel = JamfAADPreferencesModel()
    @FocusState private var isSearchFocused: Bool
    @State private var logSearchQuery = ""

    private var filteredLogContent: String {
        guard !logSearchQuery.isEmpty else { return logController.output }
        return logController.output
            .components(separatedBy: .newlines)
            .filter { $0.localizedCaseInsensitiveContains(logSearchQuery) }
            .joined(separator: "\n")
    }

    private var logContentBinding: Binding<String> {
        Binding(
            get: { filteredLogContent },
            set: { newValue in
                if logSearchQuery.isEmpty { logController.output = newValue }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle(
                            "Enable JamfAAD logging (logPII)",
                            isOn: Binding(
                                get: { prefsModel.logPIIEnabled },
                                set: { prefsModel.setLogging(enabled: $0) }
                            )
                        )

                        Spacer()

                        HStack {
                            Button(logController.isStreaming ? "Stop" : "Stream") {
                                if logController.isStreaming {
                                    logController.stopStream()
                                } else {
                                    logController.startStream()
                                }
                            }
                            Button("Last 1h") {
                                logController.showLogs(hoursBack: 1)
                            }
                            Button("Last 24h") {
                                logController.showLogs(hoursBack: 24)
                            }
                            Button("Clear") {
                                logController.clear()
                            }
                        }
                        .padding(.horizontal, 6)
                    }

                    HStack(spacing: 8) {
                        TextField("Filter logs…", text: $logSearchQuery)
                            .textFieldStyle(.roundedBorder)
                            .focused($isSearchFocused)
                        if !logSearchQuery.isEmpty {
                            Button("Clear Search") {
                                logSearchQuery = ""
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    TextEditor(text: logContentBinding)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 320)
                        .border(Color.secondary.opacity(0.3))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            prefsModel.load()
            isSearchFocused = true
        }
        .onDisappear {
            logController.stopStream()
        }
    }
}

#Preview {
    LogViewerView()
        .environmentObject(LogController())
}
