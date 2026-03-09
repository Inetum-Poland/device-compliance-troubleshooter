//
//  ContentView.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var prefsModel = JamfAADPreferencesModel()
    @StateObject private var logController = LogController()
    @Environment(\.openWindow) private var openWindow
    @FocusState private var isSearchFocused: Bool
    @State private var showSearchBar = false
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
        // ScrollView {
        VStack(alignment: .leading, spacing: 6) {
            
            GroupBox() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack {
                            AppIconDot()
                            Text("Network Test")
                                .font(.headline)
                            //.padding(.leading, 27)
                            Spacer()
                            
                            Button("Open") {
                                openWindow(id: "connection-tester")
                            }
                            .padding(.horizontal,6)
                            
                            
                        }
                        Text("Test reachability for Microsoft and Apple endpoints.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 27)
                    }
                    .padding(.vertical,8)
                }
                .padding(.horizontal,8)
            }

           
            
            Spacer()
            GroupBox() {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StateDot(isOn: prefsModel.useWKWebView == true)
                                Text("Use WKWebView for sign-in")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Button("Enable") {
                                        prefsModel.applyWebView(enabled: true)
                                    }
                                    Button("Clear") {
                                        prefsModel.clearWebView()
                                    }
                                }
                                .padding(.horizontal, 6)
                                
                            }
                            
                            Text("Sets useWKWebView = true")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 27)
                            
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                StateDot(isOn: prefsModel.tokenRetryCount > 0)
                                Text("Recheck token at JamfAAD check-in")
                                    .font(.headline)
                                Spacer()
                                HStack {
                                    Button("Set Recommended (3/42s)") {
                                        prefsModel.applyTokenRetry(count: 3, waitSeconds: 42)
                                    }
                                    Button("Clear") {
                                        prefsModel.clearTokenRetry()
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                            
                            Text("tokenRetryCount = \(prefsModel.tokenRetryCount), tokenRetryWaitTime = \(prefsModel.tokenRetryWaitTime)s")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 27)
                            
                            HStack {
                                Stepper("Retry Count \(prefsModel.tokenRetryCount)", value: $prefsModel.tokenRetryCount, in: 0...10)
                                Stepper("Wait \(prefsModel.tokenRetryWaitTime)s", value: $prefsModel.tokenRetryWaitTime, in: 1...300)
                                Button("Apply") {
                                    prefsModel.applyTokenRetry(count: prefsModel.tokenRetryCount, waitSeconds: prefsModel.tokenRetryWaitTime)
                                }
                            }
                            .padding(.horizontal, 27)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StateDot(isOn: prefsModel.disableUPNLoginHint == true)
                                Text("Disable UPN login hint")
                                    .font(.headline)
                                Link("PI-007330 fix", destination: URL(string: "https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-intune-current/page/Creating_a_Policy_Directing_Users_to_Register_Mac_Computers_with_Azure_Active_Directory.html#task-99")!)
                                
                                Spacer()
                                HStack {
                                    Button("Enable") {
                                        prefsModel.applyDisableUPNLoginHint(enabled: true)
                                    }
                                    Button("Clear") {
                                        prefsModel.clearDisableUPNLoginHint()
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                            
                            Text("Sets disableUPNLoginHint = true")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 27)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.up.doc")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                                Text("Jamf Pro Upload")
                                    .font(.headline)
                                Spacer()

                                Button("Upload") {
                                    openWindow(id: "jamf-pro-upload")
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .refreshJamfUploaderPreview, object: nil)
                                    }
                                }
                                .padding(.horizontal, 6)
                            }

                            Text("Build and upload a JamfAAD configuration profile to Jamf Pro.")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 27)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical, 6)
                }
                .padding(.horizontal,8)
            }
            HStack() {
                Spacer()
                Text("Note: If above preferences are managed by a configuration profile, changes may not apply.")
                    .font(.body)
                Spacer()
            }

            Spacer()
                .foregroundStyle(.secondary)
            
            
            GroupBox() {
                HStack {
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(
                                "Enable JamfAAD logging (logPII)",
                                isOn: Binding(
                                    get: { prefsModel.logPIIEnabled },
                                    set: { prefsModel.setLogging(enabled: $0) }
                                )
                            )
                        }
                        Spacer()
                        HStack {
                            Button(logController.isStreaming ? "Stop" : "Stream") {
                                if logController.isStreaming {
                                    logController.stopStream()
                                } else {
                                    logController.startStream()
                                }
                            }
                            Button("Search") {
                                showSearchBar.toggle()
                                if showSearchBar { isSearchFocused = true }
                            }
                            .keyboardShortcut("f", modifiers: .command)
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
                        //Spacer()
                    }

                    if showSearchBar {
                        HStack(spacing: 8) {
                            TextField("Search logs…", text: $logSearchQuery)
                                .textFieldStyle(.roundedBorder)
                                .focused($isSearchFocused)
                            if !logSearchQuery.isEmpty {
                                Button("Clear") {
                                    logSearchQuery = ""
                                }
                                .buttonStyle(.borderless)
                            }
                            Button("Done") {
                                showSearchBar = false
                                isSearchFocused = false
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }

                    TextEditor(text: logContentBinding)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 220)
                        .border(Color.secondary.opacity(0.3))
                }
                .padding(.vertical, 6)
            }
                .padding(.horizontal,8)
            }
            
            
        }
        .padding(20)
        .frame( minWidth: 700, minHeight: 800)
        //}
        
        .onAppear {
            prefsModel.load()
        }
    }
    
    
    
    //    private var header: some View {
    //        VStack(alignment: .leading, spacing: 6) {
    //            Text("Device Compliance Troubleshooter")
    //                .font(.largeTitle)
    //                .bold()
    //        }
    //    }
}

private struct StepRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let enableTitle: String
    let linkTitle: String?
    let linkURL: URL?
    let enableAction: () -> Void
    let clearAction: () -> Void
    
    init(
        title: String,
        subtitle: String,
        isEnabled: Bool,
        enableTitle: String,
        linkTitle: String? = nil,
        linkURL: URL? = nil,
        enableAction: @escaping () -> Void,
        clearAction: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isEnabled = isEnabled
        self.enableTitle = enableTitle
        self.linkTitle = linkTitle
        self.linkURL = linkURL
        self.enableAction = enableAction
        self.clearAction = clearAction
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StateDot(isOn: isEnabled)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    if let linkTitle, let linkURL {
                        Link(linkTitle, destination: linkURL)
                            .font(.headline)
                    }
                }
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(enableTitle) {
                enableAction()
            }
            Button("Clear") {
                clearAction()
            }
        }
    }
}


private struct AppIconDot: View {
    var body: some View {
        Image(systemName: "globe")
            .foregroundStyle(.secondary)
            .font(.title3)
    }
}



private struct StateDot: View {
    let isOn: Bool
    
    var body: some View {
        Image(systemName: isOn ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(isOn ? .green : .red)
            .font(.title3)
    }
}

#Preview {
    ContentView()
}
