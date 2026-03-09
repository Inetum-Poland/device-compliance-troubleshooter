//
//  JamfProUploadView.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import SwiftUI
import Combine

extension Notification.Name {
    static let refreshJamfUploaderPreview = Notification.Name("refreshJamfUploaderPreview")
}

@MainActor
final class JamfProUploadSessionStore {
    static let shared = JamfProUploadSessionStore()

    var baseURL: String = ""
    var authMode: JamfProAuthMode = .usernamePassword
    var username: String = ""
    var password: String = ""
    var clientID: String = ""
    var clientSecret: String = ""
    var profileName: String = ""

    /// Clears all credentials from memory. Call on app terminate for security.
    func clearCredentials() {
        baseURL = ""
        authMode = .usernamePassword
        username = ""
        password = ""
        clientID = ""
        clientSecret = ""
        profileName = ""
    }
}

@MainActor
final class JamfProUploadViewModel: ObservableObject {
    @Published var baseURL: String = "" { didSet { persistSession() } }
    @Published var authMode: JamfProAuthMode = .usernamePassword { didSet { persistSession() } }

    @Published var username: String = "" { didSet { persistSession() } }
    @Published var password: String = "" { didSet { persistSession() } }

    @Published var clientID: String = "" { didSet { persistSession() } }
    @Published var clientSecret: String = "" { didSet { persistSession() } }

    @Published var profileName: String = "" { didSet { persistSession() } }

    @Published var isUploading = false
    @Published var statusMessage: String = ""
    @Published private(set) var settingsPlistPreview: String = ""
    @Published private(set) var hasSettingsToUpload: Bool = false
    private var isRestoringSession = false

    init() {
        isRestoringSession = true
        let session = JamfProUploadSessionStore.shared
        baseURL = session.baseURL
        authMode = session.authMode
        username = session.username
        password = session.password
        clientID = session.clientID
        clientSecret = session.clientSecret
        profileName = session.profileName
        isRestoringSession = false
        refreshSettingsPreview()
    }

    var canUpload: Bool {
        hasSettingsToUpload && !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func refreshSettingsPreview() {
        settingsPlistPreview = JamfProUploader.settingsPlistPreview()
        hasSettingsToUpload = !settingsPlistPreview.isEmpty
    }

    func upload() {
        guard !isUploading else { return }
        refreshSettingsPreview()
        guard hasSettingsToUpload else {
            statusMessage = "There's no settings to upload, please select appropriate settings and try again."
            return
        }

        statusMessage = "Uploading profile to Jamf Pro..."
        isUploading = true

        Task {
            defer { isUploading = false }

            do {
                let summary = try await JamfProUploader.upload(
                    baseURL: baseURL,
                    authMode: authMode,
                    username: username,
                    password: password,
                    clientID: clientID,
                    clientSecret: clientSecret,
                    profileName: profileName
                )
                statusMessage = "Success (HTTP \(summary.responseCode)): \(summary.profileName) uploaded to \(summary.endpoint.absoluteString)"
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func persistSession() {
        guard !isRestoringSession else { return }
        let session = JamfProUploadSessionStore.shared
        session.baseURL = baseURL
        session.authMode = authMode
        session.username = username
        session.password = password
        session.clientID = clientID
        session.clientSecret = clientSecret
        session.profileName = profileName
    }
}

struct JamfProUploadView: View {
    @StateObject private var viewModel = JamfProUploadViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            GroupBox() {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("https://yourcompany.jamfcloud.com", text: $viewModel.baseURL)
                        .textFieldStyle(.roundedBorder)

                    Picker("", selection: $viewModel.authMode) {
                        ForEach(JamfProAuthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.authMode == .usernamePassword {
                        TextField("Username", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        TextField("API Client ID", text: $viewModel.clientID)
                            .textFieldStyle(.roundedBorder)
                        SecureField("API Client Secret", text: $viewModel.clientSecret)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Profile Name", text: $viewModel.profileName)
                        .textFieldStyle(.roundedBorder)
                    
                }
                .padding(.vertical, 4)
            }

            GroupBox(label: Text("Profile Settings:")) {
                VStack(alignment: .leading, spacing: 8) {
                      
                    if viewModel.hasSettingsToUpload {
                        ScrollView {
                            Text(viewModel.settingsPlistPreview)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .padding(10)
                        }
                        .frame(minHeight: 269)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text("There's no settings to upload, please select appropriate settings and try again.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            
            //Spacer()
            
            HStack {
                Text(viewModel.statusMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button(viewModel.isUploading ? "Uploading..." : "Upload to Jamf Pro") {
                    viewModel.upload()
                }
                .disabled(viewModel.isUploading || !viewModel.canUpload)
               
            }
            Spacer()

        }
        .padding(20)
        .frame(minWidth: 600, maxWidth: 700, minHeight: 620, maxHeight: 800)
        
        .onAppear {
            viewModel.refreshSettingsPreview()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshSettingsPreview()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshJamfUploaderPreview)) { _ in
            viewModel.refreshSettingsPreview()
        }
    }
}

#Preview {
    JamfProUploadView()
}
