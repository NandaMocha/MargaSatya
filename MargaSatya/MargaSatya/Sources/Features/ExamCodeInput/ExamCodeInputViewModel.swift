//
//  ExamCodeInputViewModel.swift
//  MargaSatya
//
//  ViewModel for Exam Code Input
//

import Foundation
import SwiftUI

@MainActor
final class ExamCodeInputViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var examCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var validatedSession: ExamSession?

    // MARK: - Dependencies

    private let apiService: ExamAPIServiceProtocol

    // MARK: - Initialization

    init(apiService: ExamAPIServiceProtocol) {
        self.apiService = apiService
    }

    // MARK: - Public Methods

    /// Validate the exam code
    func validateCode() async {
        // Clear previous error
        errorMessage = nil
        isLoading = true

        // Trim whitespace
        let code = examCode.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic validation
        guard !code.isEmpty else {
            errorMessage = "Please enter an exam code"
            isLoading = false
            triggerErrorFeedback()
            return
        }

        guard code.count >= AppConfiguration.UI.minExamCodeLength else {
            errorMessage = "Exam code must be at least \(AppConfiguration.UI.minExamCodeLength) characters"
            isLoading = false
            triggerErrorFeedback()
            return
        }

        do {
            // Call API to validate code
            let response = try await apiService.resolveExamCode(code)

            // Create exam session
            let session = ExamSession(from: response)
            validatedSession = session

            isLoading = false
        } catch let error as ExamAPIError {
            errorMessage = error.errorDescription
            isLoading = false
            triggerErrorFeedback()
        } catch {
            errorMessage = "An unexpected error occurred"
            isLoading = false
            triggerErrorFeedback()
        }
    }

    /// Reset the form
    func reset() {
        examCode = ""
        errorMessage = nil
        validatedSession = nil
        isLoading = false
    }

    // MARK: - Private Methods

    private func triggerErrorFeedback() {
        guard AppConfiguration.Features.hapticFeedbackEnabled else { return }

        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }
}
