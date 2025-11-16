//
//  ExamCodeInputViewModel.swift
//  MargaSatya
//
//  ViewModel for Exam Code Input
//

import Foundation
import SwiftUI

@MainActor
class ExamCodeInputViewModel: ObservableObject {
    @Published var examCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var validatedSession: ExamSession?

    private let apiService = ExamAPIService.shared

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
            return
        }

        guard code.count >= 3 else {
            errorMessage = "Exam code must be at least 3 characters"
            isLoading = false
            return
        }

        do {
            // Call API to validate code
            // For development, using mock API
            let response = try await apiService.mockResolveExamCode(code)

            // Create exam session
            let session = ExamSession(from: response)
            validatedSession = session

            isLoading = false
        } catch let error as ExamAPIError {
            errorMessage = error.errorDescription
            isLoading = false

            // Add haptic feedback for error
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        } catch {
            errorMessage = "An unexpected error occurred"
            isLoading = false
        }
    }

    /// Reset the form
    func reset() {
        examCode = ""
        errorMessage = nil
        validatedSession = nil
        isLoading = false
    }
}
