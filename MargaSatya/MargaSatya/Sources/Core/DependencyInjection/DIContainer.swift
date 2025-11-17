//
//  DIContainer.swift
//  SecureExamID
//
//  Dependency Injection Container
//

import Foundation

/// Dependency Injection Container for managing app dependencies
final class DIContainer {
    /// Shared instance
    static let shared = DIContainer()

    // MARK: - Core Services

    private(set) lazy var encryptionService: EncryptionServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockEncryptionService()
        } else {
            return EncryptionService()
        }
    }()

    private(set) lazy var networkMonitor: NetworkMonitorProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockNetworkMonitor()
        } else {
            let monitor = NetworkMonitor()
            monitor.startMonitoring()
            return monitor
        }
    }()

    // MARK: - Firestore Services

    private(set) lazy var authService: AuthServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockAuthService()
        } else {
            return FirebaseAuthService()
        }
    }()

    private(set) lazy var studentService: StudentServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockStudentService()
        } else {
            return FirestoreStudentService()
        }
    }()

    private(set) lazy var examService: ExamServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockExamService()
        } else {
            return FirestoreExamService()
        }
    }()

    private(set) lazy var sessionService: ExamSessionServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockSessionService()
        } else {
            return FirestoreSessionService()
        }
    }()

    private(set) lazy var answerService: ExamAnswerServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockAnswerService()
        } else {
            return FirestoreAnswerService()
        }
    }()

    private(set) lazy var adminService: AdminServiceProtocol = {
        if AppConfiguration.Features.isDevelopmentMode {
            return MockAdminService()
        } else {
            return FirestoreAdminService()
        }
    }()

    // MARK: - Legacy Services (to be removed)

    private(set) lazy var assessmentService: any AssessmentModeServiceProtocol = {
        return AssessmentModeManager()
    }()

    private init() {}

    // MARK: - Auth ViewModels

    func makeTeacherAuthViewModel() -> TeacherAuthViewModel {
        return TeacherAuthViewModel(authService: authService)
    }

    func makeAdminAuthViewModel() -> AdminAuthViewModel {
        return AdminAuthViewModel(authService: authService)
    }

    // MARK: - Student Management ViewModels

    func makeStudentListViewModel(teacherId: String) -> StudentListViewModel {
        return StudentListViewModel(studentService: studentService, teacherId: teacherId)
    }

    func makeStudentFormViewModel(teacherId: String, studentToEdit: Student?) -> StudentFormViewModel {
        return StudentFormViewModel(studentService: studentService, teacherId: teacherId, studentToEdit: studentToEdit)
    }

    // MARK: - Exam Management ViewModels

    func makeExamListViewModel(teacherId: String) -> ExamListViewModel {
        return ExamListViewModel(examService: examService, teacherId: teacherId)
    }

    func makeExamFormViewModel(teacherId: String, examToEdit: Exam?) -> ExamFormViewModel {
        return ExamFormViewModel(examService: examService, teacherId: teacherId, examToEdit: examToEdit)
    }

    func makeQuestionListViewModel(examId: String) -> QuestionListViewModel {
        return QuestionListViewModel(examService: examService, examId: examId)
    }

    func makeQuestionFormViewModel(examId: String, questionToEdit: ExamQuestion?, currentQuestionCount: Int) -> QuestionFormViewModel {
        return QuestionFormViewModel(examService: examService, examId: examId, questionToEdit: questionToEdit, currentQuestionCount: currentQuestionCount)
    }

    func makeParticipantSelectionViewModel(examId: String, teacherId: String) -> ParticipantSelectionViewModel {
        return ParticipantSelectionViewModel(examService: examService, studentService: studentService, examId: examId, teacherId: teacherId)
    }

    // MARK: - Student ViewModels

    func makeStudentEntryViewModel() -> StudentEntryViewModel {
        return StudentEntryViewModel(studentService: studentService, examService: examService, sessionService: sessionService)
    }

    func makeStudentExamViewModel(exam: Exam, session: ExamSession) -> StudentExamViewModel {
        return StudentExamViewModel(exam: exam, session: session, examService: examService, sessionService: sessionService, answerService: answerService, encryptionService: encryptionService, networkMonitor: networkMonitor)
    }

    func makeGoogleFormExamViewModel(exam: Exam, session: ExamSession) -> GoogleFormExamViewModel {
        return GoogleFormExamViewModel(exam: exam, session: session, sessionService: sessionService)
    }

    // MARK: - Legacy Factory Methods (to be refactored)

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
