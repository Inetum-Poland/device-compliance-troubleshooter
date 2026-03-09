//
//  LogController.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import Foundation
import Combine

@MainActor
final class LogController: ObservableObject {
    @Published var output: String = ""
    @Published var isStreaming: Bool = false

    private var process: Process?
    private var pipe: Pipe?

    func clear() {
        output = ""
    }

    func showLogs(hoursBack: Int) {
        stopStream()
        runLogCommand(arguments: [
            "show",
            "--last",
            "\(hoursBack)h",
            "--predicate",
            "subsystem CONTAINS \"jamfAAD\"",
            "--style",
            "syslog"
        ])
    }

    func startStream() {
        stopStream()
        isStreaming = true
        runLogCommand(arguments: [
            "stream",
            "--predicate",
            "subsystem CONTAINS \"InAdmin\"",
            "--style",
            "syslog"
        ])
    }

    func stopStream() {
        isStreaming = false
        process?.terminate()
        process = nil
        pipe = nil
    }

    private func runLogCommand(arguments: [String]) {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        self.process = process
        self.pipe = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.output.append(text)
            }
        }

        do {
            try process.run()
        } catch {
            output.append("Failed to run log command: \(error.localizedDescription)\n")
            isStreaming = false
        }
    }
}
