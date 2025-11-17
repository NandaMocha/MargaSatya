//
//  ExamPreparationViewModel.swift
//  MargaSatya
//
//  ViewModel for Exam Preparation
//

import Foundation

@MainActor
final class ExamPreparationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isPreparingAssessment = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var shouldStartExam = false

    // MARK: - Dependencies

    let examSession: ExamSession // Made public for view access
    private let assessmentService: any AssessmentModeServiceProtocol

    // MARK: - Initialization

    init(
        examSession: ExamSession,
        assessmentService: any AssessmentModeServiceProtocol
    ) {
        self.examSession = examSession
        self.assessmentService = assessmentService
    }

    // MARK: - Public Methods

    /// Start the exam with optional assessment mode
    func startExam() async {
        isPreparingAssessment = true

        // Start assessment mode if lockMode is enabled
        if examSession.lockMode {
            do {
                try await assessmentService.startAssessmentMode()

                // Wait for assessment mode to fully activate
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Start exam session
                examSession.start()

                // Navigate to exam
                shouldStartExam = true
                isPreparingAssessment = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isPreparingAssessment = false
            }
        } else {
            // Start exam without assessment mode
            examSession.start()
            shouldStartExam = true
            isPreparingAssessment = false
        }
    }
}
