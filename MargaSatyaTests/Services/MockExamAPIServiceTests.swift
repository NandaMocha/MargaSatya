//
//  MockExamAPIServiceTests.swift
//  MargaSatyaTests
//
//  Unit tests for MockExamAPIService
//

import Testing
import Foundation
@testable import MargaSatya

struct MockExamAPIServiceTests {
    // MARK: - Initialization Tests

    @Test("Mock service initializes with default delay")
    func testDefaultInitialization() {
        let service = MockExamAPIService()
        // Service should be initialized successfully
        #expect(service is ExamAPIServiceProtocol)
    }

    @Test("Mock service initializes with custom delay")
    func testCustomDelayInitialization() {
        let customDelay: UInt64 = 500_000_000 // 0.5 seconds
        let service = MockExamAPIService(mockDelay: customDelay)
        // Service should be initialized successfully
        #expect(service is ExamAPIServiceProtocol)
    }

    // MARK: - Resolve Exam Code Tests

    @Test("Resolve exam code returns mock data for valid code")
    func testResolveValidExamCode() async throws {
        let service = MockExamAPIService(mockDelay: 100_000_000) // 0.1 seconds
        let code = "ABC123"

        let response = try await service.resolveExamCode(code)

        #expect(response.examId == "EX001")
        #expect(response.examUrl.contains("google.com/forms"))
        #expect(response.examTitle == "Ujian Akhir Semester")
        #expect(response.duration == 60)
        #expect(response.lockMode == true)
    }

    @Test("Resolve exam code throws error for empty code")
    func testResolveEmptyExamCode() async {
        let service = MockExamAPIService(mockDelay: 10_000_000) // 0.01 seconds
        let code = ""

        var thrownError: Error?
        do {
            _ = try await service.resolveExamCode(code)
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil)
        #expect(thrownError is ExamAPIError)
        if let apiError = thrownError as? ExamAPIError {
            switch apiError {
            case .invalidCode:
                #expect(true) // Expected error type
            default:
                #expect(Bool(false), "Expected invalidCode error")
            }
        }
    }

    @Test("Resolve exam code throws error for code below minimum length")
    func testResolveShortExamCode() async {
        let service = MockExamAPIService(mockDelay: 10_000_000)
        let code = "AB" // Less than minimum length (3)

        var thrownError: Error?
        do {
            _ = try await service.resolveExamCode(code)
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil)
        #expect(thrownError is ExamAPIError)
    }

    @Test("Resolve exam code respects minimum length from configuration")
    func testResolveExamCodeMinimumLength() async throws {
        let service = MockExamAPIService(mockDelay: 10_000_000)
        let minLength = AppConfiguration.UI.minExamCodeLength
        let code = String(repeating: "A", count: minLength)

        // Should not throw for code at minimum length
        let response = try await service.resolveExamCode(code)
        #expect(response.examId.isEmpty == false)
    }

    @Test("Mock service simulates network delay")
    func testMockServiceDelay() async throws {
        let delay: UInt64 = 200_000_000 // 0.2 seconds
        let service = MockExamAPIService(mockDelay: delay)

        let startTime = Date()
        _ = try await service.resolveExamCode("TEST123")
        let endTime = Date()

        let elapsed = endTime.timeIntervalSince(startTime)
        // Should take at least the delay time (allowing for some variance)
        #expect(elapsed >= 0.15) // 0.15 seconds (allowing 0.05s variance)
    }

    @Test("Multiple calls to mock service return consistent data")
    func testMultipleCallsConsistency() async throws {
        let service = MockExamAPIService(mockDelay: 10_000_000)

        let response1 = try await service.resolveExamCode("CODE1")
        let response2 = try await service.resolveExamCode("CODE2")
        let response3 = try await service.resolveExamCode("CODE3")

        // All responses should have the same structure
        #expect(response1.examId == response2.examId)
        #expect(response2.examId == response3.examId)
        #expect(response1.duration == response2.duration)
        #expect(response2.duration == response3.duration)
    }
}
