//
//  JamfAADPreferencesModel.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import Foundation
import Combine

@MainActor
final class JamfAADPreferencesModel: ObservableObject {
    @Published var useWKWebView: Bool = false
    @Published var tokenRetryCount: Int = 0
    @Published var tokenRetryWaitTime: Int = 5
    @Published var disableUPNLoginHint: Bool = false
    @Published var logPIIEnabled: Bool = false

    private let prefs = JamfAADPreferences.shared

    func load() {
        useWKWebView = prefs.boolValue(forKey: "useWKWebView") ?? false
        tokenRetryCount = prefs.intValue(forKey: "tokenRetryCount") ?? 0
        tokenRetryWaitTime = prefs.intValue(forKey: "tokenRetryWaitTime") ?? 5
        disableUPNLoginHint = prefs.boolValue(forKey: "disableUPNLoginHint") ?? false
        logPIIEnabled = prefs.isLoggingEnabled
    }

    func applyWebView(enabled: Bool) {
        prefs.setBool(enabled, forKey: "useWKWebView")
        load()
    }

    func clearWebView() {
        prefs.setBool(nil, forKey: "useWKWebView")
        load()
    }

    func applyTokenRetry(count: Int, waitSeconds: Int) {
        prefs.setInt(count, forKey: "tokenRetryCount")
        prefs.setInt(waitSeconds, forKey: "tokenRetryWaitTime")
        load()
    }

    func clearTokenRetry() {
        prefs.setInt(nil, forKey: "tokenRetryCount")
        prefs.setInt(nil, forKey: "tokenRetryWaitTime")
        load()
    }

    func applyDisableUPNLoginHint(enabled: Bool) {
        prefs.setBool(enabled, forKey: "disableUPNLoginHint")
        load()
    }

    func clearDisableUPNLoginHint() {
        prefs.setBool(nil, forKey: "disableUPNLoginHint")
        load()
    }

    func setLogging(enabled: Bool) {
        prefs.setLoggingEnabled(enabled)
        load()
    }
}
