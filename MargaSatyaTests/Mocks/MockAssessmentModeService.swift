//
//  MockAssessmentModeService.swift
//  MargaSatyaTests
//
//  Mock assessment mode service for testing
//

import Foundation
import Combine
@testable import MargaSatya

/// Mock implementation of AssessmentModeServiceProtocol for testing
final class MockAssessmentModeService: AssessmentModeServiceProtocol, ObservableObject {
    // MARK: - Published Properties

    @Published var isInAssessmentMode = false
    @Published var assessmentError: AssessmentError?

    // MARK: - Properties for Testing

    var shouldStartSucceed = true
    var mockError: AssessmentError?
    var startCallCount = 0
    var endCallCount = 0
    var forceEndCallCount = 0

    // MARK: - AssessmentModeServiceProtocol

    var isAssessmentModeAvailable: Bool {
        return true
    }

    func startAssessmentMode() async throws {
        startCallCount += 1

        if !shouldStartSucceed {
            let error = mockError ?? .failedToStart("Test error")
            assessmentError = error
            throw error
        }

        // Simulate successful start
        await MainActor.run {
            isInAssessmentMode = true
        }
    }

    func endAssessmentMode() {
        endCallCount += 1
        isInAssessmentMode = false
        assessmentError = nil
    }

    func forceEndAssessment() {
        forceEndCallCount += 1
        endAssessmentMode()
    }

    // MARK: - Helper Methods

    func reset() {
        shouldStartSucceed = true
        mockError = nil
        startCallCount = 0
        endCallCount = 0
        forceEndCallCount = 0
        isInAssessmentMode = false
        assessmentError = nil
    }
}
