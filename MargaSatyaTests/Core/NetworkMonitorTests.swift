//
//  NetworkMonitorTests.swift
//  MargaSatyaTests
//
//  Unit tests for NetworkMonitor
//

import Testing
import Foundation
@testable import MargaSatya

@Suite("Network Monitor Tests")
struct NetworkMonitorTests {

    // MARK: - Mock Network Monitor Tests

    @Test("Mock monitor initialization")
    func testMockMonitorInit() {
        let monitor = MockNetworkMonitor()

        #expect(monitor.status == .connected)
        #expect(monitor.connectionType == .wifi)
    }

    @Test("Mock monitor simulate connection")
    func testMockSimulateConnection() {
        let monitor = MockNetworkMonitor()
        monitor.status = .disconnected

        monitor.simulateConnection()

        #expect(monitor.status == .connected)
    }

    @Test("Mock monitor simulate disconnection")
    func testMockSimulateDisconnection() {
        let monitor = MockNetworkMonitor()

        monitor.simulateDisconnection()

        #expect(monitor.status == .disconnected)
    }

    @Test("Mock monitor simulate poor connection")
    func testMockSimulatePoorConnection() {
        let monitor = MockNetworkMonitor()

        monitor.simulatePoorConnection()

        #expect(monitor.status == .connected)
        #expect(monitor.connectionType == .cellular)
    }

    @Test("Mock monitor start and stop")
    func testMockMonitorStartStop() {
        let monitor = MockNetworkMonitor()

        // Should not crash
        monitor.startMonitoring()
        monitor.stopMonitoring()
    }

    // MARK: - Network Status Tests

    @Test("Network status is connected check")
    func testNetworkStatusConnected() {
        #expect(NetworkStatus.connected.isConnected == true)
        #expect(NetworkStatus.disconnected.isConnected == false)
        #expect(NetworkStatus.unknown.isConnected == false)
    }

    @Test("Network status display names")
    func testNetworkStatusDisplayNames() {
        #expect(NetworkStatus.connected.rawValue == "Terhubung")
        #expect(NetworkStatus.disconnected.rawValue == "Tidak Terhubung")
        #expect(NetworkStatus.unknown.rawValue == "Tidak Diketahui")
    }

    // MARK: - Connection Type Tests

    @Test("Connection type display names")
    func testConnectionTypeDisplayNames() {
        #expect(ConnectionType.wifi.rawValue == "WiFi")
        #expect(ConnectionType.cellular.rawValue == "Seluler")
        #expect(ConnectionType.wired.rawValue == "Ethernet")
        #expect(ConnectionType.unknown.rawValue == "Tidak Diketahui")
    }

    // MARK: - Retry Strategy Tests

    @Test("Default retry strategy values")
    func testDefaultRetryStrategy() {
        let strategy = NetworkRetryStrategy.default

        #expect(strategy.maxRetries == 3)
        #expect(strategy.initialDelay == 1.0)
        #expect(strategy.maxDelay == 10.0)
        #expect(strategy.multiplier == 2.0)
    }

    @Test("Submission retry strategy values")
    func testSubmissionRetryStrategy() {
        let strategy = NetworkRetryStrategy.submission

        #expect(strategy.maxRetries == 5)
        #expect(strategy.initialDelay == 2.0)
        #expect(strategy.maxDelay == 30.0)
        #expect(strategy.multiplier == 2.0)
    }

    @Test("Retry delay calculation")
    func testRetryDelayCalculation() {
        let strategy = NetworkRetryStrategy.default

        // First attempt (0): 1.0 * 2^0 = 1.0
        #expect(strategy.delay(for: 0) == 1.0)

        // Second attempt (1): 1.0 * 2^1 = 2.0
        #expect(strategy.delay(for: 1) == 2.0)

        // Third attempt (2): 1.0 * 2^2 = 4.0
        #expect(strategy.delay(for: 2) == 4.0)

        // Fourth attempt (3): 1.0 * 2^3 = 8.0
        #expect(strategy.delay(for: 3) == 8.0)

        // Fifth attempt (4): 1.0 * 2^4 = 16.0, but capped at maxDelay (10.0)
        #expect(strategy.delay(for: 4) == 10.0)
    }

    @Test("Retry strategy execution success on first try")
    func testRetryExecutionFirstTrySuccess() async throws {
        let strategy = NetworkRetryStrategy(
            maxRetries: 3,
            initialDelay: 0.01,
            maxDelay: 1.0,
            multiplier: 2.0
        )

        var attemptCount = 0
        let result = try await strategy.execute {
            attemptCount += 1
            return "Success"
        }

        #expect(result == "Success")
        #expect(attemptCount == 1)
    }

    @Test("Retry strategy execution with retries")
    func testRetryExecutionWithRetries() async throws {
        let strategy = NetworkRetryStrategy(
            maxRetries: 3,
            initialDelay: 0.01,
            maxDelay: 1.0,
            multiplier: 2.0
        )

        var attemptCount = 0
        let result = try await strategy.execute {
            attemptCount += 1
            if attemptCount < 2 {
                throw NSError(domain: "Test", code: 1, userInfo: nil)
            }
            return "Success after retry"
        }

        #expect(result == "Success after retry")
        #expect(attemptCount == 2)
    }

    @Test("Retry strategy exhausts retries")
    func testRetryExhaustsRetries() async throws {
        let strategy = NetworkRetryStrategy(
            maxRetries: 3,
            initialDelay: 0.01,
            maxDelay: 1.0,
            multiplier: 2.0
        )

        var attemptCount = 0

        await #expect(throws: NSError.self) {
            try await strategy.execute {
                attemptCount += 1
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Persistent failure"])
            }
        }

        #expect(attemptCount == 3)
    }

    // MARK: - Integration Tests

    @Test("Monitor publishes status changes", .timeLimit(.minutes(1)))
    func testStatusPublisher() async throws {
        let monitor = MockNetworkMonitor()
        var receivedStatuses: [NetworkStatus] = []

        // Subscribe to status changes
        let cancellable = monitor.statusPublisher.sink { status in
            receivedStatuses.append(status)
        }

        // Initial status
        #expect(receivedStatuses.count == 1)
        #expect(receivedStatuses.first == .connected)

        // Change status
        monitor.simulateDisconnection()

        // Give time for publisher to emit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(receivedStatuses.contains(.disconnected))

        cancellable.cancel()
    }
}
