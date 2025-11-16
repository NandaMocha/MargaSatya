//
//  AssessmentModeServiceProtocol.swift
//  MargaSatya
//
//  Protocol for assessment mode service abstraction
//

import Foundation
import Combine

/// Protocol defining assessment mode operations
protocol AssessmentModeServiceProtocol: ObservableObject {
    /// Published property indicating if device is in assessment mode
    var isInAssessmentMode: Bool { get }

    /// Published property containing any assessment error
    var assessmentError: AssessmentError? { get }

    /// Check if assessment mode is available on this device
    var isAssessmentModeAvailable: Bool { get }

    /// Start assessment mode
    /// - Throws: AssessmentError if start fails
    func startAssessmentMode() async throws

    /// End assessment mode
    func endAssessmentMode()

    /// Force end assessment (admin override)
    func forceEndAssessment()
}
