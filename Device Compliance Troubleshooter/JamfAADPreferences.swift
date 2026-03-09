//
//  JamfAADPreferences.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import Foundation

final class JamfAADPreferences {
    static let shared = JamfAADPreferences()

    private let domain = "com.jamf.management.jamfAAD"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: domain)
    }

    func boolValue(forKey key: String) -> Bool? {
        if let value = defaults?.object(forKey: key) as? Bool {
            return value
        }
        if let value = defaults?.object(forKey: key) as? String {
            return (value as NSString).boolValue
        }
        return nil
    }

    func intValue(forKey key: String) -> Int? {
        defaults?.object(forKey: key) as? Int
    }

    func stringValue(forKey key: String) -> String? {
        defaults?.object(forKey: key) as? String
    }

    func setBool(_ value: Bool?, forKey key: String) {
        if let value {
            defaults?.set(value, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
        synchronize()
    }

    func setInt(_ value: Int?, forKey key: String) {
        if let value {
            defaults?.set(value, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
        synchronize()
    }

    func setString(_ value: String?, forKey key: String) {
        if let value {
            defaults?.set(value, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
        synchronize()
    }

    var isLoggingEnabled: Bool {
        boolValue(forKey: "logPII") == true
    }

    func setLoggingEnabled(_ enabled: Bool) {
        if enabled {
            // Per Jamf documentation, logPII is stored as a string "true".
            setString("true", forKey: "logPII")
        } else {
            setString(nil, forKey: "logPII")
        }
    }

    private func synchronize() {
        defaults?.synchronize()
        CFPreferencesAppSynchronize(domain as CFString)
    }
}

