//
//  AssessmentModeManager.swift
//  MargaSatya
//
//  Assessment Mode Manager implementation
//

import Foundation
import AutomaticAssessmentConfiguration

/// Implementation of AssessmentModeServiceProtocol using AAC
final class AssessmentModeManager: AssessmentModeServiceProtocol, ObservableObject {
    // MARK: - Published Properties

    @Published var isInAssessmentMode = false
    @Published var assessmentError: AssessmentError?

    // MARK: - Private Properties

    private var session: AEAssessmentSession?
    private var configuration: AEAssessmentConfiguration?

    // MARK: - Initialization

    init() {}

    // MARK: - AssessmentModeServiceProtocol

    var isAssessmentModeAvailable: Bool {
        return true // AAC is available on iOS 13.4+
    }

    /// Start assessment mode
    func startAssessmentMode() async throws {
        guard isAssessmentModeAvailable else {
            throw AssessmentError.notSupported
        }

        // Check if already in assessment mode
        guard !isInAssessmentMode else {
            throw AssessmentError.alreadyActive
        }

        await MainActor.run {
            // Create configuration
            let config = AEAssessmentConfiguration()
            config.autocorrectDisabled = true
            config.allowsSpellCheck = false
            config.allowsAccessibilitySpeech = true // Allow accessibility features
            config.allowsDictation = false
            config.allowsKeyboardShortcuts = false
            config.allowsContinuousPathKeyboard = false

            // Configure assessment application
            let assessmentApp = AEAssessmentApplication()
            assessmentApp.bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
            assessmentApp.requiresSignatureValidation = false
            config.mainApplication = assessmentApp

            self.configuration = config

            // Create and begin session
            let newSession = AEAssessmentSession(configuration: config)
            newSession.delegate = self
            self.session = newSession

            // Begin assessment
            newSession.begin()
            self.isInAssessmentMode = true
        }
    }

    /// End assessment mode
    func endAssessmentMode() {
        guard let session = session else { return }

        DispatchQueue.main.async {
            session.end()
            self.session = nil
            self.configuration = nil
            self.isInAssessmentMode = false
        }
    }

    /// Force end assessment (admin override)
    func forceEndAssessment() {
        endAssessmentMode()
    }
}

// MARK: - AEAssessmentSessionDelegate
extension AssessmentModeManager: AEAssessmentSessionDelegate {
    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        DispatchQueue.main.async {
            self.isInAssessmentMode = true
            print("✅ Assessment mode started successfully")
        }
    }

    func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: Error) {
        DispatchQueue.main.async {
            self.isInAssessmentMode = false
            self.assessmentError = .failedToStart(error.localizedDescription)
            print("❌ Assessment mode failed to start: \(error.localizedDescription)")
        }
    }

    func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: Error) {
        DispatchQueue.main.async {
            self.assessmentError = .interrupted(error.localizedDescription)
            print("⚠️ Assessment mode interrupted: \(error.localizedDescription)")
        }
    }

    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        DispatchQueue.main.async {
            self.isInAssessmentMode = false
            self.session = nil
            print("✅ Assessment mode ended")
        }
    }
}

// MARK: - Assessment Errors
enum AssessmentError: LocalizedError {
    case notSupported
    case alreadyActive
    case failedToStart(String)
    case interrupted(String)

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Assessment mode is not supported on this device. Please ensure your device meets the requirements."
        case .alreadyActive:
            return "Assessment mode is already active."
        case .failedToStart(let message):
            return "Failed to start assessment mode: \(message)"
        case .interrupted(let message):
            return "Assessment mode was interrupted: \(message)"
        }
    }
}
