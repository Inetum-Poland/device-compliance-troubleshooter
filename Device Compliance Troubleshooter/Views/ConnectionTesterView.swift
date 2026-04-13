//
//  ConnectionTesterView.swift
//  Device Compliance Troubleshooter
//
//  Created by Dawid Konopnicki on 09/02/2026.
//

import SwiftUI
import Combine
import Network

struct Endpoint: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var host: String
    var port: Int
    var isCustom: Bool = false
}

enum EndpointStatus: Equatable {
    case idle
    case testing
    case reachable
    case unreachable(String)
}

enum EndpointValidationError: Error {
    case invalid(String)
    var message: String {
        switch self {
        case .invalid(let text): return text
        }
    }
}

@MainActor
final class EndpointTester: ObservableObject {
    @Published var endpoints: [Endpoint] = [


            Endpoint(name: "Apple Content Delivery Network (CDN)", host: "app-site-association.cdn-apple.com", port: 443),
            Endpoint(name: "Apple Networking (Global)", host: "app-site-association.networking.apple", port: 443),
            // MARK: - Entra ID sign-in (Global + US Gov)

            Endpoint(name: "Entra ID Login (Global)", host: "login.microsoftonline.com", port: 443),
            Endpoint(name: "Entra ID Login (Alt)", host: "login.microsoft.com", port: 443),

            Endpoint(name: "Entra ID Login (US Gov)", host: "login.microsoftonline.us", port: 443),
            Endpoint(name: "Entra ID Login (US Alternate)", host: "login-us.microsoftonline.com", port: 443),

            // Device sign-in / device auth flows
            Endpoint(name: "Entra Device Login", host: "device.login.microsoftonline.com", port: 443),

            // Token services (shows up in a lot of legacy + federation-ish paths)
            Endpoint(name: "Azure AD Security Token Service (STS)", host: "sts.windows.net", port: 443),

            // MARK: - Device registration / join
            Endpoint(name: "Entra Device Registration Service (DRS)", host: "enterpriseregistration.windows.net", port: 443),

            // Optional (only if customer uses Seamless SSO / some hybrid setups)
            Endpoint(name: "Seamless SSO", host: "autologon.microsoftazuread-sso.com", port: 443),

            // MARK: - Microsoft Graph
            Endpoint(name: "Microsoft Graph", host: "graph.microsoft.com", port: 443),
            Endpoint(name: "Microsoft Graph (Legacy AAD)", host: "graph.windows.net", port: 443),

            // MARK: - Intune (MDM / enrollment / portal)
            Endpoint(name: "Intune MDM Service", host: "manage.microsoft.com", port: 443),
            Endpoint(name: "Intune Enrollment", host: "enrollment.manage.microsoft.com", port: 443),
            Endpoint(name: "Intune Admin Portal", host: "portal.manage.microsoft.com", port: 443),

            // MARK: - Platform SSO / sign-in UI assets (CDNs that break behind TLS inspection)
            Endpoint(name: "Microsoft Auth CDN (aadcdn)", host: "aadcdn.msftauth.net", port: 443),
            Endpoint(name: "Microsoft Login CDN (logincdn)", host: "logincdn.msftauth.net", port: 443),
            Endpoint(name: "Microsoft Online CDN (secure)", host: "secure.aadcdn.microsoftonline-p.com", port: 443),
    ]
    @Published var statuses: [UUID: EndpointStatus] = [:]

    /// Validates and sanitizes name and host. Returns (sanitizedName, sanitizedHost) or an error.
    static func validateEndpoint(name: String, host: String) -> Result<(String, String), EndpointValidationError> {
        let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxNameLength = 100
        if sanitizedName.isEmpty {
            return .failure(.invalid("Name cannot be empty."))
        }
        if sanitizedName.count > maxNameLength {
            return .failure(.invalid("Name must be at most \(maxNameLength) characters."))
        }
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmedHost.isEmpty {
            return .failure(.invalid("Host cannot be empty."))
        }
        if trimmedHost.count > 253 {
            return .failure(.invalid("Host must be at most 253 characters."))
        }
        let hostnameCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-")
        let isIPv6 = trimmedHost.contains(":")
        let isBracketedIPv6 = trimmedHost.hasPrefix("[") && trimmedHost.hasSuffix("]")
        let hostToValidate = isBracketedIPv6 ? String(trimmedHost.dropFirst().dropLast()) : trimmedHost
        if isIPv6 {
            let ipv6Allowed = CharacterSet(charactersIn: "0123456789abcdef:")
            guard hostToValidate.unicodeScalars.allSatisfy(ipv6Allowed.contains) else {
                return .failure(.invalid("Invalid IPv6 address."))
            }
        } else if parseIPv4(hostToValidate) {
            // Valid IPv4
        } else {
            guard hostToValidate.unicodeScalars.allSatisfy({ hostnameCharacterSet.contains($0) }) else {
                return .failure(.invalid("Host must be a valid hostname (letters, numbers, dots, hyphens) or IP address."))
            }
            guard !hostToValidate.hasPrefix("."), !hostToValidate.hasSuffix("."),
                  !hostToValidate.contains("..") else {
                return .failure(.invalid("Invalid hostname format."))
            }
        }
        return .success((sanitizedName, trimmedHost))
    }

    func addEndpoint(name: String, host: String, port: Int) {
        endpoints.append(Endpoint(name: name, host: host, port: port, isCustom: true))
    }

    private static func parseIPv4(_ s: String) -> Bool {
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        for part in parts {
            guard let num = UInt8(part), part.allSatisfy(\.isNumber) else { return false }
            if part.count > 1 && part.first == "0" { return false }
        }
        return true
    }

    func removeEndpoint(id: UUID) {
        endpoints.removeAll { $0.id == id }
        statuses[id] = nil
    }

    func status(for endpoint: Endpoint) -> EndpointStatus {
        statuses[endpoint.id] ?? .idle
    }

    func testAll() {
        Task {
            let currentEndpoints = endpoints
            for endpoint in currentEndpoints {
                statuses[endpoint.id] = .testing
            }

            for (index, endpoint) in currentEndpoints.enumerated() {
                let result = await Self.check(endpoint: endpoint)
                statuses[endpoint.id] = result

                if index < currentEndpoints.count - 1 {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
            }
        }
    }

    func test(endpoint: Endpoint) {
        statuses[endpoint.id] = .testing
        Task {
            let result = await Self.check(endpoint: endpoint)
            statuses[endpoint.id] = result
        }
    }

    private static func check(endpoint: Endpoint) async -> EndpointStatus {
        await withCheckedContinuation { continuation in
            let host = NWEndpoint.Host(endpoint.host)
            let port = NWEndpoint.Port(integerLiteral: UInt16(endpoint.port))
            let connection = NWConnection(host: host, port: port, using: .tcp)
            let gate = FinishGate()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if gate.finish() {
                        connection.cancel()
                        continuation.resume(returning: .reachable)
                    }
                case .failed(let error):
                    if gate.finish() {
                        connection.cancel()
                        continuation.resume(returning: .unreachable(error.localizedDescription))
                    }
                case .cancelled:
                    if gate.finish() {
                        continuation.resume(returning: .unreachable("Cancelled"))
                    }
                default:
                    break
                }
            }

            connection.start(queue: DispatchQueue(label: "endpoint.\(endpoint.id)"))

            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if gate.finish() {
                    connection.cancel()
                    continuation.resume(returning: .unreachable("Timed out"))
                }
            }
        }
    }
}

private final class FinishGate: @unchecked Sendable {
    nonisolated(unsafe) private var done = false
    nonisolated(unsafe) private let lock = NSLock()

    nonisolated func finish() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}

struct ConnectionTesterView: View {
    @StateObject private var tester = EndpointTester()
    @State private var newName: String = ""
    @State private var newHost: String = ""
    @State private var newPortText: String = "443"
    @State private var addEndpointError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button("Test All") {
                    tester.testAll()
                }
                Button("Clear Status") {
                    tester.statuses.removeAll()
                }
                Spacer()
            }

            GroupBox(label: Text("Endpoints")) {
                List {
                    ForEach(tester.endpoints) { endpoint in
                        HStack(spacing: 12) {
                            StatusIndicator(status: tester.status(for: endpoint))
                            VStack(alignment: .leading) {
                                Text(endpoint.name)
                                    .font(.headline)
                                Text("\(endpoint.host):\(endpoint.port)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Test") {
                                tester.test(endpoint: endpoint)
                            }
                            if endpoint.isCustom {
                                Button("Remove") {
                                    tester.removeEndpoint(id: endpoint.id)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(minHeight: 180)
            }

            GroupBox(label: Text("Add Endpoint")) {
                VStack(alignment: .leading, spacing: 12) {
                    if let addEndpointError {
                        Text(addEndpointError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    HStack {
                        TextField("Name", text: $newName)
                            .onChange(of: newName) { _, _ in addEndpointError = nil }
                        TextField("Host", text: $newHost)
                            .onChange(of: newHost) { _, _ in addEndpointError = nil }
                        TextField("Port", text: $newPortText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .onChange(of: newPortText) { _, _ in addEndpointError = nil }
                    }
                    Button("Add Endpoint") {
                        addEndpointError = nil
                        guard let port = Int(newPortText), (1...65535).contains(port) else {
                            addEndpointError = "Port must be between 1 and 65535."
                            return
                        }
                        switch EndpointTester.validateEndpoint(name: newName, host: newHost) {
                        case .success((let sanitizedName, let sanitizedHost)):
                            tester.addEndpoint(name: sanitizedName, host: sanitizedHost, port: port)
                            newName = ""
                            newHost = ""
                            newPortText = "443"
                        case .failure(let error):
                            addEndpointError = error.message
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 560)
    }
}

private struct StatusIndicator: View {
    let status: EndpointStatus

    var body: some View {
        switch status {
        case .idle:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .testing:
            ProgressView()
                .scaleEffect(0.6)
        case .reachable:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .unreachable:
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    ConnectionTesterView()
}
