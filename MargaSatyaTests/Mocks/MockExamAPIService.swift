//
//  MockExamAPIService.swift
//  MargaSatyaTests
//
//  Mock API service for testing
//

import Foundation
@testable import MargaSatya

/// Mock implementation of ExamAPIServiceProtocol for testing
final class TestMockExamAPIService: ExamAPIServiceProtocol {
    // MARK: - Properties for Testing

    var shouldSucceed = true
    var mockResponse: ExamResponse?
    var mockError: ExamAPIError?
    var resolveCodeCallCount = 0
    var lastReceivedCode: String?

    // MARK: - ExamAPIServiceProtocol

    func resolveExamCode(_ code: String) async throws -> ExamResponse {
        resolveCodeCallCount += 1
        lastReceivedCode = code

        // Simulate delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        if !shouldSucceed {
            throw mockError ?? ExamAPIError.invalidCode
        }

        if let response = mockResponse {
            return response
        }

        // Default mock response
        return ExamResponse(
            examId: "TEST001",
            examUrl: "https://example.com/test",
            examTitle: "Test Exam",
            duration: 30,
            lockMode: true
        )
    }

    // MARK: - Helper Methods

    func reset() {
        shouldSucceed = true
        mockResponse = nil
        mockError = nil
        resolveCodeCallCount = 0
        lastReceivedCode = nil
    }
}
