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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Window("Network Test", id: "connection-tester") {
            ConnectionTesterView()
        }
        Window("Jamf Pro Upload", id: "jamf-pro-upload") {
            JamfProUploadView()
        }
    }
}
