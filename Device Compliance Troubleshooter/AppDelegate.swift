//
//  AppDelegate.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated {
            JamfProUploadSessionStore.shared.clearCredentials()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard JamfAADPreferences.shared.isLoggingEnabled else {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "JamfAAD logging is enabled"
        alert.informativeText = "Do you want to disable JamfAAD logging (logPII) before quitting?"
        alert.addButton(withTitle: "Disable & Quit")
        alert.addButton(withTitle: "Quit Without Disabling")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            JamfAADPreferences.shared.setLoggingEnabled(false)
            return .terminateNow
        case .alertSecondButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }
}

