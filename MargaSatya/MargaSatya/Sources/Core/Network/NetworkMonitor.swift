//
//  NetworkMonitor.swift
//  MargaSatya
//
//  Monitors network connectivity status
//  Used to handle SUBMISSION_PENDING state when connection is poor
//

import Foundation
import Network
import Combine

// MARK: - Network Status

enum NetworkStatus: String {
    case connected = "Terhubung"
    case disconnected = "Tidak Terhubung"
    case unknown = "Tidak Diketahui"

    var isConnected: Bool {
        return self == .connected
    }
}

enum ConnectionType: String {
    case wifi = "WiFi"
    case cellular = "Seluler"
    case wired = "Ethernet"
    case unknown = "Tidak Diketahui"
}

// MARK: - Network Monitor Protocol

protocol NetworkMonitorProtocol {
    var status: NetworkStatus { get }
    var connectionType: ConnectionType { get }
    var statusPublisher: AnyPublisher<NetworkStatus, Never> { get }

    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Network Monitor Implementation

@MainActor
final class NetworkMonitor: NetworkMonitorProtocol, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var status: NetworkStatus = .unknown
    @Published private(set) var connectionType: ConnectionType = .unknown

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.margasatya.networkmonitor")

    var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        $status.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        setupMonitor()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Private Methods

    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            Task { @MainActor in
                self.updateStatus(from: path)
                self.updateConnectionType(from: path)
            }
        }
    }

    private func updateStatus(from path: NWPath) {
        switch path.status {
        case .satisfied:
            status = .connected
        case .unsatisfied, .requiresConnection:
            status = .disconnected
        @unknown default:
            status = .unknown
        }
    }

    private func updateConnectionType(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }

    // MARK: - Utility Methods

    /// Check if connected to internet
    var isConnected: Bool {
        status.isConnected
    }

    /// Check if connection is expensive (cellular)
    var isExpensive: Bool {
        monitor.currentPath.isExpensive
    }

    /// Check if connection is constrained (Low Data Mode)
    var isConstrained: Bool {
        monitor.currentPath.isConstrained
    }

    /// Get detailed connection info for logging
    var connectionInfo: String {
        """
        Status: \(status.rawValue)
        Type: \(connectionType.rawValue)
        Expensive: \(isExpensive)
        Constrained: \(isConstrained)
        """
    }
}

// MARK: - Mock Network Monitor (for testing)

final class MockNetworkMonitor: NetworkMonitorProtocol, ObservableObject {

    @Published var status: NetworkStatus = .connected
    @Published var connectionType: ConnectionType = .wifi

    var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        $status.eraseToAnyPublisher()
    }

    func startMonitoring() {
        // Mock: do nothing
    }

    func stopMonitoring() {
        // Mock: do nothing
    }

    // MARK: - Test Helpers

    func simulateConnection() {
        status = .connected
    }

    func simulateDisconnection() {
        status = .disconnected
    }

    func simulatePoorConnection() {
        status = .connected
        connectionType = .cellular
    }
}

// MARK: - Network Retry Strategy

/// Helper for retrying network operations
struct NetworkRetryStrategy {
    let maxRetries: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static let `default` = NetworkRetryStrategy(
        maxRetries: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    static let submission = NetworkRetryStrategy(
        maxRetries: 5,
        initialDelay: 2.0,
        maxDelay: 30.0,
        multiplier: 2.0
    )

    /// Calculate delay for retry attempt
    func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(multiplier, Double(attempt))
        return min(delay, maxDelay)
    }

    /// Execute operation with retry
    func execute<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry on last attempt
                if attempt < maxRetries - 1 {
                    let delaySeconds = delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                }
            }
        }

        throw lastError ?? NSError(
            domain: "NetworkRetry",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Maksimal percobaan ulang tercapai"]
        )
    }
}
