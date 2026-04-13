//
//  Device_Compliance_TroubleshooterApp.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import SwiftUI

@main
struct Device_Compliance_TroubleshooterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var logController = LogController()

    var body: some Scene {
        Window("Device Compliance Troubleshooter", id: "main") {
            MainView()
                .environmentObject(logController)
        }
        .defaultSize(width: 980, height: 700)
        .windowResizability(.contentSize)
        Window("Network Test", id: "connection-tester") {
            ConnectionTesterView()
        }
        Window("Jamf Pro Upload", id: "jamf-pro-upload") {
            JamfProUploadView()
        }
        Window("Log Viewer", id: "log-viewer") {
            LogViewerView()
                .environmentObject(logController)
        }
    }
}
