//
//  DIContainer.swift
//  MargaSatya
//
//  Dependency Injection Container
//

import Foundation

/// Dependency Injection Container for managing app dependencies
final class DIContainer {
    /// Shared instance
    static let shared = DIContainer()

    // MARK: - Services

    private(set) lazy var apiService: ExamAPIServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockExamAPIService()
        } else {
            return ExamAPIService(baseURL: AppConfiguration.API.baseURL)
        }
    }()

    private(set) lazy var assessmentService: any AssessmentModeServiceProtocol = {
        return AssessmentModeManager()
    }()

    private init() {}

    // MARK: - Factory Methods

    /// Create ExamCodeInputViewModel with dependencies
    func makeExamCodeInputViewModel() -> ExamCodeInputViewModel {
        return ExamCodeInputViewModel(apiService: apiService)
    }

    /// Create ExamPreparationViewModel with dependencies
    func makeExamPreparationViewModel(examSession: ExamSession) -> ExamPreparationViewModel {
        return ExamPreparationViewModel(
            examSession: examSession,
            assessmentService: assessmentService
        )
    }

    /// Create SecureExamViewModel with dependencies
    func makeSecureExamViewModel(examSession: ExamSession) -> SecureExamViewModel {
        return SecureExamViewModel(
            examSession: examSession,
            assessmentService: assessmentService
        )
    }
}
