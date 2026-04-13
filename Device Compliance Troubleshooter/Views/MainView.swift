//
//  MainView.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import SwiftUI
import AppKit

private let mainActionColumnWidth: CGFloat = 170

struct MainView: View {
    @StateObject private var prefsModel = JamfAADPreferencesModel()
    @Environment(\.openWindow) private var openWindow
    @State private var draftTokenRetryCount = 0
    @State private var draftTokenRetryWaitTime = 0
    private let jamfAADDocsURL = URL(string: "https://learn.jamf.com/en-US/bundle/technical-paper-microsoft-intune-current/page/Creating_a_Policy_Directing_Users_to_Register_Mac_Computers_with_Azure_Active_Directory.html#task-99")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            GroupBox() {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            AppIconDot()
                            Text("Network Test")
                                .font(.headline)
                            //.padding(.leading, 27)
                            Spacer()

                            Button("Check") {
                                openWindow(id: "connection-tester")
                            }
                            .panelActionButton()


                        }
                        Text("Test reachability for Microsoft and Apple endpoints.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 27)
                    }
                    .padding(.vertical,8)
                }
                .padding(.horizontal,8)
            }

            GroupBox() {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "document.badge.gearshape")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                                Text("Jamf Pro Documentation")
                                    .font(.headline)
                                Spacer()

                                Button("Open") {
                                    NSWorkspace.shared.open(jamfAADDocsURL)
                                }
                                .panelActionButton()
                            }

                            Text("All details for the settings below are documented in this Jamf documentation.")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 27)
                        }
                        .padding(.vertical, 8)

                        Divider()


                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 12) {
                                StateDot(isOn: prefsModel.useWKWebView == true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use WKWebView for sign-in")
                                        .font(.headline)
                                    Text("Forces the Microsoft sign-in flow to open inside a WKWebView instead of the system browser.")
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                  //  Spacer()
                                    Text("Sets: useWKWebView = true in com.jamf.management.jamfAAD")
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer(minLength: 12)

                                HStack {
                                    Button(prefsModel.useWKWebView == true ? "Clear" : "Set") {
                                        if prefsModel.useWKWebView {
                                            prefsModel.clearWebView()

                                        } else {
                                            prefsModel.applyWebView(enabled: true)
                                        }
                                    }
                                }
                                .panelActionButton()
                            }
                        }
                        .padding(.vertical, 8)


                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                StateDot(isOn: prefsModel.tokenRetryCount > 0 || prefsModel.tokenRetryWaitTime > 0)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Retry Entra ID token validation at JamfAAD check-in")
                                        .font(.headline)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text("Retries Entra ID token validation during JamfAAD check-in to help recover from temporary network issues or stalled sign-in state.")
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text("Sets: tokenRetryCount and tokenRetryWaitSeconds in com.jamf.management.jamfAAD.plist")
                                        .foregroundStyle(.tertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .layoutPriority(1)

                                Spacer(minLength: 16)

                                VStack(alignment: .trailing, spacing: 12) {
                                //   HStack(spacing: 12) {
                                    Stepper(value: $draftTokenRetryCount, in: 0...20) {
                                        Text("Retries: \(draftTokenRetryCount)")
                                            .monospacedDigit()
                                    }
                                    .fixedSize()

                                    Stepper(value: $draftTokenRetryWaitTime, in: 0...300) {
                                        Text("Wait: \(draftTokenRetryWaitTime)s")
                                            .monospacedDigit()
                                    }
                                    .fixedSize()

                                    Button((prefsModel.tokenRetryCount != 0 || prefsModel.tokenRetryWaitTime > 0) ? "Clear" : "Set") {
                                        if prefsModel.tokenRetryCount != 0 || prefsModel.tokenRetryWaitTime > 0 {
                                            prefsModel.clearTokenRetry()
                                            prefsModel.tokenRetryCount = 0
                                            prefsModel.tokenRetryWaitTime = 0
                                            draftTokenRetryCount = 0
                                            draftTokenRetryWaitTime = 0
                                        } else {
                                            prefsModel.applyTokenRetry(count: draftTokenRetryCount, waitSeconds: draftTokenRetryWaitTime)
                                            prefsModel.tokenRetryCount = draftTokenRetryCount
                                            prefsModel.tokenRetryWaitTime = draftTokenRetryWaitTime
                                        }
                                    }
                                    .fixedSize()
                                }
                                .frame(width: mainActionColumnWidth, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 8)

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 12) {
                                StateDot(isOn: prefsModel.disableUPNLoginHint == true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Disable UPN login hint")
                                        .font(.headline)

                                    Text("Prevents JamfAAD from sending the UPN login hint during Microsoft sign-in. This can help with environments affected by PI-007330.")
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text("Sets: disableUPNLoginHint = true in com.jamf.management.jamfAAD.plist")
                                        .foregroundStyle(.tertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 12)

                                HStack {
                                    Button(prefsModel.disableUPNLoginHint == true ? "Clear" : "Set") {
                                        if prefsModel.disableUPNLoginHint {
                                            prefsModel.clearDisableUPNLoginHint()
                                        } else {
                                            prefsModel.applyDisableUPNLoginHint(enabled: true)
                                        }
                                    }
                                }
                                .panelActionButton()
                            }
                        }
                        .padding(.vertical, 8)

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.up.doc")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                                Text("Configuration Profile Export")
                                    .font(.headline)
                                Spacer()

                                Button("Open") {
                                    openWindow(id: "jamf-pro-upload")
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .refreshJamfUploaderPreview, object: nil)
                                    }
                                }
                                .panelActionButton()
                            }

                            Text("Generate a configuration profile with the selected settings and download it or upload it to Jamf Pro.")
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

            GroupBox() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                            Text("Log Viewer")
                                .font(.headline)
                            Spacer()

                            Button("Open") {
                                openWindow(id: "log-viewer")
                            }
                            .panelActionButton()
                        }

                        Text("Inspect JamfAAD logs to troubleshoot authentication and compliance issues.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 27)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal,8)
            }


        }
        .padding(20)
        .frame(minWidth: 760, alignment: .topLeading)

        .onAppear {
            prefsModel.load()
            draftTokenRetryCount = prefsModel.tokenRetryCount
            draftTokenRetryWaitTime = prefsModel.tokenRetryWaitTime
        }
        .onChange(of: prefsModel.tokenRetryCount) { _, newValue in
            draftTokenRetryCount = newValue
        }
        .onChange(of: prefsModel.tokenRetryWaitTime) { _, newValue in
            draftTokenRetryWaitTime = newValue
        }
    }

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

private struct PanelActionButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: mainActionColumnWidth, alignment: .trailing)
    }
}

private extension View {
    func panelActionButton() -> some View {
        modifier(PanelActionButtonModifier())
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
        MainView()
    }
